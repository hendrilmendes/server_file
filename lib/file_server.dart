// lib/file_server.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

class FileServer {
  HttpServer? _server;
  final String _hostname;
  final int _port;
  final String _directory;

  /// Creates a [FileServer].
  ///
  /// [directory] is the root folder to serve files from.
  /// [hostname] defaults to '0.0.0.0' (all interfaces).
  /// [port] defaults to 8080.
  FileServer({
    required String directory,
    String hostname = '0.0.0.0',
    int port = 8080,
  }) : _directory = directory,
       _hostname = hostname,
       _port = port;

  Future<void> start() async {
    if (isRunning) {
      throw StateError('Server is already running on $_hostname:$_port');
    }

    final router = Router()
      ..post('/upload', _handleUpload)
      ..get('/ping', _handlePing);

    final staticHandler = createStaticHandler(
      _directory,
      serveFilesOutsidePath: true,
      listDirectories: true,
      defaultDocument: 'index.html',
    );

    final cascade = Cascade().add(router.call).add(staticHandler).handler;

    final handler = Pipeline()
        .addMiddleware(_logRequests())
        .addMiddleware(_addSecurityHeaders())
        .addHandler(cascade);

    _server = await shelf_io.serve(handler, _hostname, _port);
    if (kDebugMode) {
      print('✅ FileServer running at http://$_hostname:$_port');
    }
  }

  Future<void> stop() async {
    if (_server == null) return;
    await _server!.close(force: true);
    _server = null;
    if (kDebugMode) {
      print('🛑 FileServer stopped');
    }
  }

  bool get isRunning => _server != null;

  Future<Response> _handleUpload(Request req) async {
    try {
      final contentType = req.headers['content-type'];
      if (contentType == null || !contentType.contains('multipart/form-data')) {
        return Response(
          400,
          body: 'Invalid Content-Type, expected multipart/form-data',
        );
      }

      final boundary = _extractBoundary(contentType);
      final transformer = MimeMultipartTransformer(boundary);
      final parts = await transformer.bind(req.read()).toList();

      final savedFiles = <String>[];
      for (var part in parts) {
        final disposition = part.headers['content-disposition'];
        if (disposition == null) continue;

        final filename = _extractFilename(disposition);
        final safeName = p.basename(filename);
        final filepath = p.join(_directory, safeName);

        final sink = File(filepath).openWrite();
        await part.pipe(sink);
        await sink.close();

        savedFiles.add(safeName);
      }

      return Response.ok(
        'Upload successful: ${savedFiles.join(', ')}',
        headers: {'Content-Type': 'text/plain'},
      );
    } catch (e, stack) {
      if (kDebugMode) {
        print('Upload error: $e\n$stack');
      }
      return Response.internalServerError(body: 'Upload failed: $e');
    }
  }

  Response _handlePing(Request req) => Response.ok('pong');

  Middleware _logRequests() {
    return (innerHandler) {
      return (req) async {
        final start = DateTime.now();
        final resp = await innerHandler(req);
        final duration = DateTime.now().difference(start);
        if (kDebugMode) {
          print(
            '${req.method} ${req.requestedUri} -> ${resp.statusCode} in ${duration.inMilliseconds}ms',
          );
        }
        return resp;
      };
    };
  }

  Middleware _addSecurityHeaders() {
    return (innerHandler) {
      return (req) async {
        final resp = await innerHandler(req);
        return resp.change(
          headers: {
            ...resp.headers,
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'Referrer-Policy': 'no-referrer',
          },
        );
      };
    };
  }

  String _extractBoundary(String contentType) {
    final match = RegExp(r"boundary=(.*)").firstMatch(contentType);
    if (match == null) throw FormatException('Missing boundary');
    return match.group(1)!;
  }

  String _extractFilename(String disposition) {
    final match = RegExp(r'filename="?(.*?)"?(;|\$)').firstMatch(disposition);
    if (match == null) throw FormatException('Invalid Content-Disposition');
    return match.group(1)!;
  }
}
