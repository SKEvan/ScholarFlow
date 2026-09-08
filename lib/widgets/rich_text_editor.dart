import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RichTextEditor – True WYSIWYG editor: Bold, Italic, Underline, Highlight,
// Heading, Bullet Points, live word count. No markdown symbols in text.
// ─────────────────────────────────────────────────────────────────────────────

enum _FormatType { bold, italic, underline, highlight, heading, bullet }

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    super.key,
    this.initialTitle = '',
    this.initialContent = '',
    this.onSave,
    this.onChanged,
    this.readOnly = false,
    this.saveLabel = 'Save now',
  });

  final String initialTitle;
  final String initialContent;
  final void Function(String title, String content)? onSave;
  final void Function(String title, String content)? onChanged;
  final bool readOnly;

  /// Label for the footer save button. Callers that route the save
  /// through an approval flow (e.g. a non-owner submitting an edit
  /// request) can override this, e.g. "Send Approval Request".
  final String saveLabel;

  @override
  State<RichTextEditor> createState() => RichTextEditorState();
}

class RichTextEditorState extends State<RichTextEditor> {
  late final TextEditingController _titleCtrl;
  late final _RichController _contentCtrl;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  // Saved selection so toolbar taps don't lose highlighted text
  TextSelection _savedSel = const TextSelection.collapsed(offset: 0);

  // Undo history
  final List<String> _history = [];
  int _histIdx = -1;
  bool _suppressHistory = false;

  static const _navy = Color(0xFF0F172A);
  static const _blue = Color(0xFF2563EB);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E8F0);
  static const _toolbarBg = Color(0xFFF8FAFC);
  static const _dividerColor = Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _contentCtrl = _RichController(text: widget.initialContent);

    _history.add(widget.initialContent);
    _histIdx = 0;

    _contentCtrl.addListener(_onContentChange);
    _titleCtrl.addListener(_onTitleChange);

    // Track selection continuously
    _contentFocus.addListener(() {
      if (!_contentFocus.hasFocus) {
        // Save selection when focus leaves (toolbar tap)
        final s = _contentCtrl.selection;
        if (s.isValid) _savedSel = s;
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _onContentChange() {
    final s = _contentCtrl.selection;
    if (s.isValid) _savedSel = s;
    if (!_suppressHistory) {
      final t = _contentCtrl.text;
      if (_histIdx < _history.length - 1) {
        _history.removeRange(_histIdx + 1, _history.length);
      }
      if (_history.isEmpty || _history.last != t) {
        _history.add(t);
        _histIdx = _history.length - 1;
      }
    }
    widget.onChanged?.call(_titleCtrl.text, _contentCtrl.text);
    setState(() {});
  }

  void _onTitleChange() {
    widget.onChanged?.call(_titleCtrl.text, _contentCtrl.text);
    setState(() {});
  }

  // ── Undo / Redo ────────────────────────────────────────────────────────────

  void _undo() {
    if (_histIdx > 0) {
      _histIdx--;
      _suppressHistory = true;
      _contentCtrl.value = TextEditingValue(
        text: _history[_histIdx],
        selection: TextSelection.collapsed(offset: _history[_histIdx].length),
      );
      _suppressHistory = false;
      setState(() {});
    }
  }

  void _redo() {
    if (_histIdx < _history.length - 1) {
      _histIdx++;
      _suppressHistory = true;
      _contentCtrl.value = TextEditingValue(
        text: _history[_histIdx],
        selection: TextSelection.collapsed(offset: _history[_histIdx].length),
      );
      _suppressHistory = false;
      setState(() {});
    }
  }

  /// Programmatically replace editor content (e.g. for "Copy to Editor").
  void setContent(String text) {
    _contentCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String get content => _contentCtrl.text;
  String get title => _titleCtrl.text;

  // ── Format ─────────────────────────────────────────────────────────────────

  void _applyFormat(_FormatType fmt) {
    if (widget.readOnly) return;

    if (fmt == _FormatType.bullet) {
      _toggleBullet();
      return;
    }

    final tf = switch (fmt) {
      _FormatType.bold => _TF.bold,
      _FormatType.italic => _TF.italic,
      _FormatType.underline => _TF.underline,
      _FormatType.highlight => _TF.highlight,
      _FormatType.heading => _TF.heading,
      _FormatType.bullet => null,
    };

    if (tf == null) return;

    // Use saved selection; fall back to current controller selection
    TextSelection sel = _contentCtrl.selection.isValid && !_contentCtrl.selection.isCollapsed
        ? _contentCtrl.selection
        : _savedSel;

    _contentCtrl.toggleFmt(tf, sel);

    // Restore selection & refocus
    _contentCtrl.selection = sel;
    _savedSel = sel;
    _contentFocus.requestFocus();
    setState(() {});
  }

  // ── Bullet toggle ──────────────────────────────────────────────────────────

  void _toggleBullet() {
    final text = _contentCtrl.text;

    // If no text yet, start a bullet
    if (text.isEmpty) {
      _contentCtrl.value = const TextEditingValue(
        text: '• ',
        selection: TextSelection.collapsed(offset: 2),
      );
      _savedSel = const TextSelection.collapsed(offset: 2);
      _contentFocus.requestFocus();
      setState(() {});
      return;
    }

    // Determine cursor/selection position
    TextSelection sel = _contentCtrl.selection.isValid
        ? _contentCtrl.selection
        : _savedSel;

    final cursorPos = sel.isValid ? sel.end.clamp(0, text.length) : text.length;

    // Find start of the first affected line
    int lineStart = 0;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '\n') {
        lineStart = i + 1;
        break;
      }
    }

    // Find end of the last affected line
    int lineEnd = text.length;
    for (int i = cursorPos; i < text.length; i++) {
      if (text[i] == '\n') {
        lineEnd = i;
        break;
      }
    }

    // If selection spans multiple lines, include them all
    if (!sel.isCollapsed && sel.isValid) {
      int selStart = sel.start.clamp(0, text.length);
      // Adjust lineStart to earliest selected line
      for (int i = selStart - 1; i >= 0; i--) {
        if (text[i] == '\n') {
          lineStart = i + 1;
          break;
        }
        if (i == 0) lineStart = 0;
      }
      // Adjust lineEnd to end of last selected line
      int selEnd = sel.end.clamp(0, text.length);
      lineEnd = text.length;
      for (int i = selEnd; i < text.length; i++) {
        if (text[i] == '\n') {
          lineEnd = i;
          break;
        }
      }
    }

    final block = text.substring(lineStart, lineEnd);
    final lines = block.split('\n');
    final allBulleted = lines.isNotEmpty && lines.every((l) => l.startsWith('• '));

    final newLines = lines.map((l) {
      if (allBulleted) {
        return l.startsWith('• ') ? l.substring(2) : l;
      } else {
        return l.startsWith('• ') ? l : '• $l';
      }
    }).toList();

    final newBlock = newLines.join('\n');
    final newText = text.replaceRange(lineStart, lineEnd, newBlock);
    final newCursor = (lineStart + newBlock.length).clamp(0, newText.length);

    _contentCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _savedSel = TextSelection.collapsed(offset: newCursor);
    _contentFocus.requestFocus();
    setState(() {});
  }

  // ── Word count ─────────────────────────────────────────────────────────────

  int get _wordCount {
    final t = _contentCtrl.text.trim();
    if (t.isEmpty) return 0;
    return t
        .split(RegExp(r'\s+'))
        .where((w) => RegExp(r'[a-zA-Z0-9\u00C0-\u024F]').hasMatch(w))
        .length;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  String get currentTitle => _titleCtrl.text;
  String get currentContent => _contentCtrl.text;
  void saveNow() => widget.onSave?.call(_titleCtrl.text, _contentCtrl.text);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbar(),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _buildTitleField(),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _buildContentField(),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Toolbar ────────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    final sel = _contentCtrl.selection.isValid && !_contentCtrl.selection.isCollapsed
        ? _contentCtrl.selection
        : _savedSel;

    return Container(
      color: _toolbarBg,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TBtn(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              active: _contentCtrl.isFmtActive(_TF.bold, sel),
              onTap: () => _applyFormat(_FormatType.bold),
            ),
            _TBtn(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              active: _contentCtrl.isFmtActive(_TF.italic, sel),
              onTap: () => _applyFormat(_FormatType.italic),
            ),
            _TBtn(
              icon: Icons.format_underline_rounded,
              tooltip: 'Underline',
              active: _contentCtrl.isFmtActive(_TF.underline, sel),
              onTap: () => _applyFormat(_FormatType.underline),
            ),
            _TBtn(
              icon: Icons.highlight_rounded,
              tooltip: 'Highlight',
              active: _contentCtrl.isFmtActive(_TF.highlight, sel),
              activeColor: const Color(0xFFCA8A04),
              activeBg: const Color(0xFFFEF9C3),
              onTap: () => _applyFormat(_FormatType.highlight),
            ),
            _vDivider(),
            _TBtn(
              icon: Icons.title_rounded,
              tooltip: 'Heading',
              active: _contentCtrl.isFmtActive(_TF.heading, sel),
              onTap: () => _applyFormat(_FormatType.heading),
            ),
            _TBtn(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet list',
              active: false,
              onTap: () => _applyFormat(_FormatType.bullet),
            ),
            _vDivider(),
            _TBtn(
              icon: Icons.undo_rounded,
              tooltip: 'Undo',
              active: false,
              enabled: _histIdx > 0,
              onTap: _undo,
            ),
            _TBtn(
              icon: Icons.redo_rounded,
              tooltip: 'Redo',
              active: false,
              enabled: _histIdx < _history.length - 1,
              onTap: _redo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1.w,
        height: 20.h,
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        color: _dividerColor,
      );

  // ── Title ──────────────────────────────────────────────────────────────────

  Widget _buildTitleField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: TextField(
        controller: _titleCtrl,
        focusNode: _titleFocus,
        readOnly: widget.readOnly,
        style: GoogleFonts.fredoka(
          fontSize: 19.sp,
          fontWeight: FontWeight.w600,
          color: _navy,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: 'Note title…',
          hintStyle: GoogleFonts.fredoka(
            fontSize: 19.sp,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        maxLines: 2,
        minLines: 1,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _contentFocus.requestFocus(),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContentField() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: TextField(
        controller: _contentCtrl,
        focusNode: _contentFocus,
        readOnly: widget.readOnly,
        expands: false,
        maxLines: null,
        minLines: 12,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: GoogleFonts.fredoka(
          fontSize: 14.5.sp,
          height: 1.7,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Start writing your note here…',
          hintStyle: GoogleFonts.fredoka(
            fontSize: 14.sp,
            height: 1.7,
            color: const Color(0xFFCBD5E1),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final wc = _wordCount;
    return Container(
      color: _toolbarBg,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          // Word count badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '$wc ${wc == 1 ? "word" : "words"}',
              style: GoogleFonts.fredoka(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          // Save button
          if (!widget.readOnly)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: saveNow,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(22.r),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_alt_rounded, size: 15.sp, color: Colors.white),
                    SizedBox(width: 6.w),
                    Text(
                      widget.saveLabel,
                      style: GoogleFonts.fredoka(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar button
// ─────────────────────────────────────────────────────────────────────────────

class _TBtn extends StatelessWidget {
  const _TBtn({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.activeColor = const Color(0xFF2563EB),
    this.activeBg = const Color(0xFFEFF6FF),
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final Color activeColor;
  final Color activeBg;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.symmetric(horizontal: 1.5.w),
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: active
                ? Border.all(color: activeColor.withValues(alpha: 0.35), width: 1)
                : null,
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: !enabled
                ? const Color(0xFFCBD5E1)
                : active
                    ? activeColor
                    : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text format enum & styled char
// ─────────────────────────────────────────────────────────────────────────────

enum _TF { bold, italic, underline, highlight, heading }

// Public alias used from outside this file
typedef TextFormat = _TF;

class _StyledChar {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool highlight;
  final bool heading;

  const _StyledChar({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.highlight = false,
    this.heading = false,
  });

  _StyledChar withFmt(_TF f, bool on) => _StyledChar(
        bold: f == _TF.bold ? on : bold,
        italic: f == _TF.italic ? on : italic,
        underline: f == _TF.underline ? on : underline,
        highlight: f == _TF.highlight ? on : highlight,
        heading: f == _TF.heading ? on : heading,
      );

  bool get(_TF f) => switch (f) {
        _TF.bold => bold,
        _TF.italic => italic,
        _TF.underline => underline,
        _TF.highlight => highlight,
        _TF.heading => heading,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _StyledChar &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          highlight == other.highlight &&
          heading == other.heading;

  @override
  int get hashCode => Object.hash(bold, italic, underline, highlight, heading);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich controller
// ─────────────────────────────────────────────────────────────────────────────

class _RichController extends TextEditingController {
  List<_StyledChar> _styles = [];

  // Active formats for newly typed characters
  final Set<_TF> _active = {};

  _RichController({super.text}) {
    if (text.isNotEmpty) {
      _styles = List.filled(text.length, const _StyledChar(), growable: true);
    }
  }

  @override
  set value(TextEditingValue nv) {
    _sync(text, nv.text);
    super.value = nv;
  }

  // Sync styles when text changes by finding the edit region via prefix/suffix
  void _sync(String oldT, String newT) {
    if (oldT == newT) return;

    if (newT.isEmpty) {
      _styles = [];
      return;
    }

    if (oldT.isEmpty) {
      final def = _StyledChar(
        bold: _active.contains(_TF.bold),
        italic: _active.contains(_TF.italic),
        underline: _active.contains(_TF.underline),
        highlight: _active.contains(_TF.highlight),
        heading: _active.contains(_TF.heading),
      );
      _styles = List.filled(newT.length, def, growable: true);
      return;
    }

    // Common prefix
    int pre = 0;
    while (pre < oldT.length && pre < newT.length && oldT[pre] == newT[pre]) {
      pre++;
    }
    // Common suffix
    int suf = 0;
    while (suf < oldT.length - pre &&
        suf < newT.length - pre &&
        oldT[oldT.length - 1 - suf] == newT[newT.length - 1 - suf]) {
      suf++;
    }

    final deleted = oldT.length - pre - suf;
    final inserted = newT.length - pre - suf;

    // Remove deleted chars
    if (deleted > 0) {
      final end = (pre + deleted).clamp(0, _styles.length);
      if (pre <= end) _styles.removeRange(pre, end);
    }

    // Insert new chars with current active style
    if (inserted > 0) {
      _StyledChar ins;
      if (_active.isNotEmpty) {
        ins = _StyledChar(
          bold: _active.contains(_TF.bold),
          italic: _active.contains(_TF.italic),
          underline: _active.contains(_TF.underline),
          highlight: _active.contains(_TF.highlight),
          heading: _active.contains(_TF.heading),
        );
      } else if (pre > 0 && pre - 1 < _styles.length) {
        ins = _styles[pre - 1]; // inherit from char before cursor
      } else {
        ins = const _StyledChar();
      }
      final insPos = pre.clamp(0, _styles.length);
      _styles.insertAll(insPos, List.filled(inserted, ins, growable: true));
    }

    // Pad/trim to match new text length
    if (_styles.length < newT.length) {
      _styles.addAll(List.filled(newT.length - _styles.length, const _StyledChar(), growable: true));
    } else if (_styles.length > newT.length) {
      _styles = _styles.sublist(0, newT.length).toList(); // toList() ensures growable
    }
  }

  void toggleFmt(_TF fmt, [TextSelection? customSel]) {
    final sel = customSel ?? selection;
    final hasRange = sel.isValid && !sel.isCollapsed;

    if (hasRange) {
      final start = sel.start.clamp(0, text.length);
      final end = sel.end.clamp(0, text.length);

      // Check if ALL chars in selection already have this format
      bool allHave = true;
      for (int i = start; i < end && i < _styles.length; i++) {
        if (!_styles[i].get(fmt)) {
          allHave = false;
          break;
        }
      }
      final enable = !allHave;

      for (int i = start; i < end && i < _styles.length; i++) {
        _styles[i] = _styles[i].withFmt(fmt, enable);
      }

      if (enable) {
        _active.add(fmt);
      } else {
        _active.remove(fmt);
      }
    } else {
      // No selection – toggle the "cursor format" for upcoming typed chars
      if (_active.contains(fmt)) {
        _active.remove(fmt);
      } else {
        _active.add(fmt);
      }
    }
    notifyListeners();
  }

  bool isFmtActive(_TF fmt, [TextSelection? customSel]) {
    final sel = customSel ?? selection;
    final hasRange = sel.isValid && !sel.isCollapsed;

    if (hasRange) {
      final start = sel.start.clamp(0, text.length);
      final end = sel.end.clamp(0, text.length);
      for (int i = start; i < end && i < _styles.length; i++) {
        if (_styles[i].get(fmt)) return true;
      }
      return false;
    }
    return _active.contains(fmt);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    if (text.isEmpty || _styles.isEmpty) {
      return TextSpan(style: base, text: text);
    }

    final spans = <TextSpan>[];
    int i = 0;
    while (i < text.length && i < _styles.length) {
      final s = _styles[i];
      int j = i + 1;
      while (j < text.length && j < _styles.length && _styles[j] == s) {
        j++;
      }

      TextStyle ts = base;
      if (s.bold) ts = ts.copyWith(fontWeight: FontWeight.bold);
      if (s.italic) ts = ts.copyWith(fontStyle: FontStyle.italic);
      if (s.underline) {
        ts = ts.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: ts.color,
        );
      }
      if (s.highlight) {
        ts = ts.copyWith(
          backgroundColor: const Color(0xFFFEF08A),
          color: const Color(0xFF0F172A),
        );
      }
      if (s.heading) {
        ts = ts.copyWith(
          fontSize: (base.fontSize ?? 14.5.sp) * 1.38,
          fontWeight: FontWeight.bold,
          height: 1.4,
        );
      }

      spans.add(TextSpan(text: text.substring(i, j), style: ts));
      i = j;
    }

    // Any remaining text with no style record
    if (i < text.length) {
      spans.add(TextSpan(text: text.substring(i), style: base));
    }

    return TextSpan(style: base, children: spans);
  }
}
