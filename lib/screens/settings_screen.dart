import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_sources_screen.dart';
import 'update_notes_screen.dart';
import '../models/auth_state.dart';
import '../models/cloud_backup_info.dart';
import '../models/email_summary_preferences.dart';
import '../models/version_info.dart';
import '../services/backup_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/email_summary_preferences_service.dart';
import '../services/update_service.dart';
import '../services/update_download_service.dart';

class SettingsScreen extends StatefulWidget {
  final BackupService? backupService;
  final UpdateService? updateService;
  final CloudBackupService? cloudBackupService;
  final EmailSummaryPreferencesService? emailSummaryPreferencesService;

  const SettingsScreen({
    super.key,
    this.backupService,
    this.updateService,
    this.cloudBackupService,
    this.emailSummaryPreferencesService,
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
  late final EmailSummaryPreferencesService _emailSummaryPreferencesService;
  late final UpdateDownloadService _updateDownloadService;
  bool _busy = false;
  bool _emailPreferencesBusy = false;
  bool _emailPreferencesLoaded = false;
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
  String? _apkDownloadPath;
  String? _apkInstallError;
  AuthState _cloudAuthState = const AuthState(
    isSignedIn: false,
    provider: 'google',
  );
  CloudBackupInfo _cloudBackupInfo = const CloudBackupInfo(
    provider: 'google',
    isSignedIn: false,
  );
  EmailSummaryPreferences _emailSummaryPreferences =
      const EmailSummaryPreferences();

  @override
  void initState() {
    super.initState();
    _backupService = widget.backupService ?? BackupService();
    _updateService = widget.updateService ?? const UpdateService();
    _cloudBackupService =
        widget.cloudBackupService ?? GoogleCloudBackupService();
    _emailSummaryPreferencesService =
        widget.emailSummaryPreferencesService ??
        SharedPreferencesEmailSummaryPreferencesService();
    _updateDownloadService = UpdateDownloadService();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final timestampValue = prefs.getString(_lastCheckKey);
    final lastVersionValue = prefs.getString(_lastVersionKey);
    final cloudAuthState = await _cloudBackupService.getAuthState();
    final cloudBackupInfo = await _cloudBackupService.getBackupInfo();
    final emailSummaryPreferences = await _emailSummaryPreferencesService
        .load();

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
      _cloudBackupInfo = cloudBackupInfo;
      _emailSummaryPreferences = emailSummaryPreferences;
      _emailPreferencesLoaded = true;
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

  String _formatCloudBackupDate() {
    if (_cloudBackupInfo.lastUpdatedAt == null) {
      return _cloudBackupInfo.hasBackup ? 'Bilinmiyor' : 'Henüz yedek yok';
    }
    return DateFormat(
      'dd.MM.yyyy HH:mm',
    ).format(_cloudBackupInfo.lastUpdatedAt!);
  }

  String _formatCloudBackupSize() {
    final size = _cloudBackupInfo.backupSizeBytes;
    if (size == null) {
      return _cloudBackupInfo.hasBackup ? 'Bilinmiyor' : 'Henüz yedek yok';
    }
    return _updateDownloadService.formatFileSize(size);
  }

  String _formatEmailSummaryDate(DateTime? value) {
    if (value == null) {
      return 'Henüz gönderilmedi';
    }
    return DateFormat('dd.MM.yyyy HH:mm').format(value);
  }

  Future<void> _saveEmailSummaryPreferences(
    EmailSummaryPreferences nextPreferences,
  ) async {
    setState(() {
      _emailPreferencesBusy = true;
    });

    try {
      final saved = await _emailSummaryPreferencesService.save(nextPreferences);
      if (!mounted) {
        return;
      }
      setState(() {
        _emailSummaryPreferences = saved;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ E-posta bildirim ayarları kaydedilemedi: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _emailPreferencesBusy = false;
        });
      }
    }
  }

  Future<void> _pickEmailSummaryTime({required bool isFundSummary}) async {
    final currentValue = isFundSummary
        ? _emailSummaryPreferences.fundSummaryTime
        : _emailSummaryPreferences.stockSummaryTime;
    final initialTime = _parseTimeOfDay(currentValue);
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selected == null || !mounted) {
      return;
    }

    final formatted =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    final nextPreferences = isFundSummary
        ? _emailSummaryPreferences.copyWith(fundSummaryTime: formatted)
        : _emailSummaryPreferences.copyWith(stockSummaryTime: formatted);
    await _saveEmailSummaryPreferences(nextPreferences);
  }

  TimeOfDay _parseTimeOfDay(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return const TimeOfDay(hour: 9, minute: 30);
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return const TimeOfDay(hour: 9, minute: 30);
    }

    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  Future<bool> _showCloudRestoreConfirmation(
    CloudRestoreData restoreData,
  ) async {
    final lastBackupText = restoreData.info.lastUpdatedAt == null
        ? 'Bilinmiyor'
        : DateFormat(
            'dd.MM.yyyy HH:mm',
          ).format(restoreData.info.lastUpdatedAt!);
    final backupSizeText = restoreData.info.backupSizeBytes == null
        ? 'Bilinmiyor'
        : _updateDownloadService.formatFileSize(
            restoreData.info.backupSizeBytes!,
          );
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Buluttan Geri Yükle'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text('Bu işlem mevcut verilerin üzerine yazacaktır.'),
                const SizedBox(height: 12),
                Text('Son Yedekleme: $lastBackupText'),
                const SizedBox(height: 4),
                Text('Yedek Boyutu: $backupSizeText'),
                const SizedBox(height: 12),
                const Text(
                  'Devam etmek istiyor musunuz?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Geri Yükle'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _handleGoogleSignIn() async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      final nextState = await _cloudBackupService.signIn();
      if (!mounted) {
        return;
      }

      setState(() {
        _cloudAuthState = nextState;
      });

      if (!nextState.isSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google ile giriş başarısız oldu.')),
        );
        return;
      }

      final nextBackupInfo = await _cloudBackupService.getBackupInfo();
      if (!mounted) {
        return;
      }
      setState(() {
        _cloudBackupInfo = nextBackupInfo;
      });
    } on CloudBackupException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ ${e.message}')));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _handleCloudSignOut() async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await _cloudBackupService.signOut();
      final nextState = await _cloudBackupService.getAuthState();
      if (!mounted) {
        return;
      }
      setState(() {
        _cloudAuthState = nextState;
        _cloudBackupInfo = const CloudBackupInfo(
          provider: 'google',
          isSignedIn: false,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Widget _buildEmailNotificationTile({
    required IconData icon,
    required String title,
    required bool enabled,
    required String timeText,
    required DateTime? lastSentAt,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTimePressed,
    required String helperText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      helperText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: enabled, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onTimePressed,
                icon: const Icon(Icons.schedule),
                label: Text('Saat: $timeText'),
              ),
              Text(
                'Son Gönderim: ${_formatEmailSummaryDate(lastSentAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailNotificationsCard() {
    final recipientEmail =
        _cloudAuthState.user?.email ?? _cloudBackupInfo.user?.email;
    final isGoogleRequired = !_cloudAuthState.isSignedIn;
    final isDisabled =
        isGoogleRequired ||
        _busy ||
        _emailPreferencesBusy ||
        !_emailPreferencesLoaded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mark_email_unread_outlined),
                const SizedBox(width: 12),
                const Text(
                  '🔔 E-Posta Bildirimleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                if (_emailPreferencesBusy) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Gönderilecek Adres: ${recipientEmail ?? 'Google hesabı gerekli'}',
            ),
            const SizedBox(height: 4),
            Text(
              isGoogleRequired
                  ? 'Bu özellik için Google hesabı gereklidir.'
                  : 'Mail gönderimleri FontTakip sistem hesabı üzerinden yapılır.',
              style: TextStyle(
                color: isGoogleRequired ? Colors.orange : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: isDisabled,
              child: Opacity(
                opacity: isDisabled ? 0.6 : 1,
                child: Column(
                  children: [
                    _buildEmailNotificationTile(
                      icon: Icons.stacked_line_chart,
                      title: 'Günlük Fon Özeti Gönder',
                      enabled: _emailSummaryPreferences.fundSummaryEnabled,
                      timeText: _emailSummaryPreferences.fundSummaryTime,
                      lastSentAt:
                          _emailSummaryPreferences.lastFundSummarySentAt,
                      onChanged: (value) => _saveEmailSummaryPreferences(
                        _emailSummaryPreferences.copyWith(
                          fundSummaryEnabled: value,
                        ),
                      ),
                      onTimePressed: () =>
                          _pickEmailSummaryTime(isFundSummary: true),
                      helperText:
                          'Fon portföyü yoksa 09:30 özeti otomatik atlanır.',
                    ),
                    const SizedBox(height: 12),
                    _buildEmailNotificationTile(
                      icon: Icons.query_stats,
                      title: 'Günlük Hisse Özeti Gönder',
                      enabled: _emailSummaryPreferences.stockSummaryEnabled,
                      timeText: _emailSummaryPreferences.stockSummaryTime,
                      lastSentAt:
                          _emailSummaryPreferences.lastStockSummarySentAt,
                      onChanged: (value) => _saveEmailSummaryPreferences(
                        _emailSummaryPreferences.copyWith(
                          stockSummaryEnabled: value,
                        ),
                      ),
                      onTimePressed: () =>
                          _pickEmailSummaryTime(isFundSummary: false),
                      helperText:
                          'Hisse portföyü yoksa 18:30 özeti otomatik atlanır.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCloudUpload() async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      final nextBackupInfo = await _cloudBackupService.uploadBackup();
      final nextState = await _cloudBackupService.getAuthState();
      if (!mounted) {
        return;
      }

      setState(() {
        _cloudAuthState = nextState;
        _cloudBackupInfo = nextBackupInfo;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Bulut yedekleme tamamlandı')),
      );
    } on CloudBackupException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ ${e.message}')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bulut yedekleme sırasında bir hata oluştu'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _handleCloudRestore() async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      final restoreData = await _cloudBackupService.downloadBackup();
      if (!mounted) {
        return;
      }

      final confirmed = await _showCloudRestoreConfirmation(restoreData);
      if (!confirmed) {
        return;
      }

      await _cloudBackupService.restoreBackupData(restoreData.rawJson);
      if (!mounted) {
        return;
      }

      setState(() {
        _cloudBackupInfo = restoreData.info;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Yedek başarıyla geri yüklendi')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await SystemNavigator.pop();
    } on CloudBackupException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ ${e.message}')));
    } on FormatException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Bulut yedeği geçersiz veya bozuk')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bulut yedeği geri yüklenirken bir hata oluştu'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
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
      _apkInstallError = null;
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

      setState(() {
        _apkDownloadPath = apkPath;
      });

      final installResult = await _updateDownloadService.installApk(apkPath);
      if (!mounted) {
        return;
      }

      if (installResult == null ||
          installResult.contains('Kurulum başlatıldı')) {
        setState(() {
          _downloadingUpdate = false;
          _apkInstallError = null;
        });
      } else {
        setState(() {
          _downloadingUpdate = false;
          _apkInstallError = installResult;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('⚠️ $installResult')));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Güncelleme indirilemedi: ${e.toString()}')),
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
                          if (_apkDownloadPath != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(
                                  color: Colors.green.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '✅ APK İndirildi',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Dosya Konumu:',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    _apkDownloadPath!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_apkInstallError != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '⚠️ Kurulum Hatası',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _apkInstallError!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
          _buildEmailNotificationsCard(),
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
                  const SizedBox(height: 8),
                  if ((_cloudBackupInfo.user ?? _cloudAuthState.user)
                          ?.displayName !=
                      null)
                    Text(
                      'Ad: ${(_cloudBackupInfo.user ?? _cloudAuthState.user)!.displayName}',
                    ),
                  if ((_cloudBackupInfo.user ?? _cloudAuthState.user)
                          ?.displayName !=
                      null)
                    const SizedBox(height: 4),
                  Text(
                    'Google Hesabı: ${_cloudBackupInfo.user?.email ?? _cloudAuthState.user?.email ?? 'Giriş yapılmadı'}',
                  ),
                  const SizedBox(height: 4),
                  Text('Son Yedekleme: ${_formatCloudBackupDate()}'),
                  const SizedBox(height: 4),
                  Text('Yedek Boyutu: ${_formatCloudBackupSize()}'),
                  if (_cloudAuthState.isSignedIn) ...[
                    const SizedBox(height: 8),
                    Text(
                      _cloudBackupInfo.hasBackup
                          ? 'Bulutta kayıtlı yedek bulundu'
                          : 'Bulutta kayıtlı yedek bulunamadı',
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_cloudAuthState.isSignedIn) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy ? null : _handleCloudUpload,
                          icon: const Icon(Icons.upload),
                          label: const Text('Buluta Yedekle'),
                        ),
                        FilledButton.icon(
                          onPressed: _busy ? null : _handleCloudRestore,
                          icon: const Icon(Icons.download),
                          label: const Text('Buluttan Geri Yükle'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _handleCloudSignOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _handleGoogleSignIn,
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
