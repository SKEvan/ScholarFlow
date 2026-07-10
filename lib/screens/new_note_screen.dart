import 'package:flutter/material.dart';

class NewNoteScreen extends StatefulWidget {
  const NewNoteScreen({super.key});

  @override
  State<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'RESEARCH';
  bool _isSaving = false;
  bool _isSaved = false;

  final List<String> _categories = ['RESEARCH', 'MEETING', 'MILESTONE'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    setState(() {
      _isSaving = true;
    });

    // Simulate saving
    Future.delayed(const Duration(seconds: 1500 ~/ 1000), () {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      // Show temporary saved indicator and go back
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'New Note',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
            onPressed: () {
              // Context menu action
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Selection
                    Text(
                      'SELECT CATEGORY',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.onSecondary
                                      : theme.colorScheme.outline,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: theme.colorScheme.secondary,
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : theme.colorScheme.outline,
                              ),
                              shape: const StadiumBorder(),
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
                    const SizedBox(height: 24),

                    // Title Input
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note Title...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Editor Canvas Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(minHeight: 280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Rich Text Format Toolbar
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.format_bold_outlined, size: 20),
                                onPressed: () {},
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_italic_outlined, size: 20),
                                onPressed: () {},
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_list_bulleted_outlined, size: 20),
                                onPressed: () {},
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_quote_outlined, size: 20),
                                onPressed: () {},
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              Container(
                                height: 16,
                                width: 1,
                                color: theme.colorScheme.outlineVariant,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              IconButton(
                                icon: const Icon(Icons.functions_outlined, size: 20),
                                onPressed: () {},
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          // Editor Text Area
                          TextField(
                            controller: _contentController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Start documenting your research findings...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.outline.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions Grid
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.attach_file, size: 18, color: theme.colorScheme.secondary),
                            label: const Text('ATTACH FILE', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.outlineVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.label_outline, size: 18, color: theme.colorScheme.secondary),
                            label: const Text('TAG PROJECT', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.outlineVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // AI Assistant Card
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: theme.colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI ASSISTANT',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Mention '@research' to automatically cite relevant papers from your library.",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom Action Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving || _isSaved ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Saving...'),
                          ],
                        )
                      : _isSaved
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 20, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Saved'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 8),
                                Text('Save Note'),
                              ],
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
