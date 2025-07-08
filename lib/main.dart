// ignore_for_file: deprecated_member_use

import 'package:fluent_ui/fluent_ui.dart';
import 'package:server_file/screens/client/client.dart';
import 'package:server_file/screens/server/server.dart';
import 'package:server_file/screens/settings/settings.dart';
import 'package:server_file/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppThemeMode _themeMode = AppThemeMode.system;
  int _selected = 0;

  final List<String> _titles = [
    'Servidor de Arquivos',
    'Cliente de Arquivos',
    'Configurações',
  ];

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 0;
    setState(() => _themeMode = AppThemeMode.values[index]);
  }

  Future<void> _saveThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  void _onThemeChanged(AppThemeMode mode) {
    setState(() => _themeMode = mode);
    _saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    Brightness brightness;
    switch (_themeMode) {
      case AppThemeMode.light:
        brightness = Brightness.light;
        break;
      case AppThemeMode.dark:
        brightness = Brightness.dark;
        break;
      case AppThemeMode.system:
        brightness = WidgetsBinding.instance.window.platformBrightness;
        break;
    }

    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'File Manager',
      theme: FluentThemeData(
        brightness: brightness,
        accentColor: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      home: NavigationView(
        appBar: NavigationAppBar(
          title: Text(
            _titles[_selected],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        pane: NavigationPane(
          selected: _selected,
          onChanged: (i) => setState(() => _selected = i),
          displayMode: PaneDisplayMode.auto,
          size: const NavigationPaneSize(openMaxWidth: 240),
          header: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Icon(FluentIcons.cloud, size: 36, color: Colors.blue),
            ),
          ),
          items: [
            PaneItem(
              icon: const Icon(FluentIcons.cloud_upload),
              title: const Text('Servidor'),
              body: const ServerPage(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.cloud_download),
              title: const Text('Cliente'),
              body: const ClientPage(),
            ),
          ],
          footerItems: [
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('Configurações'),
              body: SettingsPage(
                themeMode: _themeMode,
                onThemeChanged: _onThemeChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
