import 'package:flutter/material.dart';

void showAddToProjectSheet(BuildContext context) {
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Add to Project',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              // Options List
              _buildOption(
                context,
                icon: Icons.upload_file,
                title: 'Upload Paper',
                route: '/upload-paper',
              ),
              const SizedBox(height: 8),
              _buildOption(
                context,
                icon: Icons.person_add,
                title: 'Add Collaborator',
                route: '/add-collaborator',
              ),
              const SizedBox(height: 8),
              _buildOption(
                context,
                icon: Icons.note_add,
                title: 'New Activity Note',
                route: '/new-note',
              ),
              const SizedBox(height: 8),
              _buildOption(
                context,
                icon: Icons.create_new_folder,
                title: 'Create Folder',
                route: '/create-folder',
              ),
              const SizedBox(height: 16),

              const Divider(),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCEL',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildOption(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String route,
}) {
  final theme = Theme.of(context);

  return InkWell(
    onTap: () {
      Navigator.of(context).pop(); // Dismiss bottom sheet first
      Navigator.of(context).pushNamed(route);
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ],
      ),
    ),
  );
}
