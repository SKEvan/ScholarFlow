import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';

class LiteratureReviewScreen extends StatefulWidget {
  const LiteratureReviewScreen({super.key});
  @override
  State<LiteratureReviewScreen> createState() => _LiteratureReviewScreenState();
}

class _LiteratureReviewScreenState extends State<LiteratureReviewScreen> {
  final TextEditingController _assistantCtrl = TextEditingController();
  final List<Map<String, String>> _chat = [];

  final List<Map<String, dynamic>> _sources = [
    {'tag': 'CORE', 'tagColor': AppTheme.friendlyPurple, 'tagBg': AppTheme.friendlyPurpleSoft, 'title': 'Chen & Liu, 2024', 'subtitle': 'A Probabilistic Framework for Quantum-Classical Feature Entanglement'},
    {'tag': 'CITED', 'tagColor': AppTheme.actionBlue, 'tagBg': AppTheme.accentBlueSoft, 'title': 'Patel et al., 2023', 'subtitle': 'Reproducible Benchmarks for Hybrid QV-CNN Architectures'},
    {'tag': 'CITED', 'tagColor': AppTheme.actionBlue, 'tagBg': AppTheme.accentBlueSoft, 'title': 'Watanabe et al., 2022', 'subtitle': 'Decoherence-Aware Loss Landscapes for Noisy Quantum Devices'},
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
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface), onPressed: () => Navigator.of(context).pop()),
        title: Text('ScholarFlow', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primaryNavy)),
        actions: [
          IconButton(icon: Icon(Icons.bookmark_added_rounded, color: theme.colorScheme.onSurface.withOpacity(0.55)), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 130.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOutputBanner(theme),
                SizedBox(height: 12.h),
                Text('Quantum-Classical Hybrid Architectures', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy, height: 1.2)),
                SizedBox(height: 10.h),
                Wrap(spacing: 6.w, runSpacing: 6.h, children: [
                  _metaPill(theme, Icons.calendar_today_rounded, 'Jan 15, 2024'),
                  _metaPill(theme, Icons.short_text_rounded, '12 pages'),
                  _metaPill(theme, Icons.verified_rounded, 'Peer-reviewed'),
                  _animatedReadOnly(theme),
                ]),
                SizedBox(height: 16.h),
                _buildAnalysisCard(theme),
                SizedBox(height: 12.h),
                _buildSourcesCard(theme),
                SizedBox(height: 12.h),
                _buildSynthesisCard(theme),
                SizedBox(height: 14.h),
                _buildActionBar(theme),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildAssistant(theme)),
        ],
      ),
    );
  }

  Widget _animatedReadOnly(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: AppTheme.successGreenSoft, borderRadius: BorderRadius.circular(999.r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        TweenAnimationBuilder<double>(
          key: const ValueKey('pulse'),
          tween: Tween<double>(begin: 0.35, end: 1.0),
          duration: const Duration(milliseconds: 1100),
          builder: (context, t, _) {
            return Opacity(opacity: t, child: Container(width: 6.w, height: 6.h, decoration: BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle)));
          },
        ),
        SizedBox(width: 5.w),
        Text('READ ONLY', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: AppTheme.successGreen)),
      ]),
    );
  }

  Widget _buildOutputBanner(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF8EE), Color(0xFFFFF1E0)]), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppTheme.warmAmberBorder)),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Container(width: 32.w, height: 32.h, decoration: BoxDecoration(color: AppTheme.warmAmber, borderRadius: BorderRadius.circular(9.r)), child: Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Expanded(child: Text('Output finalized — saved to your Literature library.', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primaryNavy))),
        ],
      ),
    );
  }

  Widget _metaPill(ThemeData theme, IconData icon, String label) {
    return Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999.r), border: Border.all(color: AppTheme.warmAmberBorder)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13.sp, color: AppTheme.warmAmber), SizedBox(width: 5.w), Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy))]));
  }

  Widget _buildAnalysisCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppTheme.warmAmberBorder)),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 36.w, height: 36.h, decoration: BoxDecoration(color: AppTheme.friendlyPurpleSoft, borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.insights_rounded, color: AppTheme.friendlyPurple, size: 20.sp)), SizedBox(width: 10.w), Text('Core Analysis', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy))]),
          SizedBox(height: 10.h),
          Text('Three independent studies converge on the conclusion that hybrid quantum-classical architectures outperform pure Transformer baselines on high-frequency time-series forecasting, while disagreeing on the scaling regime where advantages emerge.', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.primaryNavy.withOpacity(0.85), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSourcesCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppTheme.warmAmberBorder)),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 36.w, height: 36.h, decoration: BoxDecoration(color: AppTheme.accentBlueSoft, borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.source_rounded, color: AppTheme.actionBlue, size: 20.sp)), SizedBox(width: 10.w), Text('Key Sources', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy))]),
          SizedBox(height: 10.h),
          ..._sources.map((s) => Padding(padding: EdgeInsets.only(bottom: 8.h), child: Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: AppTheme.warmAmberSoft, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppTheme.warmAmberBorder)), child: Row(children: [Container(padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), decoration: BoxDecoration(color: s['tagBg'], borderRadius: BorderRadius.circular(999.r)), child: Text(s['tag'], style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, color: s['tagColor']))), SizedBox(width: 10.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['title'], style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy)), SizedBox(height: 2.h), Text(s['subtitle'], style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.35))]))])))),
        ],
      ),
    );
  }

  Widget _buildSynthesisCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppTheme.warmAmberBorder)),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 36.w, height: 36.h, decoration: BoxDecoration(color: AppTheme.warmAmberSoft, borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.layers_rounded, color: AppTheme.warmAmber, size: 20.sp)), SizedBox(width: 10.w), Text('Detailed Synthesis', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy)), const Spacer(), Container(padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.08), borderRadius: BorderRadius.circular(999.r)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_outline_rounded, size: 10.sp, color: theme.colorScheme.onSurface.withOpacity(0.55)), SizedBox(width: 3.w), Text('Locked', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.7)))]))]),
          SizedBox(height: 10.h),
          Text('Across three benchmark datasets (NASDAQ HFT, weather radar, genomic streams), hybrid architectures sustain a 40% training overhead reduction and 18% inference latency improvement, with decoherence effects dominating above 32 qubits.', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.primaryNavy.withOpacity(0.85), height: 1.5)),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: AppTheme.warmAmberSoft, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppTheme.warmAmberBorder)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.format_quote_rounded, color: AppTheme.warmAmber, size: 20.sp), SizedBox(width: 8.w), Expanded(child: Text('"The hybrid architecture reduces training overhead by 40% while improving predictive accuracy."', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.primaryNavy.withOpacity(0.9), height: 1.4)))]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _actionButton(theme, Icons.download_rounded, 'Export')),
        SizedBox(width: 8.w),
        Expanded(child: _actionButton(theme, Icons.share_rounded, 'Share')),
        SizedBox(width: 8.w),
        Expanded(child: Container(decoration: BoxDecoration(color: AppTheme.actionBlue, borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18.sp), SizedBox(width: 6.w), Text('Deploy', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white))]))),
      ],
    );
  }

  Widget _actionButton(ThemeData theme, IconData icon, String label) {
    return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppTheme.warmAmberBorder)), padding: EdgeInsets.symmetric(vertical: 12.h), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppTheme.primaryNavy, size: 18.sp), SizedBox(width: 6.w), Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy))]));
  }

  Widget _buildAssistant(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: Offset(0, -3.h))]),
      padding: EdgeInsets.all(12.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [Container(width: 32.w, height: 32.h, decoration: BoxDecoration(color: AppTheme.warmAmber, borderRadius: BorderRadius.circular(9.r)), child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18.sp)), SizedBox(width: 10.w), Expanded(child: Text('AI Assistant', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy))), Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h), decoration: BoxDecoration(color: AppTheme.successGreenSoft, borderRadius: BorderRadius.circular(999.r)), child: Row(mainAxisSize: MainAxisSize.min, children: [TweenAnimationBuilder<double>(tween: Tween<double>(begin: 0.35, end: 1.0), duration: const Duration(milliseconds: 1100), builder: (ctx, t, _) { return Opacity(opacity: t, child: Container(width: 6.w, height: 6.h, decoration: BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle))); }), SizedBox(width: 5.w), Text('Online', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppTheme.successGreen))]))]),
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
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      constraints: BoxConstraints(maxWidth: 240.w),
                      decoration: BoxDecoration(color: isUser ? AppTheme.actionBlue : AppTheme.warmAmberSoft, borderRadius: BorderRadius.circular(12.r)),
                      child: Text(m['text']!, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isUser ? Colors.white : AppTheme.primaryNavy)),
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: 8.h),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_chip(theme, 'Explain jargon', () => _sendMessage(chipText: 'Explain jargon')), _chip(theme, 'Find counter-evidence', () => _sendMessage(chipText: 'Find counter-evidence')), _chip(theme, 'Suggest follow-ups', () => _sendMessage(chipText: 'Suggest follow-ups'))])),
          SizedBox(height: 8.h),
          Row(children: [Expanded(child: Container(decoration: BoxDecoration(color: AppTheme.warmSurface, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppTheme.warmAmberBorder)), padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h), child: TextField(controller: _assistantCtrl, onSubmitted: (_) => _sendMessage(), decoration: InputDecoration.collapsed(hintText: 'Ask anything...', hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.45))), style: theme.textTheme.bodyMedium))), SizedBox(width: 8.w), Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(12.r), onTap: () => _sendMessage(), child: Container(width: 44.w, height: 44.h, decoration: BoxDecoration(color: AppTheme.actionBlue, borderRadius: BorderRadius.circular(12.r)), child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp))))]),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999.r),
        child: Container(
          margin: EdgeInsets.only(right: 6.w),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(color: AppTheme.warmAmberSoft, borderRadius: BorderRadius.circular(999.r), border: Border.all(color: AppTheme.warmAmberBorder)),
          child: Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy)),
        ),
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
