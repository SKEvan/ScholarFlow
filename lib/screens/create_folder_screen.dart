import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../services/user_session.dart';

class CreateFolderScreen extends StatefulWidget {
  const CreateFolderScreen({super.key});

  @override
  State<CreateFolderScreen> createState() => _CreateFolderScreenState();
}

class _CreateFolderScreenState extends State<CreateFolderScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _collaboratorController = TextEditingController();

  final List<String> _statuses = ['active', 'planned', 'completed'];
  final List<String> _collaborators = [];

  bool _isCreating = false;
  String _creatingStageText = 'Creating Project...';
  String _selectedStatus = 'active';
  DateTime? _startDate;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _collaboratorController.dispose();
    super.dispose();
  }

  String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return date.toIso8601String().split('T').first;
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _startDate ?? DateTime.now() : _deadline ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      if (isStartDate) {
        _startDate = selected;
      } else {
        _deadline = selected;
      }
    });
  }

  void _addCollaborator() {
    final collaborator = _collaboratorController.text.trim();
    if (collaborator.isEmpty) {
      return;
    }

    setState(() {
      _collaborators.add(collaborator);
      _collaboratorController.clear();
    });
  }

  Future<void> _showAddCollaboratorDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Collaborator'),
          content: TextField(
            controller: _collaboratorController,
            decoration: const InputDecoration(
              labelText: 'Collaborator name or email',
            ),
            onSubmitted: (_) {
              _addCollaborator();
              Navigator.of(dialogContext).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addCollaborator();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createProject() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project title.')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _creatingStageText = 'Creating Project...';
    });

    try {
      // The backend now creates the project + schedules the search asynchronously,
      // so this call returns as soon as the row is inserted. We can navigate to
      // the project details screen immediately and let the project details view
      // poll for papers as they arrive.
      final result = await BackendApi.createProjectAndResearch(
        title,
        ownerId: UserSession.userId,
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        startDate: _formatDate(_startDate),
        deadline: _formatDate(_deadline),
        collaborators: _collaborators,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
      });

      final project = result['project'];
      Navigator.of(context).pushReplacementNamed(
        '/project-details',
        arguments: {
          'projectId': project is Map ? project['id'] : null,
          'projectTitle': project is Map ? project['title'] : title,
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create project: $error')),
      );
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
          'New Project',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PROJECT TITLE',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Quantum Computing Research',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DESCRIPTION',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Short description of the project',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PROJECT STATUS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    items: _statuses
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status[0].toUpperCase() + status.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('START DATE'),
                          subtitle: Text(_formatDate(_startDate) ?? 'Pick a start date'),
                          trailing: const Icon(Icons.date_range),
                          onTap: () => _pickDate(isStartDate: true),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('DEADLINE'),
                          subtitle: Text(_formatDate(_deadline) ?? 'Pick a deadline'),
                          trailing: const Icon(Icons.date_range),
                          onTap: () => _pickDate(isStartDate: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COLLABORATORS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddCollaboratorDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add collaborator'),
                      ),
                    ],
                  ),
                  if (_collaborators.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: const Text('No collaborators added yet.'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _collaborators
                          .map(
                            (collaborator) => Chip(
                              label: Text(collaborator),
                              onDeleted: () {
                                setState(() {
                                  _collaborators.remove(collaborator);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.add_circle, size: 20),
                    label: const Text(
                      'Create Project',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The project will be saved in Supabase and added to your project list.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isCreating)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _creatingStageText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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