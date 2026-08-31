import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/rich_text_editor.dart';
import '../theme.dart';

class EditorTestScreen extends StatefulWidget {
  const EditorTestScreen({super.key});

  @override
  State<EditorTestScreen> createState() => _EditorTestScreenState();
}

class _EditorTestScreenState extends State<EditorTestScreen> {
  final GlobalKey<RichTextEditorState> _editorKey = GlobalKey();
  String _savedTitle = '';
  String _savedContent = '';

  void _onSave(String title, String content) {
    setState(() {
      _savedTitle = title;
      _savedContent = content;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        backgroundColor: AppTheme.successGreen,
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 17.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Saved: "${title.isEmpty ? "Untitled" : title}"',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Note Editor',
          style: GoogleFonts.fredoka(
            fontSize: 18.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // Use a scrollable that doesn't fight with the editor's internal scroll
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 8.h),
            sliver: SliverToBoxAdapter(
              child: RichTextEditor(
                key: _editorKey,
                initialTitle: 'Literature Review Notes',
                initialContent:
                    'Transformer architectures have demonstrated remarkable '
                    'capabilities across NLP tasks.\n\n'
                    '• Multi-head attention overhead scales quadratically.\n'
                    '• Sparse attention reduces complexity to O(n √n).\n'
                    '• Flash Attention improves throughput by 2–4×.',
                onSave: _onSave,
              ),
            ),
          ),
          if (_savedTitle.isNotEmpty || _savedContent.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 32.h),
              sliver: SliverToBoxAdapter(child: _buildSavePreview()),
            ),
        ],
      ),
    );
  }

  Widget _buildSavePreview() {
    return Container(
      margin: EdgeInsets.only(top: 14.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppTheme.successGreenSoft,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt_rounded,
                  color: AppTheme.successGreen, size: 15.sp),
              SizedBox(width: 6.w),
              Text(
                'Last saved note',
                style: GoogleFonts.fredoka(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Title: ${_savedTitle.isEmpty ? "Untitled" : _savedTitle}',
            style: GoogleFonts.fredoka(
              fontSize: 13.sp,
              color: const Color(0xFF065F46),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              _savedContent.isEmpty ? '(empty)' : _savedContent,
              style: GoogleFonts.fredoka(
                fontSize: 12.sp,
                color: const Color(0xFF065F46),
                height: 1.5,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
