import 'package:flutter/material.dart';
import 'agent_screen.dart';

/// Route: /agent/literature-review (project-scoped, distinct from the standalone LiteratureReviewScreen)
/// Args : { 'projectId': String, 'projectTitle': String, 'papers': List }
class AgentLiteratureReviewScreen extends StatelessWidget {
  AgentLiteratureReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgentScreen(
      toolConfig: {
        'icon'    : Icons.menu_book,
        'title'   : 'Literature Review',
        'endpoint': '/agents/literature-review',
        'choices' : ['Narrative Review', 'Theme Based Review', 'Critical Review'],
      },
    );
  }
}
