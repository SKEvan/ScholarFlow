import 'package:flutter/material.dart';
import 'agent_screen.dart';

/// Route: /agent/research-gap
/// Args : { 'projectId': String, 'projectTitle': String, 'papers': List }
class ResearchGapScreen extends StatelessWidget {
  const ResearchGapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgentScreen(
      toolConfig: {
        'icon'    : Icons.search,
        'title'   : 'Research Gap',
        'endpoint': '/agents/research-gap',
        'choices' : ['Research Gaps', 'Future Research Opportunities', 'Strengths and Limitations'],
      },
    );
  }
}
