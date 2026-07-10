import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _selectedRole;

  void _submitForm() {
    // Navigate straight to dashboard for preview/prototype purposes
    Navigator.of(context).pushReplacementNamed('/dashboard');
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
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Address
                      _buildLabel(theme, 'EMAIL ADDRESS'),
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'name@university.edu',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Academic Institution
                      _buildLabel(theme, 'ACADEMIC INSTITUTION'),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'University or Organization',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Professional Role
                      _buildLabel(theme, 'PROFESSIONAL ROLE'),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
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
                        decoration: const InputDecoration(
                          hintText: 'e.g. Quantum Computing',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _buildLabel(theme, 'PASSWORD'),
                      TextFormField(
                        obscureText: _obscurePassword,
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
                        onPressed: _submitForm,
                        child: const Text('Sign Up'),
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
                      onPressed: _submitForm,
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
                      onPressed: _submitForm,
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
