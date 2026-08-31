import 'package:diff_match_patch/diff_match_patch.dart';

/// Word-level diff between [oldText] and [newText].
///
/// diff_match_patch's `diff()` operates character-by-character. To get
/// Google-Docs-style word-level highlighting instead, each whitespace run
/// or word is mapped to a single private-use-area character, the encoded
/// strings are diffed at the character level (which is now word level),
/// and the result is decoded back to real text. This is the same "line
/// mode" trick diff_match_patch itself uses internally for line diffs,
/// applied to word tokens instead of lines.
///
/// Capped at ~6,400 unique tokens (the BMP private-use area) — comfortably
/// more than a single paper section will ever contain. If that cap were
/// exceeded, tokens beyond it collapse onto reused codepoints, which just
/// degrades diff quality rather than crashing.
List<Diff> wordDiff(String oldText, String newText) {
  final tokenPattern = RegExp(r'\s+|\S+');
  final oldTokens = tokenPattern.allMatches(oldText).map((m) => m[0]!).toList();
  final newTokens = tokenPattern.allMatches(newText).map((m) => m[0]!).toList();

  final tokenToChar = <String, int>{};
  final charToToken = <String>[];

  String encode(List<String> tokens) {
    final buffer = StringBuffer();
    for (final token in tokens) {
      var code = tokenToChar[token];
      if (code == null) {
        code = charToToken.length;
        if (code < 6400) {
          tokenToChar[token] = code;
          charToToken.add(token);
        } else {
          code = 6400 - 1;
        }
      }
      buffer.writeCharCode(0xE000 + code);
    }
    return buffer.toString();
  }

  final encodedOld = encode(oldTokens);
  final encodedNew = encode(newTokens);

  final diffs = diff(encodedOld, encodedNew);
  cleanupSemantic(diffs);

  return diffs.map((d) {
    final decoded = StringBuffer();
    for (final unit in d.text.codeUnits) {
      final index = unit - 0xE000;
      if (index >= 0 && index < charToToken.length) {
        decoded.write(charToToken[index]);
      }
    }
    return Diff(d.operation, decoded.toString());
  }).toList();
}
