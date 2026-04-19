import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:remizz/core/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/data/library_repository.dart';

class FolderSettingsScreen extends StatefulWidget {
  const FolderSettingsScreen({super.key});

  @override
  State<FolderSettingsScreen> createState() => _FolderSettingsScreenState();
}

class _FolderSettingsScreenState extends State<FolderSettingsScreen> {
  late Box _box;
  List<String> _ignoredPaths = [];
  int _minDuration = 30;

  @override
  void initState() {
    super.initState();
    _box = Hive.box('settings');
    _ignoredPaths = List<String>.from(_box.get('ignored_paths', defaultValue: ['whatsapp', 'telegram', 'recorder', 'voice notes']));
    _minDuration = _box.get('min_duration', defaultValue: 30);
  }

  void _save() {
    _box.put('ignored_paths', _ignoredPaths);
    _box.put('min_duration', _minDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pastas e Filtros'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'DURAÇÃO MÍNIMA',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surfaceColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ignorar áudios menores que $_minDuration s', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Text('Ajuda a remover mensagens de voz', style: TextStyle(fontSize: 12, color: Colors.white38)),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: _minDuration,
                    dropdownColor: AppTheme.surfaceColor,
                    underline: const SizedBox(),
                    items: [0, 5, 10, 15, 30, 60].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('${value}s'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _minDuration = val);
                        _save();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PALAVRAS-CHAVE IGNORADAS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.1),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: _showAddPathDialog,
              ),
            ],
          ),
          const Text(
            'Arquivos com estas palavras no caminho serão ocultados.',
            style: TextStyle(fontSize: 12, color: Colors.white30),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ignoredPaths.length,
            itemBuilder: (context, index) {
              final path = _ignoredPaths[index];
              return Card(
                color: AppTheme.surfaceColor,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(path, style: const TextStyle(fontWeight: FontWeight.w500)),
                  leading: const Icon(Icons.folder_off_outlined, color: Colors.white38),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                    onPressed: () {
                      setState(() => _ignoredPaths.removeAt(index));
                      _save();
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Consumer(builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: () {
                ref.read(downloadedSongsProvider.notifier).refresh();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biblioteca atualizada com os novos filtros')),
                );
              },
              child: const Text('Aplicar Alterações'),
            );
          }),
        ],
      ),
    );
  }

  void _showAddPathDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Ignorar Pasta/Termo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex: WhatsApp, Podcasts, etc',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _ignoredPaths.add(controller.text.toLowerCase()));
                _save();
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}
