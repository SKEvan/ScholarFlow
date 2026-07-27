import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';

class SummarizerReviewScreen extends StatefulWidget {
  const SummarizerReviewScreen({super.key});
  @override
  State<SummarizerReviewScreen> createState() => _SummarizerReviewScreenState();
}

class _SummarizerReviewScreenState extends State<SummarizerReviewScreen> {
  int _selectedVersion = 0;

  final List<Map<String, dynamic>> _versions = [
    {
      'title': 'Executive',
      'subtitle': 'High-level takeaway',
      'icon': Icons.bolt_rounded,
      'iconColor': AppTheme.warmAmber,
      'iconBg': AppTheme.warmAmberSoft,
      'tagline': '1-min skim',
      'isGenerating': false,
      'preview': 'Hybrid quantum-classical architectures reduce training overhead by 40% while improving predictive accuracy on high-frequency streams. Latency drops 18%; plateau observed past 32 qubits.',
      'meta1': '2 min read',
      'meta2': 'Everyday tone',
      'bullets': ['Headline result in one line', 'Why it matters for non-specialists', 'What to do next with this paper'],
    },
    {
      'title': 'Technical',
      'subtitle': 'Method + results',
      'icon': Icons.terminal_rounded,
      'iconColor': AppTheme.friendlyPurple,
      'iconBg': AppTheme.friendlyPurpleSoft,
      'tagline': 'Reproducibility-first',
      'isGenerating': true,
      'preview': 'We adopt a QV-CNN with depth-3 variational ansatz, AdamW (lr=3e-4), cosine annealing, and report benchmarks on NASDAQ HFT, weather radar, and genomic streams.',
      'meta1': '12 min read',
      'meta2': 'Reproducible',
      'bullets': ['Proves a 2x acceleration bound for QV-CNN', 'Establishes convergence under mild Lipschitz assumptions', 'Open challenge on decoherence-aware loss landscapes'],
    },
    {
      'title': 'Layman',
      'subtitle': 'Story form',
      'icon': Icons.menu_book_rounded,
      'iconColor': AppTheme.actionBlue,
      'iconBg': AppTheme.accentBlueSoft,
      'tagline': 'Plain English',
      'isGenerating': false,
      'preview': 'Think of a self-driving car that learns from many tiny microphones at once. This paper shows how to do the same trick with quantum chips, using less power and learning faster.',
      'meta1': '4 min read',
      'meta2': 'Story format',
      'bullets': ['A car-analogy that you can repeat at dinner', 'A short timeline of how this technology came about', 'One concrete way you could use it tomorrow'],
    },
  ];

  void _onVersionTap(int id) {
    setState(() => _selectedVersion = id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryNavy,
        duration: const Duration(milliseconds: 1400),
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 90.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        content: Text('Showing ${_versions[id]['title']} version', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.warmSurface,
      appBar: AppBar(
        backgroundColor: AppTheme.warmSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface), onPressed: () => Navigator.of(context).pop()),
        title: Text('ScholarFlow', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primaryNavy)),
        actions: [IconButton(icon: Icon(Icons.tune_rounded, color: theme.colorScheme.onSurface.withOpacity(0.55)), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 130.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), decoration: BoxDecoration(color: AppTheme.warmAmberSoft, borderRadius: BorderRadius.circular(999.r), border: Border.all(color: AppTheme.warmAmberBorder)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.summarize_rounded, size: 14.sp, color: AppTheme.warmAmber), SizedBox(width: 5.w), Text('SUMMARY', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy))])),
            SizedBox(height: 10.h),
            Text('Three takes, one paper', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy)),
            SizedBox(height: 4.h),
            Text('Pick the depth that fits your moment — from a 60-second skim to a reproducible walk-through.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.4)),
            SizedBox(height: 18.h),
            for (int i = 0; i < _versions.length; i++) Padding(padding: EdgeInsets.only(bottom: 12.h), child: _buildVersionCard(theme, _versions[i], i)),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(ThemeData theme, Map<String, dynamic> v, int id) {
    final selected = _selectedVersion == id;
    final generating = v['isGenerating'] == true;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onVersionTap(id),
        borderRadius: BorderRadius.circular(18.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: selected ? AppTheme.actionBlue : AppTheme.warmAmberBorder, width: selected ? 2.w : 1.w),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(selected ? 0.10 : 0.04), blurRadius: selected ? 14 : 8, offset: Offset(0, 4.h))],
          ),
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 42.w, height: 42.h, decoration: BoxDecoration(color: v['iconBg'], borderRadius: BorderRadius.circular(12.r)), child: Icon(v['icon'], color: v['iconColor'], size: 22.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['title'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy)),
                        SizedBox(height: 2.h),
                        Text(v['subtitle'], style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, key: ValueKey(selected), color: selected ? AppTheme.actionBlue : theme.colorScheme.onSurface.withOpacity(0.25), size: 24.sp),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: AppTheme.warmAmberSoft, borderRadius: BorderRadius.circular(999.r), border: Border.all(color: AppTheme.warmAmberBorder)), child: Text(v['tagline'], style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy))),
                  SizedBox(width: 6.w),
                  Text('· ${v['meta1']} · ${v['meta2']}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.55))),
                ],
              ),
              SizedBox(height: 12.h),
              if (generating) _buildShimmerBlock(theme) else Text(v['preview'], style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.primaryNavy.withOpacity(0.85), height: 1.5)),
              SizedBox(height: 12.h),
              ...v['bullets'].map<Widget>((b) => Padding(padding: EdgeInsets.only(bottom: 6.h), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.subdirectory_arrow_right_rounded, size: 16.sp, color: v['iconColor']), SizedBox(width: 8.w), Expanded(child: Text(b, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryNavy.withOpacity(0.8), height: 1.4)))]))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBlock(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 14.w, height: 14.h, decoration: BoxDecoration(color: AppTheme.warmAmber, shape: BoxShape.circle)),
          SizedBox(width: 8.w),
          Text('GENERATING', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: AppTheme.warmAmber, letterSpacing: 1.2)),
        ]),
        SizedBox(height: 10.h),
        _shimmerBar(width: double.infinity, height: 12.h),
        SizedBox(height: 8.h),
        _shimmerBar(width: double.infinity, height: 12.h),
        SizedBox(height: 8.h),
        _shimmerBar(width: 200.w, height: 12.h),
      ],
    );
  }

  Widget _shimmerBar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment(-1, 0), end: Alignment(1, 0), colors: [AppTheme.warmAmberSoft, AppTheme.friendlyPurpleSoft, AppTheme.warmAmberSoft], stops: const [0.0, 0.5, 1.0]),
        borderRadius: BorderRadius.circular(6.r),
      ),
    );
  }
  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(theme, Icons.dashboard_rounded, 'Home', false, () => Navigator.of(context).pushReplacementNamed('/dashboard')),
              _navItem(theme, Icons.folder_open_rounded, 'Projects', false, () => Navigator.of(context).pushReplacementNamed('/projects')),
              _navItem(theme, Icons.groups_rounded, 'Network', false, () => Navigator.of(context).pushReplacementNamed('/network')),
              _navItem(theme, Icons.auto_awesome_rounded, 'Tools', true, null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(ThemeData theme, IconData icon, String label, bool isActive, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.actionBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 16.sp, color: isActive ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.55)),
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppTheme.actionBlue : theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
