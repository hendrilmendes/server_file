import 'package:fluent_ui/fluent_ui.dart';
import 'package:server_file/screens/client/client.dart';
import 'package:server_file/screens/server/server.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'File Server App',
      theme: FluentThemeData(accentColor: Colors.blue),
      home: const ChooseModePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChooseModePage extends StatelessWidget {
  const ChooseModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              child: const Text('Modo Servidor'),
              onPressed: () {
                Navigator.push(
                  context,
                  FluentPageRoute(builder: (_) => const ServerPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            Button(
              child: const Text('Modo Cliente'),
              onPressed: () {
                Navigator.push(
                  context,
                  FluentPageRoute(builder: (_) => const ClientPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
