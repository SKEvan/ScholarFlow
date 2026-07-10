import 'package:flutter/material.dart';

class AddCollaboratorScreen extends StatefulWidget {
  const AddCollaboratorScreen({super.key});

  @override
  State<AddCollaboratorScreen> createState() => _AddCollaboratorScreenState();
}

class _AddCollaboratorScreenState extends State<AddCollaboratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _permissionLevel = 'editor';
  bool _isProcessing = false;
  bool _isSent = false;

  final List<Map<String, String>> _recentCollaborators = [
    {
      'name': 'Dr. Aris',
      'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuC7shefmkSeKzrjdVdVTQ5DaLtca3cEjXKaQgVTx1m6H7iJhnSRFN_-tz3cfGMN3AZn_Sgf-s1lRFG_YypEAz7i-RF0DiemIqsLSpkDq76o3haf3cYltP0cKrat_RTySQb3y0hCEORq9s0Ae4-fsF6SODn-pINtjsBxZp-SU2YL6Y2XeKB6eZ0bispyblN9Yb9E1MhgjjHw9pN_VrMsqJKZZrZd1esc658MpmCvLiET6r94j0wW7mUbkNqPW79SDIQw0TUhihfMgk8',
    },
    {
      'name': 'Prof. Miller',
      'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDZ7PlM8MwNr8HArysnj5L0m3w5yD6JCDFu0nTrUZs0P40hIpssKZbQmRP5CJvp2lraHlFmNTSPGaW6_ZldmJhSz3fejb1ALzMw6AHU5LfhheMBe-kHbIs5tWw8ZOFTHhxXfRBYFA0YjpkSmskynl4Im2IOgjPgFVshLGYljrGH63SWHEP9Pg_TO-yBpfanvER2L5iqCo0nW9ILFnVTYi2sZR1aRcndPGAdDEyxNBZo7bSNWNMyV5IMr2AGjdhr_FxqkpsFGDz_PJ8',
    },
    {
      'name': 'S. Zhang',
      'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAsxjZBK9b0zyYwmNk4LNzFtRfeE08FTPfuFD3Ktcw2IoRK3RrGh42tkcxv-xYLz_9k7ww0w85SNYuAhsB51gjpObTC9T3iixoiJLIgsj6ZSBp2nHNA2-7puKm1-t1bKwXG4F1NVk-uGoqUryPptYXs8GP-wbpF5Tx3ewzcpPEmn1gUYEKcByQhCkayydu4I6r66nesy0vMzUCpUMXYA6pYPTYlP7TNNx71j_phI_uXkykhN7Dl24Lubq6wnXPVWAxgu1ZfhFfzyr4',
    },
    {
      'name': 'L. Gomez',
      'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAkn_Uzh8YaPdbAGh_zoJLhaAeXM4JWGn4cVS-s0ErNguHHU_9OpjNR_gbyCLI0ft0XDerO6uOpKxnKu8AVEsm1p2UnbpO64HjvDlGzzywocZqSV0cTPP-Cb1L3hapWodpGkbT7g0NiGrCNuwk2h_Tbx2g91PMNm_aMFghMp5RJLJHacIkaP35GmjSvixqfVXRtaWnQZYp7Q8h6y7TnVibcMudfyQirmYy4xJPRLwFgkkKVpnLHRcdgTlb48fQIBkt106oyNnZ82fA',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendInvitation() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      // Simulate sending invitation
      Future.delayed(const Duration(seconds: 1500 ~/ 1000), () {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _isSent = true;
        });

        // Show success animation and then pop screen
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.of(context).pop();
        });
      });
    }
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
          'Add Collaborator',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
            onPressed: () {
              // Search action
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Illustration / Header container
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_add_outlined,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DIGITAL SCHOLASTICISM',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Expand your research circle',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email input
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'colleague@university.edu',
                          suffixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter colleague email address';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Permission Select
                      Text(
                        'PERMISSION LEVEL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _permissionLevel,
                        decoration: const InputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Text('Viewer (Read Only)'),
                          ),
                          DropdownMenuItem(
                            value: 'editor',
                            child: Text('Editor (Can edit papers)'),
                          ),
                          DropdownMenuItem(
                            value: 'lead',
                            child: Text('Lead (Admin Access)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _permissionLevel = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 28),

                      // Recent Collaborators Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECENT COLLABORATORS',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'VIEW ALL',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Row of User Avatars
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recentCollaborators.length,
                          itemBuilder: (context, index) {
                            final collab = _recentCollaborators[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 20.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                                    backgroundImage: NetworkImage(collab['url']!),
                                    child: ClipOval(
                                      child: Image.network(
                                        collab['url']!,
                                        fit: BoxFit.cover,
                                        width: 52,
                                        height: 52,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            color: theme.colorScheme.primary,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    collab['name']!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // AI Insight Card
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
                              Icons.lightbulb_outline,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI INSIGHT',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Collaborators with 'Editor' access can annotate papers and trigger shared citations in real-time.",
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
            ),
            // Invite Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing || _isSent ? null : _sendInvitation,
                  child: _isProcessing
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
                            Text('Processing...'),
                          ],
                        )
                      : _isSent
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 20, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Invite Sent'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Send Invitation'),
                                SizedBox(width: 8),
                                Icon(Icons.send, size: 18),
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
