import 'package:flutter/material.dart';
import 'agent_screen.dart';

/// Route: /agent/summary
/// Args : { 'projectId': String, 'projectTitle': String, 'papers': List }
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgentScreen(
      toolConfig: {
        'icon'    : Icons.summarize,
        'title'   : 'Generate Summary',
        'endpoint': '/agents/summary',
        'choices' : ['General Summary', 'Key Insights', 'Critical Analysis'],
      },
    );
  }
}
