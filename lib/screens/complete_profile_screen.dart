import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _universityController = TextEditingController();
  String? _selectedRole;
  bool _isSubmitting = false;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final profile = args['profile'];
      if (profile is Map<String, dynamic>) {
        _fullNameController.text = profile['full_name']?.toString() ?? '';
        _avatarUrlController.text = profile['avatar_url']?.toString() ?? '';
        _universityController.text = profile['university']?.toString() ?? '';
        _selectedRole = profile['role']?.toString().isNotEmpty == true ? profile['role'].toString() : null;
        _userId = profile['id']?.toString();
      }
      _userId ??= args['userId']?.toString();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _avatarUrlController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user id. Please sign in again.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await BackendApi.completeProfile(
        userId: userId,
        fullName: _fullNameController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim(),
        university: _universityController.text.trim(),
        role: _selectedRole ?? '',
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        '/dashboard',
        arguments: {
          'profile': result['profile'] ?? const {},
          'missingFields': result['missing_fields'] ?? const [],
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fill in the missing details to finish setting up your account.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Full name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarUrlController,
                decoration: const InputDecoration(labelText: 'Avatar URL'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _universityController,
                decoration: const InputDecoration(labelText: 'University'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'University is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Profession / role'),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'researcher', child: Text('Researcher')),
                  DropdownMenuItem(value: 'professor', child: Text('Professor')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value),
                validator: (value) => value == null || value.isEmpty ? 'Role is required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveProfile,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}