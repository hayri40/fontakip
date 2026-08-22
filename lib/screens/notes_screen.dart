import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _notesKey = 'tools.notes.items';

  final List<_NoteItem> _notes = [];
  SharedPreferences? _prefs;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final raw = prefs.getString(_notesKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _notes
        ..clear()
        ..addAll(
          decoded.map((item) {
            final map = item as Map<String, dynamic>;
            return _NoteItem(
              id: map['id'] as String,
              title: map['title'] as String,
              content: map['content'] as String,
              createdAt: DateTime.parse(map['createdAt'] as String),
            );
          }),
        );
    }
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _notesKey,
      jsonEncode(
        _notes
            .map(
              (note) => {
                'id': note.id,
                'title': note.title,
                'content': note.content,
                'createdAt': note.createdAt.toIso8601String(),
              },
            )
            .toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Future<void> _openNoteForm({_NoteItem? note}) async {
    var title = note?.title ?? '';
    var content = note?.content ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(note == null ? 'Not Ekle' : 'Notu Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  onChanged: (value) => title = value,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: content,
                  onChanged: (value) => content = value,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'İçerik',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    title = title.trim();
    content = content.trim();

    if (title.isEmpty || content.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve içerik boş bırakılamaz.')),
      );
      return;
    }

    setState(() {
      if (note == null) {
        _notes.insert(
          0,
          _NoteItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            content: content,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        final index = _notes.indexWhere((item) => item.id == note.id);
        if (index >= 0) {
          _notes[index] = _NoteItem(
            id: note.id,
            title: title,
            content: content,
            createdAt: note.createdAt,
          );
        }
      }
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    _saveNotes();
  }

  Future<void> _deleteNote(_NoteItem note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notu Sil'),
          content: const Text('Bu not silinecek. Devam etmek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet, Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    setState(() {
      _notes.removeWhere((item) => item.id == note.id);
    });
    _saveNotes();
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
        title: const Text('Notlarım'),
        centerTitle: true,
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Text('Henüz not yok.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_formatDate(note.createdAt)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _NoteDetailScreen(
                            title: note.title,
                            content: note.content,
                            dateLabel: _formatDate(note.createdAt),
                          ),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openNoteForm(note: note);
                        } else if (value == 'delete') {
                          _deleteNote(note);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Düzenle'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Sil'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String dateLabel;

  const _NoteDetailScreen({
    required this.title,
    required this.content,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Detayı'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dateLabel,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(content),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteItem {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  _NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });
}
