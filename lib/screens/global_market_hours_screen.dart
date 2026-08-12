import 'dart:async';

import 'package:flutter/material.dart';

enum _SessionStatus { open, openingSoon, closingSoon, closed }

class _ForexSession {
  final String name;
  final double utcOffsetHours;
  final int openHour;
  final int openMinute;
  final int closeHour;
  final int closeMinute;

  const _ForexSession({
    required this.name,
    required this.utcOffsetHours,
    required this.openHour,
    required this.openMinute,
    required this.closeHour,
    required this.closeMinute,
  });
}

class _SessionSnapshot {
  final _ForexSession session;
  final _SessionStatus status;
  final DateTime openLocal;
  final DateTime closeLocal;
  final DateTime nextOpenLocal;
  final Duration? timeToClose;
  final Duration timeToOpen;

  const _SessionSnapshot({
    required this.session,
    required this.status,
    required this.openLocal,
    required this.closeLocal,
    required this.nextOpenLocal,
    required this.timeToClose,
    required this.timeToOpen,
  });
}

class GlobalMarketHoursScreen extends StatefulWidget {
  const GlobalMarketHoursScreen({super.key});

  @override
  State<GlobalMarketHoursScreen> createState() =>
      _GlobalMarketHoursScreenState();
}

class _GlobalMarketHoursScreenState extends State<GlobalMarketHoursScreen> {
  static const List<_ForexSession> _sessions = <_ForexSession>[
    _ForexSession(
      name: 'Sydney',
      utcOffsetHours: 10,
      openHour: 8,
      openMinute: 0,
      closeHour: 17,
      closeMinute: 0,
    ),
    _ForexSession(
      name: 'Tokyo',
      utcOffsetHours: 9,
      openHour: 9,
      openMinute: 0,
      closeHour: 18,
      closeMinute: 0,
    ),
    _ForexSession(
      name: 'Londra',
      utcOffsetHours: 1,
      openHour: 8,
      openMinute: 0,
      closeHour: 17,
      closeMinute: 0,
    ),
    _ForexSession(
      name: 'New York',
      utcOffsetHours: -4,
      openHour: 8,
      openMinute: 0,
      closeHour: 17,
      closeMinute: 0,
    ),
  ];

  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = _sessions.map((s) => _snapshotFor(s, _now)).toList();
    final active = snapshots.where(_isActiveLike).toList();
    snapshots.sort((a, b) => a.timeToOpen.compareTo(b.timeToOpen));
    final nextSession = snapshots.first;
    final forexOpen = active.isNotEmpty;
    final overlapNow = _activeOverlapNames(active);
    final volatility = _volatilityLabel(active.length);
    final volatilityEmoji = _volatilityEmoji(active.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forex Seans Rehberi'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yerel Saat',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${_dayName(_now.weekday)}\n${_two(_now.hour)}:${_two(_now.minute)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Forex Durumu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    forexOpen ? '🟢 Açık' : '🔴 Kapalı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: forexOpen ? Colors.green : Colors.red,
                    ),
                  ),
                  if (!forexOpen) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Açılış: ${_dayName(nextSession.nextOpenLocal.weekday)} ${_time(nextSession.nextOpenLocal)}',
                    ),
                    Text('Kalan: ${_duration(nextSession.timeToOpen)}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _timelineCard(snapshots),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Şu An Aktif',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (active.isEmpty)
                    const Text('🔴 Forex Kapalı')
                  else
                    ...active.map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('🟢 ${s.session.name}'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bir Sonraki Seans',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextSession.session.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('Açılış: ${_time(nextSession.nextOpenLocal)}'),
                  Text('Kalan: ${_duration(nextSession.timeToOpen)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seans Çakışmaları',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _overlapRow(
                    'Sydney + Tokyo',
                    'Normal Hacim',
                    overlapNow.contains('Sydney + Tokyo'),
                  ),
                  _overlapRow(
                    'Tokyo + Londra',
                    'Yüksek Hacim',
                    overlapNow.contains('Tokyo + Londra'),
                  ),
                  _overlapRow(
                    'Londra + New York',
                    'Çok Yüksek Hacim',
                    overlapNow.contains('Londra + New York'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Volatilite',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$volatilityEmoji $volatility',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seanslar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...snapshots.map(
                    (item) => ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                      title: Text(item.session.name),
                      subtitle: Text(
                        '${_statusText(item.status)}\nAçılış: ${_time(item.openLocal)} • Kapanış: ${_time(item.closeLocal)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _SessionDetailScreen(
                              snapshot: item,
                              statusText: _statusText,
                              time: _time,
                              duration: _duration,
                              dayName: _dayName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineCard(List<_SessionSnapshot> snapshots) {
    final timelineWidth = MediaQuery.of(context).size.width - 48;
    final hourWidth = timelineWidth / 24;
    final nowPosition = (_now.hour + (_now.minute / 60.0)) * hourWidth;
    const rowHeight = 20.0;
    const rowGap = 6.0;
    final rowsHeight =
        (snapshots.length * rowHeight) + ((snapshots.length - 1) * rowGap);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final closedColor = isDark
        ? Colors.grey.shade900.withOpacity(0.8)
        : Colors.grey.shade200.withOpacity(0.9);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: timelineWidth,
              height: 16,
              child: Stack(
                children: List.generate(25, (i) {
                  final left = (i * hourWidth).clamp(0.0, timelineWidth - 16);
                  return Positioned(
                    left: left,
                    child: SizedBox(
                      width: 16,
                      child: Text(
                        i == 24 ? '24' : _two(i),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Stack(
              children: [
                SizedBox(
                  width: timelineWidth,
                  height: rowsHeight,
                  child: Column(
                    children: [
                      for (var i = 0; i < snapshots.length; i++) ...[
                        _timelineRow(
                          snapshots[i],
                          hourWidth: hourWidth,
                          laneWidth: timelineWidth,
                          closedColor: closedColor,
                        ),
                        if (i < snapshots.length - 1)
                          const SizedBox(height: rowGap),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: nowPosition,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3, color: Colors.amberAccent),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '│ ${_two(_now.hour)}:${_two(_now.minute)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.amberAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineRow(
    _SessionSnapshot snapshot, {
    required double hourWidth,
    required double laneWidth,
    required Color closedColor,
  }) {
    final interval = _todayLocalInterval(snapshot.session);
    final startHour = interval.$1.hour + interval.$1.minute / 60.0;
    var endHour = interval.$2.hour + interval.$2.minute / 60.0;
    if (interval.$2.day != interval.$1.day || endHour <= startHour) {
      endHour += 24;
    }
    final start = startHour.clamp(0.0, 24.0);
    final end = endHour.clamp(0.0, 24.0);
    final width = (end - start) * hourWidth;
    final isActive = _isActiveLike(snapshot);

    return SizedBox(
      height: 20,
      child: SizedBox(
        width: laneWidth,
        child: Stack(
          children: [
            Container(color: closedColor),
            Positioned(
              left: start * hourWidth,
              top: 0,
              width: width < 0 ? 0 : width,
              height: 20,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.8)
                      : Colors.green.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '[${snapshot.session.name}]',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlapRow(String name, String volume, bool activeNow) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(
            activeNow ? '🟢 $volume' : volume,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Set<String> _activeOverlapNames(List<_SessionSnapshot> active) {
    final names = active.map((e) => e.session.name).toSet();
    final result = <String>{};
    if (names.contains('Sydney') && names.contains('Tokyo')) {
      result.add('Sydney + Tokyo');
    }
    if (names.contains('Tokyo') && names.contains('Londra')) {
      result.add('Tokyo + Londra');
    }
    if (names.contains('Londra') && names.contains('New York')) {
      result.add('Londra + New York');
    }
    return result;
  }

  String _volatilityLabel(int activeCount) {
    if (activeCount >= 3) return 'Çok Yüksek';
    if (activeCount == 2) return 'Yüksek';
    if (activeCount == 1) return 'Normal';
    return 'Düşük';
  }

  String _volatilityEmoji(int activeCount) {
    if (activeCount >= 3) return '🔴';
    if (activeCount == 2) return '🟠';
    if (activeCount == 1) return '🟡';
    return '🟢';
  }

  bool _isActiveLike(_SessionSnapshot s) {
    return s.status == _SessionStatus.open ||
        s.status == _SessionStatus.closingSoon;
  }

  _SessionSnapshot _snapshotFor(_ForexSession session, DateTime localNow) {
    final centerNow = localNow.toUtc().add(_offset(session.utcOffsetHours));
    final centerDate = DateTime(centerNow.year, centerNow.month, centerNow.day);
    final openCenter = DateTime(
      centerDate.year,
      centerDate.month,
      centerDate.day,
      session.openHour,
      session.openMinute,
    );
    var closeCenter = DateTime(
      centerDate.year,
      centerDate.month,
      centerDate.day,
      session.closeHour,
      session.closeMinute,
    );
    final overnight = !closeCenter.isAfter(openCenter);
    if (overnight) {
      closeCenter = closeCenter.add(const Duration(days: 1));
    }

    final isWeekend =
        centerNow.weekday == DateTime.saturday ||
        centerNow.weekday == DateTime.sunday;
    final openLocal = _centerToLocal(openCenter, session.utcOffsetHours);
    final closeLocal = _centerToLocal(closeCenter, session.utcOffsetHours);
    final nextOpenCenter = _nextOpenCenter(
      session,
      centerNow,
      openCenter,
      closeCenter,
    );
    final nextOpenLocal = _centerToLocal(
      nextOpenCenter,
      session.utcOffsetHours,
    );
    final timeToOpen = nextOpenCenter.difference(centerNow);

    if (isWeekend) {
      return _SessionSnapshot(
        session: session,
        status: _SessionStatus.closed,
        openLocal: openLocal,
        closeLocal: closeLocal,
        nextOpenLocal: nextOpenLocal,
        timeToOpen: timeToOpen,
        timeToClose: null,
      );
    }

    final inTodayWindow =
        centerNow.isAfter(openCenter) && centerNow.isBefore(closeCenter);
    final prevOpen = openCenter.subtract(const Duration(days: 1));
    final prevClose = closeCenter.subtract(const Duration(days: 1));
    final inPrevWindow =
        overnight &&
        centerNow.isAfter(prevOpen) &&
        centerNow.isBefore(prevClose);
    final isOpen = inTodayWindow || inPrevWindow;

    if (isOpen) {
      final closeRef = inPrevWindow ? prevClose : closeCenter;
      final remaining = closeRef.difference(centerNow);
      return _SessionSnapshot(
        session: session,
        status: remaining <= const Duration(hours: 1)
            ? _SessionStatus.closingSoon
            : _SessionStatus.open,
        openLocal: openLocal,
        closeLocal: closeLocal,
        nextOpenLocal: nextOpenLocal,
        timeToOpen: timeToOpen,
        timeToClose: remaining,
      );
    }

    return _SessionSnapshot(
      session: session,
      status: timeToOpen <= const Duration(hours: 1)
          ? _SessionStatus.openingSoon
          : _SessionStatus.closed,
      openLocal: openLocal,
      closeLocal: closeLocal,
      nextOpenLocal: nextOpenLocal,
      timeToOpen: timeToOpen,
      timeToClose: null,
    );
  }

  DateTime _nextOpenCenter(
    _ForexSession session,
    DateTime centerNow,
    DateTime todayOpen,
    DateTime todayClose,
  ) {
    if (centerNow.isBefore(todayOpen) && !_isWeekend(centerNow)) {
      return todayOpen;
    }
    var dayOffset = 1;
    for (var i = dayOffset; i < 14; i++) {
      final probe = centerNow.add(Duration(days: i));
      if (!_isWeekend(probe)) {
        return DateTime(
          probe.year,
          probe.month,
          probe.day,
          session.openHour,
          session.openMinute,
        );
      }
    }
    return todayClose.add(const Duration(hours: 1));
  }

  bool _isWeekend(DateTime value) {
    return value.weekday == DateTime.saturday ||
        value.weekday == DateTime.sunday;
  }

  (DateTime, DateTime) _todayLocalInterval(_ForexSession session) {
    final centerNow = _now.toUtc().add(_offset(session.utcOffsetHours));
    final centerDate = DateTime(centerNow.year, centerNow.month, centerNow.day);
    final openCenter = DateTime(
      centerDate.year,
      centerDate.month,
      centerDate.day,
      session.openHour,
      session.openMinute,
    );
    var closeCenter = DateTime(
      centerDate.year,
      centerDate.month,
      centerDate.day,
      session.closeHour,
      session.closeMinute,
    );
    if (!closeCenter.isAfter(openCenter)) {
      closeCenter = closeCenter.add(const Duration(days: 1));
    }
    return (
      _centerToLocal(openCenter, session.utcOffsetHours),
      _centerToLocal(closeCenter, session.utcOffsetHours),
    );
  }

  DateTime _centerToLocal(DateTime centerDateTime, double centerOffset) {
    final utc = DateTime.utc(
      centerDateTime.year,
      centerDateTime.month,
      centerDateTime.day,
      centerDateTime.hour,
      centerDateTime.minute,
    ).subtract(_offset(centerOffset));
    return utc.toLocal();
  }

  Duration _offset(double offsetHour) =>
      Duration(minutes: (offsetHour * 60).round());

  String _statusText(_SessionStatus status) {
    switch (status) {
      case _SessionStatus.open:
        return '🟢 Açık';
      case _SessionStatus.openingSoon:
        return '🟡 Açılmasına 1 saatten az kaldı';
      case _SessionStatus.closingSoon:
        return '🟠 Kapanmasına 1 saatten az kaldı';
      case _SessionStatus.closed:
        return '🔴 Kapalı';
    }
  }

  String _duration(Duration value) {
    final mins = value.inMinutes;
    if (mins <= 0) return '0dk';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h <= 0) return '${_two(m)}dk';
    return '${h}s ${_two(m)}dk';
  }

  String _time(DateTime value) => '${_two(value.hour)}:${_two(value.minute)}';

  String _dayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Pazartesi';
      case DateTime.tuesday:
        return 'Salı';
      case DateTime.wednesday:
        return 'Çarşamba';
      case DateTime.thursday:
        return 'Perşembe';
      case DateTime.friday:
        return 'Cuma';
      case DateTime.saturday:
        return 'Cumartesi';
      case DateTime.sunday:
        return 'Pazar';
      default:
        return '';
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _SessionDetailScreen extends StatelessWidget {
  final _SessionSnapshot snapshot;
  final String Function(_SessionStatus status) statusText;
  final String Function(DateTime value) time;
  final String Function(Duration value) duration;
  final String Function(int weekday) dayName;

  const _SessionDetailScreen({
    required this.snapshot,
    required this.statusText,
    required this.time,
    required this.duration,
    required this.dayName,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = snapshot.timeToClose ?? snapshot.timeToOpen;
    return Scaffold(
      appBar: AppBar(title: Text(snapshot.session.name)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.session.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _row('Durum', statusText(snapshot.status)),
                  _row('Açılış', time(snapshot.openLocal)),
                  _row('Kapanış', time(snapshot.closeLocal)),
                  _row(
                    'Kalan Süre',
                    remaining == null ? '-' : duration(remaining),
                  ),
                  _row(
                    'Bir Sonraki Açılış',
                    '${dayName(snapshot.nextOpenLocal.weekday)} ${time(snapshot.nextOpenLocal)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
