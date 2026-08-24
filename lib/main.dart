import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'services/user_session.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/new_note_screen.dart';
import 'screens/invitations_inbox_screen.dart';
import 'screens/upload_paper_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/project_details_screen.dart';
import 'screens/create_folder_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/summarizer_review_screen.dart';
import 'screens/comparison_gap_screen.dart';
import 'screens/literature_review_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/comparison_screen.dart';
import 'screens/research_gap_screen.dart';
import 'screens/agent_literature_review_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/note_editor_screen.dart';
import 'app_route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await UserSession.load();
  runApp(const ScholarFlowApp());
}

class ScholarFlowApp extends StatelessWidget {
  const ScholarFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'ScholarFlow',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [dashboardRouteObserver],
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/landing': (context) => const LandingScreen(),
            '/signin': (context) => const SignInScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/notes': (context) => const NotesScreen(),
            '/note-editor': (context) => const NoteEditorScreen(),
            '/new-note': (context) => const NewNoteScreen(),
            '/add-collaborator': (context) => const _AddCollaboratorRouter(),
            '/invitations-inbox': (context) => const InvitationsInboxScreen(),
            '/upload-paper': (context) => const UploadPaperScreen(),
            '/search-results': (context) => const SearchResultsScreen(),
            '/projects': (context) => const ProjectsScreen(),
            '/project-details': (context) => const ProjectDetailsScreen(),
            '/create-folder': (context) => const CreateFolderScreen(),
            '/insights': (context) => const InsightsScreen(),
            '/summarizer-review': (context) => const SummarizerReviewScreen(),
            '/comparison-gap': (context) => const ComparisonGapScreen(),
            '/literature-review': (context) => const LiteratureReviewScreen(),
            '/complete-profile': (context) => const CompleteProfileScreen(),
            '/agent/summary': (context) => const SummaryScreen(),
            '/agent/comparison': (context) => const ComparisonScreen(),
            '/agent/research-gap': (context) => const ResearchGapScreen(),
            '/agent/literature-review': (context) =>
                AgentLiteratureReviewScreen(),
          },
        );
      },
    );
  }
}

/// Placeholder shown when legacy code paths navigate to
/// `/add-collaborator` without a project context. Open a project first
/// to invite collaborators — the real form lives in
/// `ProjectMembersScreen`.
class _AddCollaboratorRouter extends StatelessWidget {
  const _AddCollaboratorRouter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite collaborator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Open a project first, then use the Members tab to invite '
            'collaborators.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
