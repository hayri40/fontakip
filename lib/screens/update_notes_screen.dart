import 'package:flutter/material.dart';

import '../models/version_info.dart';
import '../services/update_service.dart';

class UpdateNotesScreen extends StatefulWidget {
  const UpdateNotesScreen({super.key});

  @override
  State<UpdateNotesScreen> createState() => _UpdateNotesScreenState();
}

class _UpdateNotesScreenState extends State<UpdateNotesScreen> {
  late final Future<VersionInfo?> _latestVersionFuture;

  @override
  void initState() {
    super.initState();
    _latestVersionFuture = const UpdateService().fetchLatestVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güncelleme Notları'),
        centerTitle: true,
      ),
      body: FutureBuilder<VersionInfo?>(
        future: _latestVersionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final version = snapshot.data;
          if (version == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('⚠️ Güncelleme notları yüklenemedi.'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'En Son Sürüm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'v${version.version}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Yayın Tarihi: ${version.formattedReleaseDate}'),
                const SizedBox(height: 20),
                if (version.notes.isEmpty)
                  const Text('Güncelleme notu bulunamadı.')
                else ...[
                  const Text(
                    'Güncelleme Notları',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...version.notes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final note = entry.value;
                    final emoji = switch (index) {
                      0 => '✨',
                      1 => '⚡',
                      2 => '🐛',
                      _ => '📝',
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('$emoji $note'),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
