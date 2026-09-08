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
/// If the current user is the section owner:
///   - Single-pane editor directly updating approved content.
/// If the user is NOT the section owner:
///   - Split-view editor:
///     - Upper pane: Read-only view of the approved main content with
///       "Copy to Editor ↓" button.
///     - Lower pane: Editable RichTextEditor saving to a new database version
///       without overwriting the original.
class ProjectSectionEditorScreen extends StatefulWidget {
  const ProjectSectionEditorScreen({super.key});

  @override
  State<ProjectSectionEditorScreen> createState() =>
      _ProjectSectionEditorScreenState();
}

class _ProjectSectionEditorScreenState
    extends State<ProjectSectionEditorScreen> {
  final GlobalKey<RichTextEditorState> _editorKey =
      GlobalKey<RichTextEditorState>();

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

  void _showSnack(String message, {String? actionLabel, VoidCallback? onAction}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        content: Text(message),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }

  void _openVersions() {
    if (_projectId == null) return;
    Navigator.of(context).pushNamed(
      '/project-section-versions',
      arguments: {
        'projectId': _projectId,
        'projectTitle': _projectTitle,
        'sectionKey': _sectionKey,
        'sectionLabel': _sectionLabel,
        'isOwner': _isOwner,
        'approvedContent': _approvedContent,
      },
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
      _saveNewVersion(projectId, userId, content);
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

  Future<void> _saveNewVersion(
    String projectId,
    String userId,
    String content,
  ) async {
    if (content.trim().isEmpty) {
      _showSnack('Cannot save an empty version.');
      return;
    }

    final message = await _promptVersionMessage();
    if (message == null) return; // User cancelled

    setState(() => _isSaving = true);
    try {
      await BackendApi.createSectionVersion(
        projectId: projectId,
        sectionKey: _sectionKey,
        content: content,
        editedBy: userId,
        message: message,
      );
      if (!mounted) return;
      _showSnack(
        'New version saved. The original copy was not overwritten.',
        actionLabel: 'View Versions',
        onAction: _openVersions,
      );
    } catch (error) {
      _showSnack('Could not save version: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _promptVersionMessage() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.bookmark_add_outlined,
                color: const Color(0xFF2563EB), size: 22.sp),
            SizedBox(width: 8.w),
            Text(
              'Save New Version',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add an optional note describing your edits:',
              style:
                  TextStyle(fontSize: 13.sp, color: const Color(0xFF64748B)),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g., Refined methodology section',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Save Version'),
          ),
        ],
      ),
    );
  }

  void _copyToEditor() {
    _editorKey.currentState?.setContent(_approvedContent);
    _showSnack('Approved content copied into your editor below.');
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
                  ? '$_projectTitle · section owner'
                  : '$_projectTitle · split view editor',
              style: GoogleFonts.fredoka(
                fontSize: 11.sp,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Version History',
            onPressed: _openVersions,
          ),
        ],
      ),
      body: _isOwner ? _buildOwnerView() : _buildSplitView(),
    );
  }

  /// Owner view: standard single-pane rich text editor directly updating approved content
  Widget _buildOwnerView() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 24.h),
          sliver: SliverToBoxAdapter(
            child: RichTextEditor(
              key: ValueKey('$_projectId::$_sectionKey'),
              initialTitle: _sectionLabel,
              initialContent: _approvedContent,
              onSave: _handleSave,
              saveLabel: _isSaving ? 'Saving...' : 'Save now',
            ),
          ),
        ),
      ],
    );
  }

  /// Non-owner view: split view with approved content on top and editor below
  Widget _buildSplitView() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 24.h),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Upper Pane: Read-only approved content ───────────
                _buildApprovedContentPane(),
                SizedBox(height: 16.h),

                // ── Pane separator banner ─────────────────────────────
                _buildSplitDivider(),
                SizedBox(height: 16.h),

                // ── Lower Pane: Working Draft Editor ──────────────────
                RichTextEditor(
                  key: _editorKey,
                  initialTitle: '$_sectionLabel (Draft)',
                  initialContent: '',
                  onSave: _handleSave,
                  saveLabel:
                      _isSaving ? 'Saving Version...' : 'Save as New Version',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedContentPane() {
    final hasContent = _approvedContent.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13.r)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 16.sp,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Main Approved Content',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'Original',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Read-only · will not be overwritten by your edits',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                FilledButton.tonalIcon(
                  onPressed: hasContent ? _copyToEditor : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB)
                        .withValues(alpha: 0.12),
                    foregroundColor: const Color(0xFF2563EB),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.arrow_downward_rounded, size: 15.sp),
                  label: Text(
                    'Copy to Editor',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Content Box
          Container(
            constraints: BoxConstraints(minHeight: 100.h, maxHeight: 220.h),
            padding: EdgeInsets.all(14.r),
            child: SingleChildScrollView(
              child: hasContent
                  ? SelectableText(
                      _approvedContent,
                      style: GoogleFonts.fredoka(
                        fontSize: 14.sp,
                        height: 1.5,
                        color: const Color(0xFF334155),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notes_rounded,
                                size: 28.sp, color: const Color(0xFF94A3B8)),
                            SizedBox(height: 6.h),
                            Text(
                              'No approved content written yet.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFCBD5E1), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 15.sp,
                  color: const Color(0xFF2563EB),
                ),
                SizedBox(width: 6.w),
                Text(
                  'Your Editable Version Below',
                  style: GoogleFonts.fredoka(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFCBD5E1), thickness: 1)),
      ],
    );
  }
}
