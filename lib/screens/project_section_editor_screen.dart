import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/project_section_store.dart';
import '../widgets/rich_text_editor.dart';

/// Full-screen draft editor for one project section (Abstract, Introduction,
/// Literature Review, Methodology). Reached by pushing '/project-section-editor'
/// with arguments: projectId, projectTitle, sectionKey, sectionLabel.
class ProjectSectionEditorScreen extends StatefulWidget {
  const ProjectSectionEditorScreen({super.key});

  @override
  State<ProjectSectionEditorScreen> createState() =>
      _ProjectSectionEditorScreenState();
}

class _ProjectSectionEditorScreenState
    extends State<ProjectSectionEditorScreen> {
  final _store = ProjectSectionStore();

  String? _projectId;
  String _projectTitle = 'Project';
  String _sectionKey = 'abstract';
  String _sectionLabel = 'Abstract';
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _projectId = args['projectId']?.toString();
      final title = args['projectTitle']?.toString();
      if (title != null && title.isNotEmpty) _projectTitle = title;
      final key = args['sectionKey']?.toString();
      if (key != null && key.isNotEmpty) _sectionKey = key;
      final label = args['sectionLabel']?.toString();
      if (label != null && label.isNotEmpty) _sectionLabel = label;
    }
    _argsRead = true;
  }

  void _handleChanged(String title, String content) {
    if (_projectId == null) return;
    _store.setContent(_projectId!, _sectionKey, content);
  }

  void _handleSave(String title, String content) {
    if (_projectId == null) return;
    _store.setContent(_projectId!, _sectionKey, content);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        content: Text('$_sectionLabel saved.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialContent =
        _projectId != null ? _store.getContent(_projectId!, _sectionKey) : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _sectionLabel,
              style: GoogleFonts.fredoka(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _projectTitle,
              style: GoogleFonts.fredoka(
                fontSize: 11.sp,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      // CustomScrollView so the editor's own internal scrolling (unbounded
      // TextField) doesn't fight the outer scroll, matching editor_test_screen.
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 24.h),
            sliver: SliverToBoxAdapter(
              child: RichTextEditor(
                key: ValueKey('$_projectId::$_sectionKey'),
                initialTitle: _sectionLabel,
                initialContent: initialContent,
                onChanged: _handleChanged,
                onSave: _handleSave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
