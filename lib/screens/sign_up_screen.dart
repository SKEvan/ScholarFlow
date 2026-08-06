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
  final _emailController = TextEditingController();
  final _universityController = TextEditingController();
  final _researchInterestController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _selectedRole;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _researchInterestController.dispose();
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
        university: _universityController.text.trim(),
        role: _selectedRole ?? '',
        researchInterest: _researchInterestController.text.trim(),
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
          content: Text('Account created. Please check your email before signing in.'),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/signin');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $error')),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Brand Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
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
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Headers
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Empower your academic journey with AI.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Up Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name
                      _buildLabel(theme, 'FULL NAME'),
                      TextFormField(
                        controller: _fullNameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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

                      // Email Address
                      _buildLabel(theme, 'EMAIL ADDRESS'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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

                      // Academic Institution
                      _buildLabel(theme, 'ACADEMIC INSTITUTION'),
                      TextFormField(
                        controller: _universityController,
                        decoration: const InputDecoration(
                          hintText: 'University or Organization',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Professional Role
                      _buildLabel(theme, 'PROFESSIONAL ROLE'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        hint: Text(
                          'Select your role',
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.outline.withOpacity(0.6),
                            fontSize: 15,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'student', child: Text('Student')),
                          DropdownMenuItem(value: 'researcher', child: Text('Researcher')),
                          DropdownMenuItem(value: 'professor', child: Text('Professor')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedRole = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Research Interest
                      _buildLabel(theme, 'PRIMARY RESEARCH INTEREST'),
                      TextFormField(
                        controller: _researchInterestController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Quantum Computing',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
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
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 20),

                // Social Sign Up
                Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google sign-up is not configured yet.')),
                        );
                      },
                      icon: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCPrz5JGj39MXh5qItGlUhCvHavI1qW21OZZ-wu9VNkgIznykj3X4nQWpXfs-xfw4HE8EfbetArRYuvulVQ7gZI2IFDvf_-gOUDkAPRO2ump0ezrehM8TQaFaHfK2Xg1RVhfl0hH6fi7WIZMCMVjBmgGfTBcUnZC5YduWmfViwzeaMC728QwiDZ_Cd-esiwpoh_2LaHJxMMzslUk_tkgM1nSqclJNNDSgf7rCoODrFam5JWIZc6DnjmnYsFZP3-yScdS5_j6Pb6lHs',
                        height: 20,
                        width: 20,
                        errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata),
                      ),
                      label: Text(
                        'Sign up with Google',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('LinkedIn sign-up is not configured yet.')),
                        );
                      },
                      icon: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCaTQzSL1X0tjmxiCLtDDsE-d_POAv6JOsvjzNT4UOsUuZJ4czz88XhEmdcEihQuf0MlHQtHpQMjASewRE3e-ipyYPO5qkgbB8s7whjuckA1GXKKkIGA04D7v62rIGdCZ-tGHRT58ABgDB_T2MFvbv_sHF4pvITnGWOO8B9Pg-upJu87I7mh7kW1Ay9NBLYIAQhlZ4dBzIGRGFS7nLXvnDijn657PfW0Gw029aAHRbNXls7FGlCCuEEiS-pbC8mCFEozjEN8YvxMsA',
                        height: 20,
                        width: 20,
                        errorBuilder: (c, e, s) => const Icon(Icons.link),
                      ),
                      label: Text(
                        'Sign up with LinkedIn',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 36),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/signin');
                      },
                      child: Text(
                        'Sign In',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Terms & Help
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('Help', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.outline.withOpacity(0.7),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Terms', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.outline.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
