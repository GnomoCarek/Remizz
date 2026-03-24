import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:remizz/data/song_model.dart';

class DownloadService {
  final YoutubeExplode _yt;

  DownloadService(this._yt);

  /// Baixa o áudio do YouTube e retorna o caminho local
  Future<String?> downloadSong(Song song, {Function(double)? onProgress}) async {
    try {
      debugPrint('Iniciando download da música: ${song.title} (${song.id})');
      
      // 1. Obter o diretório para salvar o arquivo
      final directory = await getApplicationDocumentsDirectory();
      final songsDir = Directory('${directory.path}/songs');
      
      if (!await songsDir.exists()) {
        await songsDir.create(recursive: true);
      }

      final fileName = '${song.id}.mp3';
      final file = File('${songsDir.path}/$fileName');

      // Se já existe, apenas retornamos o caminho
      if (await file.exists()) {
        final size = await file.length();
        if (size > 1000) { // Verifica se o arquivo não está vazio/corrompido
          debugPrint('Música já baixada: ${file.path}');
          return file.path;
        } else {
          // Se for muito pequeno, deletamos para tentar baixar de novo
          await file.delete();
        }
      }

      // 2. Obter informações do vídeo do YouTube
      final manifest = await _yt.videos.streamsClient.getManifest(song.id);
      
      if (manifest.audioOnly.isEmpty) {
        debugPrint('Nenhum stream de áudio encontrado para: ${song.id}');
        return null;
      }
      
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      debugPrint('Stream selecionado: ${streamInfo.size.totalMegaBytes.toStringAsFixed(2)} MB');
      
      // 3. Abrir o stream de dados e o arquivo para escrita
      final stream = _yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();

      // 4. Baixar os bytes e atualizar o progresso
      int totalDownloaded = 0;
      final totalSize = streamInfo.size.totalBytes;
      double lastReportedProgress = -1.0;

      debugPrint('Iniciando transferência de bytes...');

      try {
        await for (final data in stream) {
          fileStream.add(data);
          totalDownloaded += data.length;
          
          final currentProgress = totalDownloaded / totalSize;
          
          // Reporta apenas se houver uma mudança de pelo menos 1% para não sobrecarregar
          if (onProgress != null && (currentProgress - lastReportedProgress) >= 0.01) {
            onProgress(currentProgress);
            lastReportedProgress = currentProgress;
            
            // Log no console a cada 20%
            if ((currentProgress * 100).toInt() % 20 == 0) {
              debugPrint('Download ${song.title}: ${(currentProgress * 100).toStringAsFixed(0)}%');
            }
          }
        }
        await fileStream.flush();
      } catch (e) {
        debugPrint('Erro durante a transferência de bytes: $e');
        await fileStream.close();
        if (await file.exists()) await file.delete();
        return null;
      } finally {
        await fileStream.close();
      }

      debugPrint('Download concluído com sucesso: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Erro ao baixar música (${song.id}): $e');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
