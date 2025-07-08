// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final TextEditingController _ipController = TextEditingController();
  final Dio _dio = Dio();
  final FileDownloader _downloader = FileDownloader();

  String _baseUrl = '';
  List<String> _files = [];
  bool _isLoading = false;
  bool _isUploading = false;
  late Directory _downloadDir;

  @override
  void initState() {
    super.initState();
    _initDownloads();
    _loadSavedIP();
    _downloader.registerCallbacks(
      taskStatusCallback: (update) {
        final filename = update.task.filename;
        if (update.status == TaskStatus.complete) {
          _showDialog('Download concluído: $filename');
        } else if (update.status == TaskStatus.failed) {
          _showDialog('Download falhou: $filename');
        }
      },
    );
  }

  Future<void> _initDownloads() async {
    _downloadDir = await getApplicationDocumentsDirectory();
  }

  Future<void> _loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('server_ip');
    if (ip != null && mounted) {
      setState(() {
        _ipController.text = ip;
        _baseUrl = 'http://$ip:8080';
      });
      await _connect(); // conecta automaticamente se tiver IP salvo
    }
  }

  Future<void> _saveIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _isLoading = true);
    _baseUrl = 'http://$ip:8080';
    await _saveIP(ip);

    try {
      final res = await http.get(Uri.parse(_baseUrl));
      if (res.statusCode == 200) {
        final matches = RegExp(r'href="([^"/]+)"')
            .allMatches(res.body)
            .map((m) => Uri.decodeComponent(m.group(1)!))
            .where((name) => name.isNotEmpty)
            .toList();
        setState(() => _files = matches);
      } else {
        _showDialog('Falha ao conectar: HTTP ${res.statusCode}');
      }
    } catch (e) {
      _showDialog('Erro de conexão: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFile(String filename) async {
    final url = '$_baseUrl/${Uri.encodeComponent(filename)}';
    final task = DownloadTask(
      url: url,
      filename: filename,
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
    );

    try {
      await _downloader.enqueue(task);
      _showDialog('Download iniciado: $filename');
    } catch (e) {
      _showDialog('Erro no download: $e');
    }
  }

  Future<void> _openFile(String filename) async {
    final file = File('${_downloadDir.path}/$filename');
    if (await file.exists()) {
      final content = await file.readAsString();
      final controller = TextEditingController(text: content);

      await showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: Text('Editar: $filename'),
          content: SizedBox(
            height: 300,
            child: TextBox(
              controller: controller,
              expands: true,
              maxLines: null,
              minLines: null,
              placeholder: 'Conteúdo do arquivo...',
            ),
          ),
          actions: [
            Button(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              child: const Text('Salvar'),
              onPressed: () async {
                await file.writeAsString(controller.text);
                Navigator.pop(context);
                _showDialog('Arquivo salvo com sucesso!');
              },
            ),
          ],
        ),
      );
    } else {
      _showDialog(
        'Arquivo não encontrado localmente. Faça o download primeiro.',
      );
    }
  }

  Future<void> _uploadFile() async {
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      final file = File(result.files.single.path!);
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      });

      final resp = await _dio.post('$_baseUrl/upload', data: form);
      if (resp.statusCode == 200) {
        _showDialog('Upload concluído com sucesso!');
        await _connect();
      } else {
        _showDialog('Falha no upload: HTTP ${resp.statusCode}');
      }
    } catch (e) {
      _showDialog('Erro no upload: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => ContentDialog(
            title: const Text('Informação'),
            content: Text(message),
            actions: [
              Button(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Cliente de Arquivos')),
      children: [
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Endereço IP do Servidor',
          child: Row(
            children: [
              Expanded(
                child: TextBox(
                  controller: _ipController,
                  placeholder: 'Ex: 192.168.1.100',
                  suffix: _isLoading ? const ProgressRing() : null,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isLoading ? null : _connect,
                child: const Text('Conectar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_files.isNotEmpty)
          Row(
            children: [
              FilledButton(
                onPressed: _isUploading ? null : _uploadFile,
                child: _isUploading
                    ? const ProgressRing()
                    : const Text('Enviar Arquivo'),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: _isLoading || _baseUrl.isEmpty
                    ? null
                    : () async {
                        await _connect();
                      },
                child: const Text('Recarregar Arquivos'),
              ),
            ],
          ),
        const SizedBox(height: 20),
        _files.isEmpty
            ? const Center(child: Text('Nenhum arquivo encontrado'))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _files.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final name = _files[i];
                  return ListTile(
                    leading: const Icon(FluentIcons.page),
                    title: Text(name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(FluentIcons.download),
                          onPressed: () => _downloadFile(name),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(FluentIcons.open_file),
                          onPressed: () => _openFile(name),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
