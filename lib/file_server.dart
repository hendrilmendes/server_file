// lib/file_server.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

class FileServer {
  HttpServer? _server;

  /// Inicia o servidor local na pasta [dirPath] e na porta [port].
  Future<void> start(String dirPath, int port) async {
    final router = Router();

    // Upload via POST multipart
    router.post('/', (Request req) async {
      final boundary = req.headers['content-type']?.split('boundary=').last;
      if (boundary == null) {
        return Response.badRequest(body: 'Sem boundary no Content-Type');
      }
      final transformer = MimeMultipartTransformer(boundary);
      final parts = await transformer.bind(req.read()).toList();

      for (var part in parts) {
        final disposition = part.headers['content-disposition'];
        final filename = RegExp(
          r'filename="([^"]*)"',
        ).firstMatch(disposition!)!.group(1)!;
        final file = File('$dirPath${Platform.pathSeparator}$filename');
        await part
            .fold<List<int>>(<int>[], (a, b) => a..addAll(b))
            .then((data) => file.writeAsBytes(data));
      }
      return Response.ok('Upload bem‑sucedido');
    });

    // Servir arquivos estáticos
    final staticHandler = createStaticHandler(
      dirPath,
      serveFilesOutsidePath: true,
      listDirectories: true,
    );

    // Combina upload + download
    final cascade = Cascade().add(router.call).add(staticHandler).handler;

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(cascade);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    if (kDebugMode) {
      print(
        'Servidor rodando em http://${_server!.address.address}:${_server!.port}',
      );
    }
  }

  /// Para o servidor
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  bool get isRunning => _server != null;
}
