import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/version_info.dart';

class UpdateService {
  static const String defaultVersionUrl =
      'https://raw.githubusercontent.com/hayri40/fontakip/main/version.json';

  final String versionUrl;

  const UpdateService({this.versionUrl = defaultVersionUrl});

  Future<VersionInfo?> fetchLatestVersion() async {
    try {
      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return VersionInfo.fromJson(decoded);
    } on FormatException {
      return null;
    } on http.ClientException {
      return null;
    } on Exception {
      return null;
    }
  }

  bool hasNewVersion(String currentVersion, String latestVersion) {
    final normalizedCurrent = _normalizeVersion(currentVersion);
    final normalizedLatest = _normalizeVersion(latestVersion);

    if (normalizedCurrent == null || normalizedLatest == null) {
      return false;
    }

    return _compareVersions(normalizedLatest, normalizedCurrent) > 0;
  }

  int compareVersions(String left, String right) {
    final normalizedLeft = _normalizeVersion(left);
    final normalizedRight = _normalizeVersion(right);

    if (normalizedLeft == null || normalizedRight == null) {
      return 0;
    }

    return _compareVersions(normalizedLeft, normalizedRight);
  }

  List<int>? _normalizeVersion(String version) {
    final trimmed = version.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final withoutPrefix = trimmed.replaceFirst(RegExp(r'^[vV]'), '');
    final base = withoutPrefix.split('+').first;
    final segments = base.split('.');
    final values = <int>[];

    for (final segment in segments) {
      if (segment.trim().isEmpty) {
        continue;
      }
      final parsed = int.tryParse(segment.trim());
      if (parsed == null) {
        return null;
      }
      values.add(parsed);
    }

    if (values.isEmpty) {
      return null;
    }

    return values;
  }

  int _compareVersions(List<int> left, List<int> right) {
    final maxLength = left.length > right.length ? left.length : right.length;

    for (var index = 0; index < maxLength; index++) {
      final leftValue = index < left.length ? left[index] : 0;
      final rightValue = index < right.length ? right[index] : 0;

      if (leftValue < rightValue) {
        return -1;
      }
      if (leftValue > rightValue) {
        return 1;
      }
    }

    return 0;
  }

  Future<int?> getApkFileSize(String apkUrl) async {
    if (apkUrl.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .head(Uri.parse(apkUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final contentLength = response.contentLength;
        if (contentLength != null && contentLength > 0) {
          return contentLength;
        }
      }
      return null;
    } on Exception {
      return null;
    }
  }

  bool isApkUrlValid(String? apkUrl) {
    return apkUrl != null && apkUrl.isNotEmpty;
  }
}
