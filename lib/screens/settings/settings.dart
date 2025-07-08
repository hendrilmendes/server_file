import 'package:fluent_ui/fluent_ui.dart';
import 'package:server_file/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppThemeMode _selectedMode = AppThemeMode.system;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.themeMode;
    _loadSavedIP();
  }

  Future<void> _loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('server_ip');
    if (ip != null) {
      setState(() {
        _ipController.text = ip;
      });
    }
  }

  Future<void> _saveIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
  }

  void _onChanged(AppThemeMode? mode) {
    if (mode == null) return;
    setState(() => _selectedMode = mode);
    widget.onThemeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Configurações')),
      children: [
        const SizedBox(height: 12),
        const Text(
          'Tema do Aplicativo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        RadioButton(
          checked: _selectedMode == AppThemeMode.system,
          content: const Text('Seguir o Sistema'),
          onChanged: (_) => _onChanged(AppThemeMode.system),
        ),
        const SizedBox(height: 12),
        RadioButton(
          checked: _selectedMode == AppThemeMode.light,
          content: const Text('Modo Claro'),
          onChanged: (_) => _onChanged(AppThemeMode.light),
        ),
        const SizedBox(height: 12),
        RadioButton(
          checked: _selectedMode == AppThemeMode.dark,
          content: const Text('Modo Escuro'),
          onChanged: (_) => _onChanged(AppThemeMode.dark),
        ),
        const SizedBox(height: 32),
        const Text(
          'IP do Servidor Padrão',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextBox(
          controller: _ipController,
          placeholder: 'Ex: 192.168.0.100',
          onChanged: (value) => _saveIP(value),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
