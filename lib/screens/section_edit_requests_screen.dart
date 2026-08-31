import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diff_match_patch/diff_match_patch.dart' show Diff, DIFF_INSERT, DIFF_DELETE;

import '../services/backend_api.dart';
import '../services/user_session.dart';
import '../utils/word_diff.dart';

/// Owner-only screen listing pending edit requests for one section, with
/// a word-level diff against the current approved content and
/// approve/reject actions. Reached by pushing
/// '/project-section-edit-requests' with arguments: projectId, sectionKey,
/// sectionLabel.
class SectionEditRequestsScreen extends StatefulWidget {
  const SectionEditRequestsScreen({super.key});

  @override
  State<SectionEditRequestsScreen> createState() =>
      _SectionEditRequestsScreenState();
}

class _SectionEditRequestsScreenState
    extends State<SectionEditRequestsScreen> {
  String? _projectId;
  String _sectionKey = 'abstract';
  String _sectionLabel = 'Section';
  bool _argsRead = false;

  bool _isLoading = false;
  String _approvedContent = '';
  List<Map<String, dynamic>> _requests = [];
  final Set<String> _resolvingIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _projectId = args['projectId']?.toString();
      final key = args['sectionKey']?.toString();
      if (key != null && key.isNotEmpty) _sectionKey = key;
      final label = args['sectionLabel']?.toString();
      if (label != null && label.isNotEmpty) _sectionLabel = label;
    }
    _argsRead = true;
    _load();
  }

  Future<void> _load() async {
    if (_projectId == null) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        BackendApi.listProjectSections(_projectId!),
        BackendApi.listSectionEditRequests(
          projectId: _projectId!,
          sectionKey: _sectionKey,
          status: 'pending',
        ),
      ]);
      final sections = results[0];
      final requests = results[1];
      final section = sections.firstWhere(
        (s) => s['section_key'] == _sectionKey,
        orElse: () => const {},
      );
      if (!mounted) return;
      setState(() {
        _approvedContent = section['approved_content']?.toString() ?? '';
        _requests = requests;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load edit requests: $error')),
      );
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    final actorUserId = UserSession.userId;
    final requestId = request['id']?.toString();
    if (actorUserId == null || requestId == null || _projectId == null) {
      return;
    }
    setState(() => _resolvingIds.add(requestId));
    try {
      await BackendApi.approveSectionEditRequest(
        projectId: _projectId!,
        sectionKey: _sectionKey,
        requestId: requestId,
        actorUserId: actorUserId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit approved and applied.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not approve: $error')),
      );
    } finally {
      if (mounted) setState(() => _resolvingIds.remove(requestId));
    }
  }

  Future<void> _reject(Map<String, dynamic> request) async {
    final actorUserId = UserSession.userId;
    final requestId = request['id']?.toString();
    if (actorUserId == null || requestId == null || _projectId == null) {
      return;
    }

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject edit request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resolvingIds.add(requestId));
    try {
      await BackendApi.rejectSectionEditRequest(
        projectId: _projectId!,
        sectionKey: _sectionKey,
        requestId: requestId,
        actorUserId: actorUserId,
        reason: reasonController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit request rejected.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reject: $error')),
      );
    } finally {
      if (mounted) setState(() => _resolvingIds.remove(requestId));
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
        title: Text(
          '$_sectionLabel — Edit Requests',
          style: GoogleFonts.fredoka(
            fontSize: 17.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _requests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.all(14.w),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildRequestCard(_requests[index]),
                      ),
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
                  Icon(
                    Icons.inbox_outlined,
                    size: 40.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'No pending edit requests',
                    style: GoogleFonts.fredoka(
                      fontSize: 15.sp,
                      color: const Color(0xFF475569),
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

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final author = request['author'] as Map<String, dynamic>?;
    final authorName = author?['full_name']?.toString().trim();
    final createdAt = request['created_at']?.toString();
    final proposedContent = request['proposed_content']?.toString() ?? '';
    final requestId = request['id']?.toString() ?? '';
    final isResolving = _resolvingIds.contains(requestId);
    final diffs = wordDiff(_approvedContent, proposedContent);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor: const Color(
                  0xFF017ECB,
                ).withValues(alpha: 0.12),
                child: Icon(
                  Icons.person_rounded,
                  size: 15.sp,
                  color: const Color(0xFF017ECB),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (authorName == null || authorName.isEmpty)
                          ? 'Unnamed member'
                          : authorName,
                      style: GoogleFonts.fredoka(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatTimestamp(createdAt),
                        style: GoogleFonts.fredoka(
                          fontSize: 11.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: _buildDiffText(diffs),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isResolving ? null : () => _reject(request),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isResolving ? null : () => _approve(request),
                  icon: isResolving
                      ? SizedBox(
                          width: 14.sp,
                          height: 14.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF017ECB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiffText(List<Diff> diffs) {
    return Text.rich(
      TextSpan(
        children: diffs.map((d) {
          switch (d.operation) {
            case DIFF_INSERT:
              return TextSpan(
                text: d.text,
                style: TextStyle(
                  backgroundColor: const Color(0xFFDCFCE7),
                  color: const Color(0xFF166534),
                  fontSize: 13.sp,
                  height: 1.6,
                ),
              );
            case DIFF_DELETE:
              return TextSpan(
                text: d.text,
                style: TextStyle(
                  backgroundColor: const Color(0xFFFEE2E2),
                  color: const Color(0xFF991B1B),
                  decoration: TextDecoration.lineThrough,
                  fontSize: 13.sp,
                  height: 1.6,
                ),
              );
            default:
              return TextSpan(
                text: d.text,
                style: TextStyle(
                  color: const Color(0xFF334155),
                  fontSize: 13.sp,
                  height: 1.6,
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
