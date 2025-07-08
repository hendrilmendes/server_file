import 'package:fluent_ui/fluent_ui.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:background_downloader/background_downloader.dart';
import 'dart:io';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});
  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final TextEditingController _ipCtrl = TextEditingController();
  String baseUrl = '';
  List<String> files = [];

  @override
  void initState() {
    super.initState();
    FileDownloader().registerCallbacks();
  }

  Future<void> _connect() async {
    baseUrl = 'http://${_ipCtrl.text}:8080';
    final res = await http.get(Uri.parse(baseUrl));
    files = RegExp(r'href="([^"]+)"')
        .allMatches(res.body)
        .map((m) => Uri.decodeComponent(m.group(1)!))
        .toList();
    setState(() {});
  }

  Future<void> downloadFile(String name) async {
    final task = DownloadTask(
      url: '$baseUrl/${Uri.encodeComponent(name)}',
      filename: name,
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
    );
    FileDownloader().enqueue(task);
    _showDialog('Download iniciado: $name');
  }

  Future<void> uploadFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res == null) return;
    final f = File(res.files.single.path!);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        f.path,
        filename: f.uri.pathSegments.last,
      ),
    });
    final resp = await Dio().post('$baseUrl/', data: form);
    if (resp.statusCode == 200) {
      _showDialog('Upload concluído');
      _connect();
    } else {
      _showDialog('Falha no upload');
    }
  }

  void _showDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Info'),
        content: Text(msg),
        actions: [
          Button(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Cliente de Arquivos')),
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextBox(
                  controller: _ipCtrl,
                  placeholder: 'IP do servidor',
                ),
              ),
              const SizedBox(width: 10),
              Button(onPressed: _connect, child: const Text('Conectar')),
            ],
          ),
          if (files.isNotEmpty)
            Button(onPressed: uploadFile, child: const Text('Enviar Arquivo')),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (_, i) {
                final n = files[i];
                return ListTile(
                  leading: const Icon(FluentIcons.page),
                  title: Text(n),
                  trailing: IconButton(
                    icon: const Icon(FluentIcons.download),
                    onPressed: () => downloadFile(n),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
