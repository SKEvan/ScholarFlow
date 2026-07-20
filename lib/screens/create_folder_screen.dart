import 'package:flutter/material.dart';
import '../theme.dart';

class CreateFolderScreen extends StatefulWidget {
  const CreateFolderScreen({super.key});

  @override
  State<CreateFolderScreen> createState() => _CreateFolderScreenState();
}

class _CreateFolderScreenState extends State<CreateFolderScreen> {
  final TextEditingController _nameController = TextEditingController();
  
  Color _selectedColor = AppTheme.actionBlue; // Default blue
  IconData _selectedIcon = Icons.folder;
  bool _isCreating = false;

  final List<Color> _colors = [
    AppTheme.actionBlue, // Blue
    AppTheme.folderGold, // Gold/Brown
    AppTheme.folderRed, // Red
    Colors.black, // Black
  ];

  final List<Map<String, dynamic>> _icons = [
    {'icon': Icons.folder, 'name': 'folder'},
    {'icon': Icons.menu_book, 'name': 'book'},
    {'icon': Icons.science, 'name': 'science'},
    {'icon': Icons.school, 'name': 'school'},
    {'icon': Icons.storage, 'name': 'database'},
    {'icon': Icons.auto_awesome, 'name': 'ai'},
  ];

  final List<Map<String, dynamic>> _existingFolders = [
    {
      'title': 'Machine Learning Basics',
      'papers': '12 Papers',
      'updated': 'Updated 2d ago',
      'color': AppTheme.folderGold,
    },
    {
      'title': 'Climate Change Ethics',
      'papers': '5 Papers',
      'updated': 'Updated 5h ago',
      'color': AppTheme.actionBlue,
    },
    {
      'title': 'Thesis References',
      'papers': '28 Papers',
      'updated': 'Updated 1w ago',
      'color': AppTheme.folderRed,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCreateFolder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a folder name.')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    // Simulate creation loader delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isCreating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder "${_nameController.text}" created successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'New Folder',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Folder Name Input
                        Text(
                          'FOLDER NAME',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Quantum Computing Research',
                            hintStyle: TextStyle(color: theme.colorScheme.outline.withOpacity(0.5)),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Custom Aesthetic Picker Container
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Theme color
                              Text(
                                'THEME COLOR',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ..._colors.map((color) {
                                    final isSelected = _selectedColor == color;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedColor = color;
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(color: Colors.white, width: 2)
                                              : null,
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: color.withOpacity(0.4),
                                                    blurRadius: 6,
                                                    spreadRadius: 2,
                                                  )
                                                ]
                                              : null,
                                        ),
                                      ),
                                    );
                                  }),
                                  // Custom add color button
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHigh,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: theme.colorScheme.outlineVariant),
                                    ),
                                    child: const Icon(Icons.add, size: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Icon symbol
                              Text(
                                'ICON SYMBOL',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: _icons.length,
                                itemBuilder: (context, index) {
                                  final iconData = _icons[index]['icon'] as IconData;
                                  final isSelected = _selectedIcon == iconData;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedIcon = iconData;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.surfaceContainerHighest
                                            : Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: isSelected
                                            ? Border.all(color: theme.colorScheme.secondary.withOpacity(0.3), width: 2)
                                            : null,
                                      ),
                                      child: Icon(
                                        iconData,
                                        color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.outline,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Existing libraries
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EXISTING LIBRARIES',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.outline,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '4 TOTAL',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: _existingFolders.map((folder) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: (folder['color'] as Color).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.folder,
                                      color: folder['color'] as Color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          folder['title']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${folder['papers']} • ${folder['updated']}',
                                          style: TextStyle(
                                            color: theme.colorScheme.outline,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: theme.colorScheme.outline.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // AI Suggestion Box
                        InkWell(
                          onTap: () {
                            setState(() {
                              _nameController.text = 'Bioinformatics Advanced Concepts';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Suggestion autofilled!')),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.secondary.withOpacity(0.1),
                              ),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb, color: theme.colorScheme.secondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI SUGGESTION',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Based on your recent activity, we suggest naming this folder "Bioinformatics Advanced Concepts". Tap to fill.',
                                        style: TextStyle(fontSize: 12, height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Footer Area
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _onCreateFolder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: const Icon(Icons.add_circle, size: 20),
                        label: const Text(
                          'Create Folder',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Folders organize your papers for rapid retrieval.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isCreating)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Creating library folder...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
