import 'package:flutter/material.dart';
import 'package:remizz/core/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remizz/main.dart';
import 'package:remizz/core/theme_provider.dart';
import 'package:remizz/features/home/folder_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pauseOnUnplug = true;
  bool _showNotifications = true;

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final primaryColor = ref.watch(themeColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes e Funções', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 10),
          _buildHeader('REPRODUÇÃO', primaryColor),
          _buildFunctionCard(
            child: Column(
              children: [
                _buildToggleTile(
                  icon: Icons.headphones_rounded,
                  title: 'Pausar ao desconectar',
                  subtitle: 'Para a música ao remover o fone',
                  value: _pauseOnUnplug,
                  onChanged: (v) => setState(() => _pauseOnUnplug = v),
                  activeColor: primaryColor,
                ),
                const Divider(height: 1, indent: 55, color: Colors.white10),
                _buildToggleTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notificações',
                  subtitle: 'Mostrar controles na tela de bloqueio',
                  value: _showNotifications,
                  onChanged: (v) => setState(() => _showNotifications = v),
                  activeColor: primaryColor,
                ),
                const Divider(height: 1, indent: 55, color: Colors.white10),
                _buildClickTile(
                  icon: Icons.palette_rounded,
                  title: 'Cor de Destaque',
                  subtitle: 'Personalize o visual do aplicativo',
                  onTap: () => _showColorPickerDialog(context, ref),
                ),
                const Divider(height: 1, indent: 55, color: Colors.white10),
                StreamBuilder<int?>(
                  stream: handler.sleepTimerStream,
                  builder: (context, snapshot) {
                    final minutes = snapshot.data;
                    return _buildClickTile(
                      icon: Icons.timer_outlined,
                      title: 'Sleep Timer',
                      subtitle: minutes != null 
                          ? 'Ativo: desligando em $minutes min' 
                          : 'Definir tempo para desligar',
                      onTap: () => _showSleepTimerDialog(context, handler),
                    );
                  }
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildHeader('BIBLIOTECA', primaryColor),
          _buildFunctionCard(
            child: Column(
              children: [
                _buildClickTile(
                  icon: Icons.folder_open_rounded,
                  title: 'Pastas de Música',
                  subtitle: 'Selecionar diretórios e filtros de busca',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FolderSettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 55, color: Colors.white10),
                _buildClickTile(
                  icon: Icons.cleaning_services_rounded,
                  title: 'Limpar Cache',
                  subtitle: 'Apagar miniaturas e arquivos temporários',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildHeader('INFORMAÇÕES', primaryColor),
          _buildFunctionCard(
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Sobre o Projeto',
                  subtitle: 'Remizz Player v1.0.0',
                ),
                const Divider(height: 1, indent: 55, color: Colors.white10),
                _buildInfoTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Desenvolvedor',
                  subtitle: 'Renan Amorim • Flutter Developer',
                ),
                const Divider(height: 1, indent: 55, color: Colors.white10),
                _buildClickTile(
                  icon: Icons.code_rounded,
                  title: 'Código Fonte',
                  subtitle: 'Ver repositório no GitHub',
                  onTap: () => _launchUrl('https://github.com/GnomoCarek/Remizz.git'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildFunctionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color activeColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white38)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      ),
    );
  }

  Widget _buildClickTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white38)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white38)),
    );
  }

  void _showSleepTimerDialog(BuildContext context, dynamic handler) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Sleep Timer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Desligar a música automaticamente em:', style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [15, 30, 45, 60, 90, 120].map((mins) {
                  return InkWell(
                    onTap: () {
                      handler.setSleepTimer(mins);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text('$mins min', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    handler.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Desativar Temporizador', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showColorPickerDialog(BuildContext context, WidgetRef ref) {
    final List<Color> colors = [
      const Color(0xFFBB86FC), // Roxo Original
      const Color(0xFF03DAC6), // Ciano
      const Color(0xFFFF5252), // Vermelho
      const Color(0xFFFFAB40), // Laranja
      const Color(0xFF448AFF), // Azul
      const Color(0xFF69F0AE), // Verde
      const Color(0xFFFF4081), // Rosa
      const Color(0xFFE0E0E0), // Branco/Cinza
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Cor de Destaque', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  final isSelected = ref.watch(themeColorProvider) == color;
                  
                  return GestureDetector(
                    onTap: () {
                      ref.read(themeColorProvider.notifier).setThemeColor(color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.black) : null,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
