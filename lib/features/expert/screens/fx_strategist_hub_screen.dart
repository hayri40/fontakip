import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/formatters/app_formatters.dart';
import '../../../models/expert_models.dart';
import '../../../models/fx_asset.dart';
import '../../../services/expert_service.dart';
import '../../../services/expert_firestore_service.dart';
import '../../../services/fx_market_service.dart';
import '../widgets/expert_chat_bubble.dart';
import '../widgets/expert_action_bar.dart';
import '../widgets/trading_view_chart.dart';
import 'rules_manager_screen.dart';
import '../widgets/expert_action_bar.dart';
import '../widgets/trading_view_chart.dart';
import 'fullscreen_chart_screen.dart';
import 'rules_manager_screen.dart';

class FxStrategistHubScreen extends StatefulWidget {
  const FxStrategistHubScreen({super.key});

  @override
  State<FxStrategistHubScreen> createState() => _FxStrategistHubScreenState();
}

class _FxStrategistHubScreenState extends State<FxStrategistHubScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ExpertChatMessage> _messages = [];
  final ScrollController _pageScrollController = ScrollController();
  
  final ExpertService _expertService = ExpertService();
  final ExpertFirestoreService _firestoreService = ExpertFirestoreService();
  final FxMarketService _marketService = const FxMarketService();
  
  // Use a GlobalKey to keep the TradingViewChart alive across layout changes
  final GlobalKey _chartKey = GlobalKey();
  
  List<ExpertRule> _activeRules = [];
  bool _isLoading = false;
  bool _isFullScreen = false;
  String _currentSymbol = 'FX:GBPCAD';
  double _fxBalanceUsd = 0.0;
  double _usdTryRate = 0.0;
  double _scrollOffset = 0;
  List<String> _watchlist = [];

  @override
  void initState() {
    super.initState();
    _loadRules();
    _loadInitialState();
    _pageScrollController.addListener(() {
      if (!_isFullScreen && mounted) {
        setState(() {
          _scrollOffset = _pageScrollController.offset;
        });
      }
    });
    _messages.add(ExpertChatMessage(
      id: 'init',
      sender: 'expert',
      text: 'Merhaba! Ben FX Baş Stratejistiniz. Hafızamdaki kuralları yükledim, analiz yapmaya hazırım. Bugün hangi pariteyi inceleyelim?',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fxBalanceUsd = prefs.getDouble('fx.balance_usd') ?? 0.0;
      });
    }

    // Fetch USDTRY rate
    try {
      final asset = await _marketService.getDetailBySymbol(
        symbol: 'USD/TRY',
        name: 'USD/TRY',
        type: FxAssetType.currency,
      );
      if (mounted) {
        setState(() {
          _usdTryRate = asset.currentPrice ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching USDTRY for balance: $e');
    }

    // Load last chart state
    final state = await _firestoreService.getChartState();
    if (state != null && mounted) {
      setState(() {
        _currentSymbol = state['currentSymbol'] ?? _currentSymbol;
      });
    }

    // Load watchlist stream
    _firestoreService.streamWatchlist().listen((list) {
      if (mounted) {
        setState(() {
          _watchlist = list;
        });
      }
    });
  }

  void _onSymbolChanged(String newSymbol) {
    debugPrint('TV_LOG: Hub received newSymbol: $newSymbol. Current: $_currentSymbol');
    if (newSymbol != _currentSymbol) {
      setState(() {
        _currentSymbol = newSymbol;
      });
      _firestoreService.saveChartState(newSymbol, '60');
    }
  }

  Future<void> _toggleFavorite() async {
    final symbol = _currentSymbol;
    final isFav = _watchlist.contains(symbol);
    
    debugPrint('TV_LOG: [FAVORITE_ACTION] User clicked STAR. Current Hub Symbol: $symbol');
    debugPrint('TV_LOG: [WATCHLIST_STATE] Watchlist contains $symbol: $isFav');

    try {
      await _firestoreService.toggleWatchlist(symbol, !isFav);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!isFav ? '$symbol favorilere eklendi' : '$symbol favorilerden kaldırıldı'),
          duration: const Duration(seconds: 1),
          backgroundColor: !isFav ? Colors.green : Colors.blueGrey,
        ),
      );
    } catch (e) {
      debugPrint('WATCHLIST_LOG: Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadRules() async {
    // We can't use stream directly here for the prompt context easily without state management
    // So we'll fetch once or listen to updates
    _firestoreService.streamRules().listen((rules) {
      if (mounted) {
        setState(() {
          _activeRules = rules.where((r) => r.isActive).toList();
        });
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = ExpertChatMessage(
      id: DateTime.now().toString(),
      sender: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _expertService.sendMessage(
        message: text,
        activeRules: _activeRules,
        history: _messages.map((m) => {'sender': m.sender, 'text': m.text}).toList(),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(response);
        if (response.analysisSetup != null) {
          _currentSymbol = 'FX:${response.analysisSetup!.pair.replaceAll('/', '')}';
        }
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ExpertChatMessage(
          id: DateTime.now().toString(),
          sender: 'expert',
          text: '⚠️ Hata oluştu: ${e.toString()}',
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveLearnedRule(ExpertRule rule) async {
    try {
      // Calculate display ID (next one)
      final allRules = await _firestoreService.streamRules().first;
      final nextId = allRules.isEmpty ? 1 : allRules.map((r) => r.displayId).reduce((a, b) => a > b ? a : b) + 1;
      
      final ruleToSave = ExpertRule(
        id: '',
        displayId: nextId,
        title: rule.title,
        rule: rule.rule,
        category: rule.category,
        learnedAt: DateTime.now(),
        sourceContext: 'Sohbet sırasında öğrenildi',
      );

      await _firestoreService.addRule(ruleToSave);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kural #$nextId hafızaya eklendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kural kaydedilemedi: $e')),
      );
    }
  }

  Widget _buildBalanceInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FX Bakiyesi (USD)',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: _fxBalanceUsd == 0 ? '' : _fxBalanceUsd.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.white24),
            ),
            onChanged: _updateBalance,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    final tlValue = _fxBalanceUsd * _usdTryRate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TL Karşılığı',
            style: TextStyle(color: Colors.cyan, fontSize: 10),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppFormatters.currencyValue(tlValue),
              style: const TextStyle(
                color: Colors.cyan,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_pageScrollController.hasClients) {
        _pageScrollController.animateTo(
          _pageScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _updateBalance(String value) async {
    final val = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fx.balance_usd', val);
    if (mounted) {
      setState(() {
        _fxBalanceUsd = val;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final chartHeightNormal = screenHeight * 0.65;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      resizeToAvoidBottomInset: true,
      appBar: _isFullScreen 
          ? null 
          : AppBar(
              backgroundColor: const Color(0xFF161922),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FX Baş Stratejisti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.orange : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isLoading ? 'Analiz Hazırlanıyor...' : 'Aktif Analiz Modu • ${_activeRules.length} Kural',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.psychology, color: Colors.cyan),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RulesManagerScreen()),
                    );
                  },
                ),
              ],
            ),
      body: SafeArea(
        top: !_isFullScreen,
        child: Stack(
          children: [
            // Layer 1: Scrollable Chat Content
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _pageScrollController,
                    physics: _isFullScreen ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Space for the Chart (it floats above this via Stack)
                        SizedBox(height: chartHeightNormal),

                        // ORTA KISIM: SOHBET BAŞLIĞI
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          child: const Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.cyan),
                              SizedBox(width: 8),
                              Text(
                                'Uzman Analiz Sohbeti',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                        // MESAJLAR
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => ExpertChatBubble(
                            message: _messages[index],
                            onSaveRule: _saveLearnedRule,
                          ),
                        ),

                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.cyan, strokeWidth: 2),
                            ),
                          ),
                        
                        const SizedBox(height: 120), // Extra padding for input
                      ],
                    ),
                  ),
                ),

                // ALT KISIM: KOMUTLAR VE INPUT (Sticky at bottom)
                if (!_isFullScreen)
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F1117),
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExpertActionBar(onCommand: _sendMessage),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1D24),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    style: const TextStyle(fontSize: 14, color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Strateji sor veya analiz iste...',
                                      hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: _sendMessage,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: _isLoading ? Colors.grey : Colors.cyan,
                                child: IconButton(
                                  icon: _isLoading 
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : const Icon(Icons.send, color: Colors.black, size: 18),
                                  onPressed: () => _sendMessage(_messageController.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Layer 2: The Chart (Positioned to handle scroll and fullscreen)
            Positioned(
              top: _isFullScreen ? 0 : -_scrollOffset,
              left: 0,
              right: 0,
              height: _isFullScreen ? screenHeight : chartHeightNormal,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF131722),
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        if (!_isFullScreen)
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            color: const Color(0xFF161922),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildBalanceInput(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildBalanceDisplay(),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: TradingViewChart(
                            key: _chartKey,
                            symbol: _currentSymbol,
                            showControls: true,
                            onSymbolChanged: _onSymbolChanged,
                          ),
                        ),
                      ],
                    ),
                    
                    // NEW: Right Bar for Fav, Watchlist, and Fullscreen
                    if (!_isFullScreen)
                      Positioned(
                        top: 60, // Adjusted for balance bar
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Watchlist Dropdown
                            PopupMenuButton<String>(
                              onSelected: (String symbol) {
                                setState(() {
                                  _currentSymbol = symbol;
                                });
                              },
                              offset: const Offset(0, 40),
                              color: const Color(0xFF1A1D24),
                              itemBuilder: (BuildContext context) {
                                if (_watchlist.isEmpty) {
                                  return [
                                    const PopupMenuItem(
                                      enabled: false,
                                      child: Text('Liste boş', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                    )
                                  ];
                                }
                                return _watchlist.map((String symbol) {
                                  return PopupMenuItem<String>(
                                    value: symbol,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 8),
                                        Text(symbol, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1D24).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Row(
                                  children: [
                                    Text('Watchlist', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                    Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Favorite Star
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _toggleFavorite,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1D24).withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Icon(
                                    _watchlist.contains(_currentSymbol) ? Icons.star : Icons.star_border,
                                    color: _watchlist.contains(_currentSymbol) ? Colors.amber : Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Fullscreen Toggle Button
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isFullScreen = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1D24).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Fullscreen Exit (only visible in full screen)
                    if (_isFullScreen)
                      Positioned(
                        top: topPadding + 8,
                        right: 12,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isFullScreen = false;
                              _scrollOffset = _pageScrollController.offset;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D24).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))
                              ],
                            ),
                            child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 22),
                          ),
                        ),
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
}
