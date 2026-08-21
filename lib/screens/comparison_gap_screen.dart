import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';

class ComparisonGapScreen extends StatefulWidget {
  const ComparisonGapScreen({super.key});
  @override
  State<ComparisonGapScreen> createState() => _ComparisonGapScreenState();
}

class _ComparisonGapScreenState extends State<ComparisonGapScreen> {
  final TextEditingController _assistantCtrl = TextEditingController();
  final List<Map<String, String>> _chat = [];
  int _keepCount = 0;

  final List<Map<String, dynamic>> _versions = [
    {
      'title': 'Theoretical',
      'subtitle': 'Chen & Liu, 2024',
      'icon': Icons.psychology_alt_rounded,
      'iconColor': AppTheme.friendlyPurple,
      'iconBg': AppTheme.friendlyPurpleSoft,
      'tagline': 'Foundational framing',
      'preview':
          'Introduces a probabilistic framework for quantum-classical feature entanglement. Demonstrates theoretical scaling advantages for high-dimensional inference tasks.',
      'highlights': [
        'Proves a 2x acceleration bound for QV-CNN architectures',
        'Establishes convergence under mild Lipschitz assumptions',
        'Sketches an open challenge on decoherence-aware loss landscapes',
      ],
    },
    {
      'title': 'Empirical',
      'subtitle': 'Patel et al., 2023',
      'icon': Icons.bar_chart_rounded,
      'iconColor': AppTheme.actionBlue,
      'iconBg': AppTheme.accentBlueSoft,
      'tagline': 'Benchmark-led study',
      'preview':
          'Provides reproducible benchmarks across NASDAQ HFT, weather radar, and genomic streams. Reports 40% training overhead reduction and 18% lower inference latency.',
      'highlights': [
        'Reproducible accuracy on three real-world datasets',
        'Highlights hardware-specific bottlenecks up to 32 qubits',
        'Open-sources benchmark pipeline and ablation scripts',
      ],
    },
  ];

  @override
  void dispose() {
    _assistantCtrl.dispose();
    super.dispose();
  }

  void _sendMessage({String? chipText}) {
    final text = (chipText ?? _assistantCtrl.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _chat.add({'role': 'user', 'text': text});
      _assistantCtrl.clear();
    });
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ScholarFlow',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 130.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.friendlyPurpleSoft,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.compare_arrows_rounded,
                        size: 14.sp,
                        color: AppTheme.friendlyPurple,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'COMPARE',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.friendlyPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Two takes, side by side',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Spot agreements fast. Focus on what they disagree on.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 18.h),
                ..._versions.map(
                  (v) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildVersionCard(theme, v),
                  ),
                ),
                SizedBox(height: 6.h),
                _buildGapCallout(theme),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildAssistantBar(theme),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildVersionCard(ThemeData theme, Map<String, dynamic> v) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppTheme.warmAmberBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: v['iconBg'],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(v['icon'], color: v['iconColor'], size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v['title'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      v['subtitle'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999.r),
                  onTap: () {
                    setState(() => _keepCount += 1);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.successGreen,
                        duration: const Duration(milliseconds: 1200),
                        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 90.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        content: Text(
                          'Kept: ${v['title']} version ($_keepCount saved)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warmAmberSoft,
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(color: AppTheme.warmAmberBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_add_rounded,
                          size: 13.sp,
                          color: AppTheme.warmAmber,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Keep',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppTheme.warmAmberSoft,
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(color: AppTheme.warmAmberBorder),
            ),
            child: Text(
              v['tagline'],
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            v['preview'],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryNavy.withOpacity(0.85),
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          ...v['highlights'].map<Widget>(
            (h) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16.sp,
                    color: AppTheme.successGreen,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      h,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryNavy.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapCallout(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmAmberSoft,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppTheme.warmAmberBorder),
      ),
      padding: EdgeInsets.all(14.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: AppTheme.warmAmber,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where they disagree',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Chen & Liu prove an asymptotic scaling bound; Patel et al. observe plateauing past 32 qubits on real hardware. Treated as an open challenge.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryNavy.withOpacity(0.85),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: Offset(0, -3.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: AppTheme.warmAmber,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'AI Assistant',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppTheme.successGreenSoft,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_chat.isNotEmpty) ...[
            SizedBox(height: 10.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 140.h),
              child: ListView.separated(
                shrinkWrap: true,
                reverse: true,
                itemCount: _chat.length,
                separatorBuilder: (_, __) => SizedBox(height: 6.h),
                itemBuilder: (_, i) {
                  final m = _chat[_chat.length - 1 - i];
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      constraints: BoxConstraints(maxWidth: 240.w),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppTheme.actionBlue
                            : AppTheme.warmAmberSoft,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        m['text']!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: isUser ? Colors.white : AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickChip(
                  theme,
                  Icons.bolt_rounded,
                  'Make it technical',
                  () => _sendMessage(chipText: 'Make it more technical'),
                ),
                _quickChip(
                  theme,
                  Icons.trending_up_rounded,
                  'Focus on ROI',
                  () => _sendMessage(chipText: 'Focus on ROI'),
                ),
                _quickChip(
                  theme,
                  Icons.summarize_rounded,
                  'Summarize gaps',
                  () => _sendMessage(chipText: 'Summarize the gaps'),
                ),
                _quickChip(
                  theme,
                  Icons.format_quote_rounded,
                  'Cite sources',
                  () => _sendMessage(chipText: 'Cite sources'),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.warmSurface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppTheme.warmAmberBorder),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  child: TextField(
                    controller: _assistantCtrl,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Ask anything...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => _sendMessage(),
                  child: Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: AppTheme.actionBlue,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999.r),
        child: Container(
          margin: EdgeInsets.only(right: 6.w),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppTheme.warmAmberSoft,
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(color: AppTheme.warmAmberBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13.sp, color: AppTheme.warmAmber),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                theme,
                Icons.dashboard_rounded,
                'Home',
                false,
                () => Navigator.of(context).pushReplacementNamed('/dashboard'),
              ),
              _navItem(
                theme,
                Icons.folder_open_rounded,
                'Projects',
                false,
                () => Navigator.of(context).pushReplacementNamed('/projects'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    ThemeData theme,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback? onTap,
  ) {
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
                child: Icon(
                  icon,
                  size: 16.sp,
                  color: isActive
                      ? Colors.white
                      : theme.colorScheme.onSurface.withOpacity(0.55),
                ),
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
                  color: isActive
                      ? AppTheme.actionBlue
                      : theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
