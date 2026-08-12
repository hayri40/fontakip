import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_sources_screen.dart';
import 'update_notes_screen.dart';
import '../models/auth_state.dart';
import '../models/version_info.dart';
import '../services/backup_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/update_service.dart';
import '../services/update_download_service.dart';

class SettingsScreen extends StatefulWidget {
  final BackupService? backupService;
  final UpdateService? updateService;
  final CloudBackupService? cloudBackupService;

  const SettingsScreen({
    super.key,
    this.backupService,
    this.updateService,
    this.cloudBackupService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _lastCheckKey = 'last_update_check_timestamp';
  static const String _lastVersionKey = 'last_update_version_json';
  static const String _lastUpdateAvailableKey = 'last_update_available';
  static const String _lastCheckFailedKey = 'last_update_check_failed';

  late final BackupService _backupService;
  late final UpdateService _updateService;
  late final CloudBackupService _cloudBackupService;
  late final UpdateDownloadService _updateDownloadService;
  bool _busy = false;
  bool _checkingUpdates = false;
  bool _downloadingUpdate = false;
  int _downloadProgress = 0;
  int _downloadTotal = 0;
  String _currentVersion = '...';
  DateTime? _lastCheckTime;
  VersionInfo? _latestVersion;
  bool _updateAvailable = false;
  bool _updateCheckAttempted = false;
  bool _updateCheckFailed = false;
  AuthState _cloudAuthState = const AuthState(
    isSignedIn: false,
    provider: 'google',
  );

  @override
  void initState() {
    super.initState();
    _backupService = widget.backupService ?? BackupService();
    _updateService = widget.updateService ?? const UpdateService();
    _cloudBackupService =
        widget.cloudBackupService ?? GoogleCloudBackupService();
    _updateDownloadService = UpdateDownloadService();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final timestampValue = prefs.getString(_lastCheckKey);
    final lastVersionValue = prefs.getString(_lastVersionKey);
    final cloudAuthState = await _cloudBackupService.getAuthState();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentVersion = packageInfo.version;
      _lastCheckTime = timestampValue == null || timestampValue.isEmpty
          ? null
          : DateTime.tryParse(timestampValue);
      _updateCheckAttempted =
          lastVersionValue != null || timestampValue != null;
      _updateCheckFailed = prefs.getBool(_lastCheckFailedKey) ?? false;
      if (lastVersionValue != null && lastVersionValue.isNotEmpty) {
        try {
          final decoded = jsonDecode(lastVersionValue);
          if (decoded is Map<String, dynamic>) {
            _latestVersion = VersionInfo.fromJson(decoded);
          }
        } catch (_) {
          _latestVersion = null;
        }
      }
      _updateAvailable = prefs.getBool(_lastUpdateAvailableKey) ?? false;
      _cloudAuthState = cloudAuthState;
    });
  }

  Future<void> _checkForUpdates() async {
    if (_checkingUpdates) {
      return;
    }

    setState(() {
      _checkingUpdates = true;
      _updateCheckAttempted = false;
      _updateCheckFailed = false;
      _latestVersion = null;
      _updateAvailable = false;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final latestVersion = await _updateService.fetchLatestVersion();

      if (!mounted) {
        return;
      }

      if (latestVersion == null || latestVersion.version.trim().isEmpty) {
        throw const FormatException('Unable to read update metadata');
      }

      final updateAvailable = _updateService.hasNewVersion(
        packageInfo.version,
        latestVersion.version,
      );
      final now = DateTime.now();

      await _persistCheckResult(
        lastCheckTime: now,
        latestVersion: latestVersion,
        updateAvailable: updateAvailable,
        failed: false,
      );

      setState(() {
        _currentVersion = packageInfo.version;
        _lastCheckTime = now;
        _latestVersion = latestVersion;
        _updateAvailable = updateAvailable;
        _updateCheckAttempted = true;
        _updateCheckFailed = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final failedAt = DateTime.now();
      await _persistCheckResult(
        lastCheckTime: failedAt,
        latestVersion: null,
        updateAvailable: false,
        failed: true,
      );

      setState(() {
        _lastCheckTime = failedAt;
        _latestVersion = null;
        _updateAvailable = false;
        _updateCheckAttempted = true;
        _updateCheckFailed = true;
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _checkingUpdates = false;
      });
    }
  }

  Future<void> _persistCheckResult({
    required DateTime lastCheckTime,
    required VersionInfo? latestVersion,
    required bool updateAvailable,
    required bool failed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, lastCheckTime.toIso8601String());
    if (latestVersion != null) {
      await prefs.setString(
        _lastVersionKey,
        jsonEncode({
          'version': latestVersion.version,
          'releaseDate': latestVersion.releaseDate,
          'notes': latestVersion.notes,
          'apkUrl': latestVersion.apkUrl,
        }),
      );
    } else {
      await prefs.remove(_lastVersionKey);
    }
    await prefs.setBool(_lastUpdateAvailableKey, updateAvailable);
    await prefs.setBool(_lastCheckFailedKey, failed);
  }

  String _formatLastCheck() {
    if (_lastCheckTime == null) {
      return 'Henüz kontrol edilmedi';
    }
    return DateFormat('dd.MM.yyyy HH:mm').format(_lastCheckTime!);
  }

  Future<void> _handleGoogleSignIn() async {
    await _cloudBackupService.signIn();
    final nextState = await _cloudBackupService.getAuthState();
    if (!mounted) {
      return;
    }

    setState(() {
      _cloudAuthState = nextState;
    });

    if (!_cloudAuthState.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google ile giriş başarısız oldu.')),
      );
    }
  }

  Future<void> _handleCloudSignOut() async {
    await _cloudBackupService.signOut();
    final nextState = await _cloudBackupService.getAuthState();
    if (!mounted) {
      return;
    }
    setState(() {
      _cloudAuthState = nextState;
    });
  }

  Future<void> _handleCloudUpload() async {
    await _cloudBackupService.uploadBackup();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulut yedekleme özelliği yakında aktif olacak.'),
      ),
    );
  }

  Future<void> _handleCloudRestore() async {
    await _cloudBackupService.restoreBackup();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buluttan geri yükleme yakında aktif olacak.'),
      ),
    );
  }

  String _formatDownloadProgress() {
    if (_downloadTotal == 0) {
      return 'İndiriliyor...';
    }
    final percent = ((_downloadProgress / _downloadTotal) * 100)
        .toStringAsFixed(0);
    final downloadedSize = _updateDownloadService.formatFileSize(
      _downloadProgress,
    );
    final totalSize = _updateDownloadService.formatFileSize(_downloadTotal);
    return 'İndiriliyor... $percent% ($downloadedSize / $totalSize)';
  }

  Future<void> _showDownloadConfirmation() async {
    if (_latestVersion == null ||
        !_updateService.isApkUrlValid(_latestVersion!.apkUrl)) {
      return;
    }

    final fileSize = await _updateService.getApkFileSize(
      _latestVersion!.apkUrl!,
    );
    final fileSizeText = fileSize != null
        ? _updateDownloadService.formatFileSize(fileSize)
        : 'Bilinmiyor';

    if (!mounted) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Güncellemeyi İndir'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Sürüm: v${_latestVersion!.version}'),
                const SizedBox(height: 8),
                Text('Yayın Tarihi: ${_latestVersion!.formattedReleaseDate}'),
                const SizedBox(height: 8),
                Text('Dosya Boyutu: $fileSizeText'),
                const SizedBox(height: 16),
                const Text(
                  'Devam etmek istiyor musunuz?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('İndir'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await _handleDownloadApk();
  }

  Future<void> _handleDownloadApk() async {
    if (_downloadingUpdate ||
        _latestVersion?.apkUrl == null ||
        _latestVersion!.apkUrl!.isEmpty) {
      return;
    }

    setState(() {
      _downloadingUpdate = true;
      _downloadProgress = 0;
      _downloadTotal = 0;
    });

    try {
      final apkPath = await _updateDownloadService.downloadApk(
        _latestVersion!.apkUrl!,
        (current, total) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = current;
            _downloadTotal = total;
          });
        },
      );

      if (!mounted) {
        return;
      }

      if (apkPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Güncelleme indirilemedi')),
        );
        setState(() {
          _downloadingUpdate = false;
        });
        return;
      }

      final installSuccess = await _updateDownloadService.installApk(apkPath);
      if (!mounted) {
        return;
      }

      if (installSuccess) {
        setState(() {
          _downloadingUpdate = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Kurulum başlatılamadı')),
        );
        setState(() {
          _downloadingUpdate = false;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Güncelleme indirilemedi')),
      );
      setState(() {
        _downloadingUpdate = false;
      });
    }
  }

  Future<void> _exportBackup() async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      final savedPath = await _backupService.exportBackup();
      if (!mounted) return;
      if (savedPath == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yedek başarıyla oluşturuldu.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yedek oluşturulurken bir hata oluştu.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _importBackup() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uyarı'),
          content: const Text(
            'Bu işlem mevcut verilerin üzerine yazacaktır.\n\n'
            'Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _busy = true;
    });
    try {
      final imported = await _backupService.importBackup();
      if (!mounted || !imported) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yedek başarıyla geri yüklendi.\nUygulama yeniden başlatılacak.',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await SystemNavigator.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yedek geri yüklenirken bir hata oluştu.'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _resetAppData() async {
    if (_busy) return;

    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uyarı'),
          content: const Text('Tüm verileriniz silinecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    if (firstConfirmed != true) return;

    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Son Onay'),
          content: const Text('Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    if (secondConfirmed != true) return;

    setState(() {
      _busy = true;
    });
    try {
      await _backupService.resetAllUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm veriler silindi. Uygulama yeniden başlatılacak.'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await SystemNavigator.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uygulama sıfırlanırken bir hata oluştu.'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.system_update_alt_outlined),
                      const SizedBox(width: 12),
                      const Text(
                        'Güncellemeler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Mevcut Sürüm'),
                  const SizedBox(height: 4),
                  Text(
                    'v$_currentVersion',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Son Kontrol:\n${_formatLastCheck()}'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _checkingUpdates || _busy
                          ? null
                          : _checkForUpdates,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _checkingUpdates
                            ? 'Kontrol ediliyor...'
                            : 'Güncellemeleri Kontrol Et',
                      ),
                    ),
                  ),
                  if (_updateCheckAttempted) ...[
                    const SizedBox(height: 16),
                    if (_updateCheckFailed)
                      const Text(
                        '⚠️ Güncellemeler kontrol edilemedi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      )
                    else if (_latestVersion != null) ...[
                      if (_updateAvailable)
                        const Text(
                          '🎉 Yeni sürüm mevcut',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        )
                      else
                        const Text(
                          '✅ Uygulamanız güncel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text('Mevcut sürüm:\nv$_currentVersion'),
                      if (_updateAvailable) ...[
                        const SizedBox(height: 4),
                        Text('Son sürüm:\nv${_latestVersion!.version}'),
                        const SizedBox(height: 4),
                        Text(
                          'Yayın Tarihi: ${_latestVersion!.formattedReleaseDate}',
                        ),
                        if (_latestVersion!.notes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Güncelleme Notları',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          ..._latestVersion!.notes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final note = entry.value;
                            final emoji = switch (index) {
                              0 => '✨',
                              1 => '⚡',
                              2 => '🐛',
                              _ => '📝',
                            };

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('$emoji $note'),
                            );
                          }),
                          const SizedBox(height: 12),
                          if (_downloadingUpdate)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_formatDownloadProgress()),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: _downloadTotal > 0
                                        ? _downloadProgress / _downloadTotal
                                        : null,
                                    minHeight: 6,
                                  ),
                                ],
                              ),
                            )
                          else if (!_updateService.isApkUrlValid(
                            _latestVersion!.apkUrl,
                          ))
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Güncelleme paketi henüz yayınlanmamış',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _showDownloadConfirmation,
                                icon: const Icon(Icons.download),
                                label: const Text('APK İndir'),
                              ),
                            ),
                        ],
                      ] else ...[
                        const SizedBox(height: 8),
                        Text('Son Kontrol:\n${_formatLastCheck()}'),
                      ],
                    ],
                  ],
                  if (_updateCheckAttempted && !_updateCheckFailed) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Debug Bilgileri',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'URL: ${_updateService.versionUrl}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    if (_latestVersion != null)
                      Text(
                        'Algılanan Sürüm: v${_latestVersion!.version}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined),
                      const SizedBox(width: 12),
                      const Text(
                        '☁ Bulut Yedekleme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Durum: ${_cloudAuthState.isSignedIn ? 'Bağlı' : 'Bağlı Değil'}',
                  ),
                  if (_cloudAuthState.isSignedIn) ...[
                    const SizedBox(height: 8),
                    if (_cloudAuthState.user?.displayName != null)
                      Text('Ad: ${_cloudAuthState.user!.displayName}'),
                    const SizedBox(height: 4),
                    Text(
                      'Hesap: ${_cloudAuthState.user?.email ?? 'Bilinmeyen kullanıcı'}',
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_cloudAuthState.isSignedIn) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _handleCloudUpload,
                          icon: const Icon(Icons.upload),
                          label: const Text('Buluta Yedekle'),
                        ),
                        FilledButton.icon(
                          onPressed: _handleCloudRestore,
                          icon: const Icon(Icons.download),
                          label: const Text('Buluttan Geri Yükle'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _handleCloudSignOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _handleGoogleSignIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Google ile Giriş Yap'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    enabled: !_busy,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.list_alt_rounded),
                    title: const Text('📋 Güncelleme Notları'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UpdateNotesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    enabled: !_busy,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.hub_outlined),
                    title: const Text('Veri Kaynakları'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DataSourcesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    enabled: !_busy,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Verileri Dışa Aktar'),
                    onTap: _exportBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    enabled: !_busy,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.download),
                    title: const Text('Verileri İçe Aktar'),
                    onTap: _importBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    enabled: !_busy,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: const Text('Uygulamayı Sıfırla'),
                    onTap: _resetAppData,
                  ),
                ],
              ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
