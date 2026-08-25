import 'package:flutter/material.dart';

import '../services/data_source_connection_test_service.dart';
import '../services/data_source_settings_service.dart';

class DataSourcesScreen extends StatefulWidget {
  final DataSourceSettingsService? settingsService;
  final DataSourceConnectionTestService? connectionTestService;

  const DataSourcesScreen({
    super.key,
    this.settingsService,
    this.connectionTestService,
  });

  @override
  State<DataSourcesScreen> createState() => _DataSourcesScreenState();
}

class _DataSourcesScreenState extends State<DataSourcesScreen> {
  late final DataSourceSettingsService _settingsService;
  late final DataSourceConnectionTestService _connectionTestService;

  final _fundProviderController = TextEditingController();
  final _fundApiKeyController = TextEditingController();
  final _stockApiUrlController = TextEditingController();
  final _stockApiKeyController = TextEditingController();
  final _fxProviderController = TextEditingController();
  final _fxApiKeyController = TextEditingController();
  final _geminiApiKeyController = TextEditingController();

  bool _showFundApiKey = false;
  bool _showStockApiKey = false;
  bool _showFxApiKey = false;
  bool _showGeminiApiKey = false;
  bool _stockAppendDotIs = false;
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? DataSourceSettingsService.instance;
    _connectionTestService =
        widget.connectionTestService ?? const DataSourceConnectionTestService();
    _load();
  }

  @override
  void dispose() {
    _fundProviderController.dispose();
    _fundApiKeyController.dispose();
    _stockApiUrlController.dispose();
    _stockApiKeyController.dispose();
    _fxProviderController.dispose();
    _fxApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fund = await _settingsService.getFundSource();
    final stock = await _settingsService.getStockSource();
    final fx = await _settingsService.getFxSource();

    _fundProviderController.text = fund.providerName;
    _fundApiKeyController.text = fund.apiKey;
    _stockApiUrlController.text = stock.apiUrl;
    _stockApiKeyController.text = stock.apiKey;
    _stockAppendDotIs = stock.appendDotIs;
    _fxProviderController.text = fx.providerName;
    _fxApiKeyController.text = fx.apiKey;
    _geminiApiKeyController.text = await _settingsService.getGeminiApiKey();

    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  Future<void> _saveFund() async {
    await _settingsService.saveFundSource(
      providerName: _fundProviderController.text,
      apiKey: _fundApiKeyController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fon veri kaynağı kaydedildi.')),
    );
  }

  Future<void> _saveStock() async {
    await _settingsService.saveStockSource(
      apiUrl: _stockApiUrlController.text,
      apiKey: _stockApiKeyController.text,
      appendDotIs: _stockAppendDotIs,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hisse veri kaynağı kaydedildi.')),
    );
  }

  Future<void> _saveFx() async {
    await _settingsService.saveFxSource(
      providerName: _fxProviderController.text,
      apiKey: _fxApiKeyController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FX veri kaynağı kaydedildi.')),
    );
  }

  Future<void> _saveGemini() async {
    await _settingsService.saveGeminiApiKey(_geminiApiKeyController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini API anahtarı kaydedildi.')),
    );
  }

  Future<void> _runTest(Future<String> Function() runner) async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      final result = await runner();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veri Kaynakları'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sourceCard(
            title: 'Fon Veri Kaynağı',
            child: _providerApiContent(
              providerController: _fundProviderController,
              apiKeyController: _fundApiKeyController,
              visible: _showFundApiKey,
              onToggleVisible: () {
                setState(() {
                  _showFundApiKey = !_showFundApiKey;
                });
              },
              onSave: _saveFund,
              onTest: () {
                _runTest(() {
                  return _connectionTestService.testFundConnection(
                    providerName: _fundProviderController.text,
                    apiKey: _fundApiKeyController.text,
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _sourceCard(
            title: 'Hisse Veri Kaynağı',
            child: Column(
              children: [
                TextField(
                  controller: _stockApiUrlController,
                  decoration: const InputDecoration(
                    labelText: 'API URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _stockApiKeyController,
                  obscureText: !_showStockApiKey,
                  decoration: InputDecoration(
                    labelText: 'API Anahtarı',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _showStockApiKey = !_showStockApiKey;
                        });
                      },
                      icon: Icon(
                        _showStockApiKey ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                CheckboxListTile(
                  value: _stockAppendDotIs,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sembole .IS ekle'),
                  onChanged: (value) {
                    setState(() {
                      _stockAppendDotIs = value ?? false;
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _saveStock,
                        child: const Text('Kaydet'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () {
                                _runTest(() {
                                  return _connectionTestService.testStockConnection(
                                    apiUrl: _stockApiUrlController.text,
                                    apiKey: _stockApiKeyController.text,
                                    appendDotIs: _stockAppendDotIs,
                                  );
                                });
                              },
                        child: const Text('Bağlantıyı Test Et'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sourceCard(
            title: 'FX Veri Kaynağı',
            child: _providerApiContent(
              providerController: _fxProviderController,
              apiKeyController: _fxApiKeyController,
              visible: _showFxApiKey,
              onToggleVisible: () {
                setState(() {
                  _showFxApiKey = !_showFxApiKey;
                });
              },
              onSave: _saveFx,
              onTest: () {
                _runTest(() {
                  return _connectionTestService.testFxConnection(
                    providerName: _fxProviderController.text,
                    apiKey: _fxApiKeyController.text,
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _sourceCard(
            title: 'Gemini AI (FX Uzmanı)',
            child: Column(
              children: [
                TextField(
                  controller: _geminiApiKeyController,
                  obscureText: !_showGeminiApiKey,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Anahtarı',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _showGeminiApiKey = !_showGeminiApiKey;
                        });
                      },
                      icon: Icon(
                        _showGeminiApiKey ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _saveGemini,
                    icon: const Icon(Icons.save),
                    label: const Text('API Anahtarını Kaydet'),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'FX Baş Stratejisti ile konuşabilmek için geçerli bir Gemini API anahtarı gereklidir.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
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

  Widget _sourceCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _providerApiContent({
    required TextEditingController providerController,
    required TextEditingController apiKeyController,
    required bool visible,
    required VoidCallback onToggleVisible,
    required VoidCallback onSave,
    required VoidCallback onTest,
  }) {
    return Column(
      children: [
        TextField(
          controller: providerController,
          decoration: const InputDecoration(
            labelText: 'Sağlayıcı Adı',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: apiKeyController,
          obscureText: !visible,
          decoration: InputDecoration(
            labelText: 'API Anahtarı',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: onToggleVisible,
              icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : onSave,
                child: const Text('Kaydet'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _busy ? null : onTest,
                child: const Text('Bağlantıyı Test Et'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
