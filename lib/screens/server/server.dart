// lib/screens/server/server.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:server_file/file_server.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  FileServer? _server;
  String? _directory;
  final int _port = 8080;

  bool get _isRunning => _server?.isRunning ?? false;

  Future<void> _selectFolder() async {
    try {
      final selected = await FilePicker.platform.getDirectoryPath();
      if (selected != null) {
        setState(() => _directory = selected);
      }
    } catch (e) {
      if (kDebugMode) print('Error selecting folder: $e');
      await showDialog(
        context: context,
        builder: (_) => ContentDialog(
          title: const Text('Erro'),
          content: const Text(
            'Não foi possível abrir o seletor de pastas. '
            'Verifique se o Zenity ou kdialog está instalado.',
          ),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _startServer() async {
    if (_directory == null) return;
    _server = FileServer(directory: _directory!, port: _port);
    try {
      await _server!.start();
      setState(() {});
    } catch (e) {
      if (kDebugMode) print('Server start error: $e');
      await showDialog(
        context: context,
        builder: (_) => ContentDialog(
          title: const Text('Erro ao Iniciar'),
          content: Text('Falha ao iniciar servidor: $e'),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _stopServer() async {
    if (_server == null) return;
    await _server!.stop();
    setState(() => _server = null);
  }

  Future<String?> _getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var intf in interfaces) {
        for (var addr in intf.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (e) {
      if (kDebugMode) print('IP fetch error: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Servidor de Arquivos')),
      children: [
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Pasta Compartilhada',
          child: Row(
            children: [
              Expanded(
                child: TextFormBox(
                  placeholder: 'Nenhuma pasta selecionada',
                  readOnly: true,
                  controller: TextEditingController(text: _directory ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              Button(onPressed: _selectFolder, child: const Text('Selecionar')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: (_directory != null && !_isRunning)
                  ? _startServer
                  : null,
              child: const Text('Iniciar Servidor'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _isRunning ? _stopServer : null,
              style: ButtonStyle(
                // ignore: deprecated_member_use
                backgroundColor: ButtonState.all(Colors.red.dark),
              ),
              child: const Text('Parar Servidor'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_isRunning)
          FutureBuilder<String?>(
            future: _getLocalIP(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: ProgressRing());
              } else if (snapshot.hasError) {
                return Text('Erro ao obter IP: ${snapshot.error}');
              } else if (snapshot.hasData) {
                return InfoLabel(
                  label: 'Servidor Ativo',
                  child: Text(
                    'http://${snapshot.data}:$_port',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }
}
