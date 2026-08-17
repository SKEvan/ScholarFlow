import 'dart:convert';
import 'package:flutter/foundation.dart';

class NoteModel {
  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'RESEARCH',
      updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  final String id;
  final String title;
  final String content;
  final String category;
  final String updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'updatedAt': updatedAt,
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NoteStorageService extends ChangeNotifier {
  static final NoteStorageService _instance = NoteStorageService._internal();
  factory NoteStorageService() => _instance;
  NoteStorageService._internal() {
    _loadInitialData();
  }

  final List<NoteModel> _notes = [];

  List<NoteModel> get notes => List.unmodifiable(_notes);

  void _loadInitialData() {
    // Initial JSON placeholder notes data
    const initialJsonString = '''
    [
      {
        "id": "note_101",
        "title": "Literature Review: Transformer Attention Gaps",
        "content": "Critical observation on multi-head attention overhead in large context windows. Need to explore Sparse Attention mechanisms and Linear Complexity models for paper section 3.",
        "category": "RESEARCH",
        "updatedAt": "2026-08-17T14:30:00Z"
      },
      {
        "id": "note_102",
        "title": "Lab Meeting with Dr. Vance",
        "content": "Discussed experimental design for high-frequency decision engines. Key takeaway: benchmark latency under 15ms threshold before next grant deadline.",
        "category": "MEETING",
        "updatedAt": "2026-08-16T10:15:00Z"
      },
      {
        "id": "note_103",
        "title": "Quantum Hybrid Benchmark Milestone",
        "content": "Achieved 65% convergence on quantum-classical hybrid nodes. Next step: prepare data tables and export figures for journal submission.",
        "category": "MILESTONE",
        "updatedAt": "2026-08-15T18:45:00Z"
      }
    ]
    ''';

    try {
      final List<dynamic> parsedList = json.decode(initialJsonString);
      _notes.clear();
      _notes.addAll(parsedList.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing initial notes JSON: $e');
      }
    }
  }

  // Exports all current notes as a JSON formatted string (ready for DB/API sync)
  String exportNotesAsJson() {
    final list = _notes.map((n) => n.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  // Import notes from JSON string
  void importNotesFromJson(String jsonString) {
    try {
      final List<dynamic> parsed = json.decode(jsonString);
      _notes.clear();
      _notes.addAll(parsed.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error importing notes JSON: $e');
      }
    }
  }

  Future<void> addNote(NoteModel note) async {
    _notes.insert(0, note);
    notifyListeners();
  }

  Future<void> updateNote(NoteModel updatedNote) async {
    final index = _notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
  }
}
