import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

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
                // Logo & Brand Name
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
                const SizedBox(height: 32),
                
                // Welcome Texts
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your research journey',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 36),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      Text(
                        'EMAIL ADDRESS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'name@university.edu',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password field
                      Text(
                        'PASSWORD',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
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
                      const SizedBox(height: 8),
                      
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/forgot-password');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sign In Button
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Sign In'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR SIGN IN WITH',
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
                const SizedBox(height: 24),

                // Social Auth
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitForm,
                        icon: Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCPrz5JGj39MXh5qItGlUhCvHavI1qW21OZZ-wu9VNkgIznykj3X4nQWpXfs-xfw4HE8EfbetArRYuvulVQ7gZI2IFDvf_-gOUDkAPRO2ump0ezrehM8TQaFaHfK2Xg1RVhfl0hH6fi7WIZMCMVjBmgGfTBcUnZC5YduWmfViwzeaMC728QwiDZ_Cd-esiwpoh_2LaHJxMMzslUk_tkgM1nSqclJNNDSgf7rCoODrFam5JWIZc6DnjmnYsFZP3-yScdS5_j6Pb6lHs',
                          height: 20,
                          width: 20,
                          errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata),
                        ),
                        label: Text(
                          'Google',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitForm,
                        icon: Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCaTQzSL1X0tjmxiCLtDDsE-d_POAv6JOsvjzNT4UOsUuZJ4czz88XhEmdcEihQuf0MlHQtHpQMjASewRE3e-ipyYPO5qkgbB8s7whjuckA1GXKKkIGA04D7v62rIGdCZ-tGHRT58ABgDB_T2MFvbv_sHF4pvITnGWOO8B9Pg-upJu87I7mh7kW1Ay9NBLYIAQhlZ4dBzIGRGFS7nLXvnDijn657PfW0Gw029aAHRbNXls7FGlCCuEEiS-pbC8mCFEozjEN8YvxMsA',
                          height: 20,
                          width: 20,
                          errorBuilder: (c, e, s) => const Icon(Icons.link),
                        ),
                        label: Text(
                          'LinkedIn',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Switch to Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/signup');
                      },
                      child: Text(
                        'Sign Up',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 36),
                
                // Bottom Terms & Help
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.help_outline, size: 20),
                      label: const Text('Help'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.outline.withOpacity(0.7),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.description_outlined, size: 20),
                      label: const Text('Terms'),
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
}
