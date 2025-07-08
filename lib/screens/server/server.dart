import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:server_file/file_server.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});
  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final FileServer _server = FileServer();
  String? _dir;
  final int _port = 8080;

  Future<void> _selectFolder() async {
    _dir = await FilePicker.platform.getDirectoryPath();
    setState(() {});
  }

  Future<void> _start() async {
    if (_dir == null) return;
    await _server.start(_dir!, _port);
    setState(() {});
  }

  Future<void> _stop() async {
    await _server.stop();
    setState(() {});
  }

  Future<String?> _localIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (!address.isLoopback) {
            return address.address;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter o endereço IP: $e');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext c) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Servidor de Arquivos')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Button(
            onPressed: _selectFolder,
            child: const Text('Selecionar Pasta'),
          ),
          if (_dir != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Pasta: $_dir'),
            ),
          Wrap(
            spacing: 10,
            children: [
              Button(
                onPressed: (_dir != null && !_server.isRunning) ? _start : null,
                child: const Text('Iniciar Servidor'),
              ),
              Button(
                onPressed: _server.isRunning ? _stop : null,
                child: const Text('Parar Servidor'),
              ),
            ],
          ),
          if (_server.isRunning)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: FutureBuilder<String?>(
                future: _localIP(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Erro: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    return Text('Servidor em: http://${snapshot.data}:$_port');
                  } else {
                    return const Text('Não foi possível obter o IP');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
