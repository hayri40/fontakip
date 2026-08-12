import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UpdateDownloadService {
  static const String _apkFileName = 'fontakip_update.apk';
  static const platform = MethodChannel('com.fontakip.app/update');

  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<String?> downloadApk(
    String apkUrl,
    Function(int current, int total)? onProgress,
  ) async {
    try {
      final uri = Uri.parse(apkUrl);
      final request = http.Request('GET', uri);
      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        return null;
      }

      final contentLength = streamedResponse.contentLength;
      if (contentLength == null || contentLength == 0) {
        return null;
      }

      final bytes = <int>[];
      var received = 0;

      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, contentLength);
      }

      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        return null;
      }

      final apkFile = File('${downloadDir.path}/$_apkFileName');
      await apkFile.writeAsBytes(bytes);
      return apkFile.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> installApk(String apkPath) async {
    try {
      final result = await platform.invokeMethod<String>('installApk', {
        'apkPath': apkPath,
      });
      return result;
    } on PlatformException catch (e) {
      return 'Hata: ${e.message}';
    } catch (e) {
      return 'Kurulum başlatılamadı: ${e.toString()}';
    }
  }
}
