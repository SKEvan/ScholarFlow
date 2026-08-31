import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/backend_api.dart';
import '../services/user_session.dart';
import '../widgets/rich_text_editor.dart';

/// Full-screen draft editor for one project section (Abstract, Introduction,
/// Literature Review, Methodology). Reached by pushing '/project-section-editor'
/// with arguments: projectId, projectTitle, sectionKey, sectionLabel,
/// isOwner, approvedContent.
///
/// The owner's save applies directly to the live approved content. A
/// non-owner's save is submitted as a pending edit request instead — it
/// never overwrites the approved content until the owner approves it.
class ProjectSectionEditorScreen extends StatefulWidget {
  const ProjectSectionEditorScreen({super.key});

  @override
  State<ProjectSectionEditorScreen> createState() =>
      _ProjectSectionEditorScreenState();
}

class _ProjectSectionEditorScreenState
    extends State<ProjectSectionEditorScreen> {
  String? _projectId;
  String _projectTitle = 'Project';
  String _sectionKey = 'abstract';
  String _sectionLabel = 'Abstract';
  String _approvedContent = '';
  bool _isOwner = false;
  bool _argsRead = false;
  bool _isSaving = false;

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
      _approvedContent = args['approvedContent']?.toString() ?? '';
      _isOwner = args['isOwner'] == true;
    }
    _argsRead = true;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        content: Text(message),
      ),
    );
  }

  void _handleSave(String title, String content) {
    if (_isSaving) return;
    final projectId = _projectId;
    final userId = UserSession.userId;
    if (projectId == null || userId == null || userId.isEmpty) {
      _showSnack('You need to be signed in to do that.');
      return;
    }
    if (_isOwner) {
      _applyDirectly(projectId, userId, content);
    } else {
      _submitEditRequest(projectId, userId, content);
    }
  }

  Future<void> _applyDirectly(
    String projectId,
    String userId,
    String content,
  ) async {
    setState(() => _isSaving = true);
    try {
      await BackendApi.updateSectionContent(
        projectId: projectId,
        sectionKey: _sectionKey,
        content: content,
        actorUserId: userId,
      );
      if (!mounted) return;
      setState(() => _approvedContent = content);
      _showSnack('$_sectionLabel saved.');
    } catch (error) {
      _showSnack('Could not save: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitEditRequest(
    String projectId,
    String userId,
    String content,
  ) async {
    setState(() => _isSaving = true);
    try {
      await BackendApi.createSectionEditRequest(
        projectId: projectId,
        sectionKey: _sectionKey,
        content: content,
        authorUserId: userId,
      );
      _showSnack('Sent to the section owner for approval.');
    } catch (error) {
      _showSnack('Could not send approval request: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _isOwner
                  ? _projectTitle
                  : '$_projectTitle · edits need owner approval',
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
                initialContent: _approvedContent,
                onSave: _handleSave,
                saveLabel: _isOwner ? 'Save now' : 'Send Approval Request',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
