import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scholar_flow/services/backend_api.dart';

import 'sign_in_screen.dart';

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

  void _goToSignIn() {
    Navigator.of(context).pushReplacement(_authRoute(const SignInScreen()));
  }

  PageRouteBuilder<void> _authRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.03, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeTabColor = Color(0xFF0F3A31);

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
                    const SizedBox(height: 28),
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
                        borderRadius: BorderRadius.circular(15),
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
                            Container(
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7ECE9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: double.infinity,
                                      child: TextButton(
                                        onPressed: _goToSignIn,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              theme.colorScheme.onSurface,
                                          backgroundColor: Colors.transparent,
                                          side: BorderSide.none,
                                          padding: EdgeInsets.zero,
                                          textStyle: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Login'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: SizedBox(
                                      height: double.infinity,
                                      child: FilledButton(
                                        onPressed: null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: activeTabColor,
                                          disabledBackgroundColor:
                                              activeTabColor,
                                          disabledForegroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          textStyle: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Sign Up'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: const Color(0xFF0F3A31),
                                    ),
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
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 55,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Google sign-up is not configured yet.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Image.asset(
                                        'assets/google.png',
                                        height: 30,
                                        width: 30,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.g_mobiledata),
                                      ),
                                      label: Text(
                                        'Google',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        foregroundColor:
                                            theme.colorScheme.onSurface,
                                        side: BorderSide(
                                          color:
                                              theme.colorScheme.outlineVariant,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: 55,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'LinkedIn sign-up is not configured yet.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Image.asset(
                                        'assets/linkedin.png',
                                        height: 30,
                                        width: 30,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.link),
                                      ),
                                      label: Text(
                                        'LinkedIn',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        foregroundColor:
                                            theme.colorScheme.onSurface,
                                        side: BorderSide(
                                          color:
                                              theme.colorScheme.outlineVariant,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
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
