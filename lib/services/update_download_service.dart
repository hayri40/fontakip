import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDownloadService {
  static const String _apkFileName = 'fontakip_update.apk';

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
    } catch (_) {
      return null;
    }
  }

  Future<bool> installApk(String apkPath) async {
    try {
      final apkUri = Uri.file(apkPath);
      final result = await launchUrl(
        apkUri,
        mode: LaunchMode.externalApplication,
      );
      return result;
    } catch (_) {
      return false;
    }
  }
}
