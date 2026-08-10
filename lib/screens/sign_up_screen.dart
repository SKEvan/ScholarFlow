import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholar_flow/services/backend_api.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _universityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _selectedRole;

  @override
  void dispose() {
    _fullNameController.dispose();
    _avatarUrlController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await BackendApi.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim(),
        university: _universityController.text.trim(),
        role: _selectedRole ?? '',
      );
      if (!mounted) {
        return;
      }

      final session = result['session'];
      if (session is Map && session.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created. Please check your email before signing in.',
          ),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/signin');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign up failed: $error')));
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
    const activeTabColor = Color(0xFF3F4347);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3A31),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -45,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ScholarFlow',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Empower your academic journey with AI.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.84),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.45,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed('/signin');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Login'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: null,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      disabledBackgroundColor: activeTabColor,
                                      disabledForegroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Sign Up'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLabel(theme, 'FULL NAME'),
                                  TextFormField(
                                    controller: _fullNameController,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Full name is required';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your full name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel(theme, 'AVATAR URL'),
                                  TextFormField(
                                    controller: _avatarUrlController,
                                    keyboardType: TextInputType.url,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'https://example.com/avatar.png',
                                      prefixIcon: Icon(Icons.image_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel(theme, 'EMAIL ADDRESS'),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'name@university.edu',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel(theme, 'ACADEMIC INSTITUTION'),
                                  TextFormField(
                                    controller: _universityController,
                                    decoration: const InputDecoration(
                                      hintText: 'University or Organization',
                                      prefixIcon: Icon(Icons.school_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel(theme, 'PROFESSIONAL ROLE'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedRole,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.work_outline),
                                    ),
                                    hint: Text(
                                      'Select your role',
                                      style: GoogleFonts.inter(
                                        color: theme.colorScheme.outline
                                            .withOpacity(0.6),
                                        fontSize: 15,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'student',
                                        child: Text('Student'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'researcher',
                                        child: Text('Researcher'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'professor',
                                        child: Text('Professor'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'other',
                                        child: Text('Other'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedRole = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel(theme, 'PASSWORD'),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (value.length < 8) {
                                        return 'Use at least 8 characters';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Min. 8 characters',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : _submitForm,
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Sign Up'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.outlineVariant
                                        .withOpacity(0.5),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    'OR CONTINUE WITH',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.outline,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.outlineVariant
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Google sign-up is not configured yet.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Image.asset(
                                    'assets/google.png',
                                    height: 20,
                                    width: 20,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.g_mobiledata),
                                  ),
                                  label: Text(
                                    'Sign up with Google',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onSurface,
                                    side: BorderSide(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                    shape: const StadiumBorder(),
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'LinkedIn sign-up is not configured yet.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Image.asset(
                                    'assets/linkedin.png',
                                    height: 20,
                                    width: 20,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.link),
                                  ),
                                  label: Text(
                                    'Sign up with LinkedIn',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onSurface,
                                    side: BorderSide(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                    shape: const StadiumBorder(),
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.help_outline,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Help',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.outline
                                        .withOpacity(0.7),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.description_outlined,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Terms',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.outline
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
