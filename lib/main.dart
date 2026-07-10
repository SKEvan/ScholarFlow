import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/new_note_screen.dart';
import 'screens/add_collaborator_screen.dart';
import 'screens/network_screen.dart';
import 'screens/upload_paper_screen.dart';
import 'screens/ai_tools_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/project_details_screen.dart';
import 'screens/create_folder_screen.dart';
import 'screens/insights_screen.dart';

void main() {
  runApp(const ScholarFlowApp());
}

class ScholarFlowApp extends StatelessWidget {
  const ScholarFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScholarFlow',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/landing': (context) => const LandingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/new-note': (context) => const NewNoteScreen(),
        '/add-collaborator': (context) => const AddCollaboratorScreen(),
        '/network': (context) => const NetworkScreen(),
        '/upload-paper': (context) => const UploadPaperScreen(),
        '/ai-tools': (context) => const AIToolsScreen(),
        '/search-results': (context) => const SearchResultsScreen(),
        '/projects': (context) => const ProjectsScreen(),
        '/project-details': (context) => const ProjectDetailsScreen(),
        '/create-folder': (context) => const CreateFolderScreen(),
        '/insights': (context) => const InsightsScreen(),
      },
    );
  }
}
