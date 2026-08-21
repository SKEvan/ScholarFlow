import 'package:flutter/material.dart';
import '../services/note_storage_service.dart';
import '../widgets/floating_nav_bar.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'RESEARCH';
  String? _noteId;
  bool _isEditing = false;
  bool _isSaving = false;

  final List<String> _categories = ['RESEARCH', 'MEETING', 'MILESTONE', 'IDEA'];
  final _storageService = NoteStorageService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('note')) {
      final note = args['note'] as NoteModel;
      if (!_isEditing) {
        _isEditing = true;
        _noteId = note.id;
        _titleController.text = note.title;
        _contentController.text = note.content;
        _selectedCategory = note.category;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note title.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now().toIso8601String();

    if (_isEditing && _noteId != null) {
      final updatedNote = NoteModel(
        id: _noteId!,
        title: title,
        content: content,
        category: _selectedCategory,
        updatedAt: now,
      );
      await _storageService.updateNote(updatedNote);
    } else {
      final newNote = NoteModel(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        category: _selectedCategory,
        updatedAt: now,
      );
      await _storageService.addNote(newNote);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Note updated successfully' : 'New note saved',
        ),
        backgroundColor: const Color(0xFF017ECB),
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _deleteNote() async {
    if (!_isEditing || _noteId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this research note?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteNote(_noteId!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note deleted')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brandColor = Color(0xFF017ECB);
    const lightSkyBlue = Color(0xFFEAF4FB);

    return Scaffold(
      backgroundColor: lightSkyBlue,
      appBar: AppBar(
        backgroundColor: lightSkyBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Note' : 'New Research Note',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
              ),
              onPressed: _deleteNote,
              tooltip: 'Delete Note',
            ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: brandColor,
                    ),
                  )
                : const Icon(Icons.save_rounded, color: brandColor),
            onPressed: _isSaving ? null : _saveNote,
            tooltip: 'Save Note',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                    children: [
                      // Category Selection
                      const Text(
                        'CATEGORY',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: brandColor,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? brandColor
                                      : const Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Single Unified Editor Sheet Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        constraints: const BoxConstraints(minHeight: 340),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seamless Title Input Field
                            TextField(
                              controller: _titleController,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Note Title...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Formatting Toolbar
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _ToolButton(
                                    icon: Icons.format_bold_rounded,
                                    onTap: () {},
                                  ),
                                  _ToolButton(
                                    icon: Icons.format_italic_rounded,
                                    onTap: () {},
                                  ),
                                  _ToolButton(
                                    icon: Icons.format_list_bulleted_rounded,
                                    onTap: () {},
                                  ),
                                  _ToolButton(
                                    icon: Icons.format_quote_rounded,
                                    onTap: () {},
                                  ),
                                  _ToolButton(
                                    icon: Icons.code_rounded,
                                    onTap: () {},
                                  ),
                                  Container(
                                    height: 18,
                                    width: 1,
                                    color: const Color(0xFFE2E8F0),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                  ),
                                  _ToolButton(
                                    icon: Icons.auto_awesome,
                                    color: Colors.amber[700],
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'AI Assistant: Inserted paper citation stub',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),

                            // Content Text Area
                            TextField(
                              controller: _contentController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF334155),
                                height: 1.55,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Start documenting your research findings, formulas, and citations...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
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
          ),

          // Floating Glassmorphism Navigation Bar at the bottom
          const Positioned.fill(child: FloatingNavBar(currentRoute: '/notes')),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 19, color: color ?? const Color(0xFF64748B)),
      ),
    );
  }
}
