import 'package:intl/intl.dart';

class VersionInfo {
  final String version;
  final String releaseDate;
  final List<String> notes;
  final String? apkUrl;

  const VersionInfo({
    required this.version,
    required this.releaseDate,
    required this.notes,
    this.apkUrl,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    final notesData = json['notes'];
    final notes = <String>[];

    if (notesData is List) {
      for (final note in notesData) {
        if (note is String && note.trim().isNotEmpty) {
          notes.add(note.trim());
        }
      }
    }

    return VersionInfo(
      version: (json['version'] ?? '').toString().trim(),
      releaseDate: (json['releaseDate'] ?? '').toString().trim(),
      notes: notes,
      apkUrl: json['apkUrl'] == null ? null : json['apkUrl'].toString(),
    );
  }

  String get formattedReleaseDate {
    final date = DateTime.tryParse(releaseDate);
    if (date == null) {
      return releaseDate;
    }
    return DateFormat('dd.MM.yyyy').format(date);
  }
}
