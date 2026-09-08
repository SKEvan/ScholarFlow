import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diff_match_patch/diff_match_patch.dart'
    show Diff, DIFF_INSERT, DIFF_DELETE;

import '../services/backend_api.dart';
import '../services/user_session.dart';
import '../utils/word_diff.dart';

/// Screen displaying all saved versions of a section.
/// Allows contributors to review historical versions, see who edited what and when,
/// copy text, and request approval to merge a version into the approved copy.
/// Reached by pushing '/project-section-versions' with arguments:
/// projectId, projectTitle, sectionKey, sectionLabel, isOwner, approvedContent.
class SectionVersionsScreen extends StatefulWidget {
  const SectionVersionsScreen({super.key});

  @override
  State<SectionVersionsScreen> createState() => _SectionVersionsScreenState();
}

class _SectionVersionsScreenState extends State<SectionVersionsScreen> {
  String? _projectId;
  String _projectTitle = 'Project';
  String _sectionKey = 'abstract';
  String _sectionLabel = 'Abstract';
  String _approvedContent = '';
  bool _isOwner = false;
  bool _argsRead = false;

  bool _isLoading = false;
  List<Map<String, dynamic>> _versions = [];
  final Set<String> _requestingIds = {};
  final Set<String> _applyingIds = {};
  final Set<String> _expandedVersionIds = {};

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
    _load();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        content: Text(message),
      ),
    );
  }

  Future<void> _load() async {
    final projectId = _projectId;
    if (projectId == null) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        BackendApi.listSectionVersions(
          projectId: projectId,
          sectionKey: _sectionKey,
        ),
        BackendApi.listProjectSections(projectId),
      ]);
      final versions = results[0];
      final sections = results[1];
      final section = sections.firstWhere(
        (s) => s['section_key'] == _sectionKey,
        orElse: () => const <String, dynamic>{},
      );

      if (!mounted) return;
      setState(() {
        _versions = versions;
        _approvedContent = section['approved_content']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Could not load versions: $error');
    }
  }

  Future<void> _requestApproval(Map<String, dynamic> version) async {
    final versionId = version['id']?.toString();
    final projectId = _projectId;
    final userId = UserSession.userId;
    if (versionId == null || projectId == null || userId == null) return;

    setState(() => _requestingIds.add(versionId));
    try {
      await BackendApi.requestVersionApproval(
        projectId: projectId,
        sectionKey: _sectionKey,
        versionId: versionId,
        authorUserId: userId,
      );
      _showSnack('Approval request sent to the section owner.');
    } catch (error) {
      _showSnack('Could not request approval: $error');
    } finally {
      if (mounted) setState(() => _requestingIds.remove(versionId));
    }
  }

  Future<void> _applyAsApproved(Map<String, dynamic> version) async {
    final versionId = version['id']?.toString();
    final projectId = _projectId;
    final userId = UserSession.userId;
    final content = version['content']?.toString() ?? '';
    if (versionId == null || projectId == null || userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Apply Version to Main Copy?',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 18.sp),
        ),
        content: Text(
          'This will replace the section’s main approved text with this version’s content.',
          style: TextStyle(fontSize: 13.sp, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
            ),
            child: const Text('Apply Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _applyingIds.add(versionId));
    try {
      await BackendApi.updateSectionContent(
        projectId: projectId,
        sectionKey: _sectionKey,
        content: content,
        actorUserId: userId,
      );
      if (!mounted) return;
      setState(() => _approvedContent = content);
      _showSnack('Applied version as the current approved content.');
    } catch (error) {
      _showSnack('Could not apply version: $error');
    } finally {
      if (mounted) setState(() => _applyingIds.remove(versionId));
    }
  }

  void _copyContent(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Version content copied to clipboard.');
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
              '$_sectionLabel — Versions',
              style: GoogleFonts.fredoka(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$_projectTitle · ${_versions.length} version${_versions.length == 1 ? '' : 's'}',
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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _versions.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                      itemCount: _versions.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 14.h),
                      itemBuilder: (ctx, index) =>
                          _buildVersionCard(_versions[index], index),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_toggle_off_rounded,
                      size: 44.sp,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'No saved versions yet',
                    style: GoogleFonts.fredoka(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'When collaborators edit this section in the split-view editor,\n'
                    'their changes are saved here as timestamped versions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCard(Map<String, dynamic> version, int index) {
    final versionId = version['id']?.toString() ?? '';
    final editor = version['editor'] as Map<String, dynamic>?;
    final editorName = editor?['full_name']?.toString().trim();
    final createdAt = version['created_at']?.toString();
    final message = version['message']?.toString().trim();
    final content = version['content']?.toString() ?? '';
    final isRequesting = _requestingIds.contains(versionId);
    final isApplying = _applyingIds.contains(versionId);
    final isExpanded = _expandedVersionIds.contains(versionId);
    final diffs = wordDiff(_approvedContent, content);

    final isIdenticalToApproved = content.trim() == _approvedContent.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: index == 0
              ? const Color(0xFF2563EB).withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  child: Text(
                    (editorName != null && editorName.isNotEmpty)
                        ? editorName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.fredoka(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
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
                              (editorName == null || editorName.isEmpty)
                                  ? 'Collaborator'
                                  : editorName,
                              style: GoogleFonts.fredoka(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (index == 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Latest',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                          if (isIdenticalToApproved) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Current Approved',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12.sp, color: const Color(0xFF94A3B8)),
                          SizedBox(width: 4.w),
                          Text(
                            createdAt != null
                                ? _formatTimestamp(createdAt)
                                : 'Unknown date',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 17.sp,
                    color: const Color(0xFF64748B),
                  ),
                  tooltip: 'Copy text',
                  onPressed: () => _copyContent(content),
                ),
              ],
            ),
          ),

          // Message if available
          if (message != null && message.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 13.sp, color: const Color(0xFF64748B)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Diff Preview / Content Container
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Changes vs Approved',
                        style: GoogleFonts.fredoka(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedVersionIds.remove(versionId);
                            } else {
                              _expandedVersionIds.add(versionId);
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              isExpanded ? 'Show less' : 'Show full',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16.sp,
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: isExpanded ? double.infinity : 90.h,
                    ),
                    child: SingleChildScrollView(
                      physics: isExpanded
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      child: _buildDiffText(diffs),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions Footer
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
            child: Row(
              children: [
                // Non-owner: Request Approval button
                if (!_isOwner) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isRequesting
                          ? null
                          : () => _requestApproval(version),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      icon: isRequesting
                          ? SizedBox(
                              width: 14.r,
                              height: 14.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.send_rounded, size: 15.sp),
                      label: Text(
                        isRequesting ? 'Sending...' : 'Request Approval',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                // Owner: Apply this version directly
                if (_isOwner) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isApplying || isIdenticalToApproved
                          ? null
                          : () => _applyAsApproved(version),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      icon: isApplying
                          ? SizedBox(
                              width: 14.r,
                              height: 14.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.check_circle_outline_rounded,
                              size: 15.sp),
                      label: Text(
                        isIdenticalToApproved
                            ? 'Already Main Copy'
                            : (isApplying ? 'Applying...' : 'Apply to Main Copy'),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffText(List<Diff> diffs) {
    if (diffs.isEmpty) {
      return Text(
        'Empty text.',
        style: TextStyle(
          color: const Color(0xFF94A3B8),
          fontSize: 12.sp,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: diffs.map((d) {
          switch (d.operation) {
            case DIFF_INSERT:
              return TextSpan(
                text: d.text,
                style: TextStyle(
                  backgroundColor: const Color(0xFFDCFCE7),
                  color: const Color(0xFF166534),
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              );
            case DIFF_DELETE:
              return TextSpan(
                text: d.text,
                style: TextStyle(
                  backgroundColor: const Color(0xFFFEE2E2),
                  color: const Color(0xFF991B1B),
                  decoration: TextDecoration.lineThrough,
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              );
            default:
              return TextSpan(
                text: d.text,
                style: TextStyle(
                  color: const Color(0xFF334155),
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              );
          }
        }).toList(),
      ),
    );
  }

  String _formatTimestamp(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
