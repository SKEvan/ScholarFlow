import 'package:flutter/material.dart';
import 'agent_screen.dart';

/// Route: /agent/comparison
/// Args : { 'projectId': String, 'projectTitle': String, 'papers': List }
class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgentScreen(
      toolConfig: {
        'icon'    : Icons.compare_arrows,
        'title'   : 'Comparison Gap',
        'endpoint': '/agents/comparison',
        'choices' : ['Overall Comparison', 'Similarity and Difference', 'Strength and Limitation'],
      },
    );
  }
}
