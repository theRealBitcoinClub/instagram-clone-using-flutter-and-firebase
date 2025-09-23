import 'package:flutter/material.dart';
import 'package:mahakka/tag.dart';
import 'package:mahakka/tagged_text.dart';
import 'package:mahakka/trie.dart';

class CustomFlutterTaggerController extends TextEditingController {
  CustomFlutterTaggerController({String? text}) : super(text: text);

  late final Trie trie = Trie();
  late Map<TaggedText, String> _tags;

  late Map<String, TextStyle> _tagStyles;

  void setTagStyles(Map<String, TextStyle> tagStyles) {
    _tagStyles = tagStyles;
  }

  RegExp? _triggerCharsPattern;

  RegExp get _triggerCharactersPattern => _triggerCharsPattern!;

  void setTriggerCharactersRegExpPattern(RegExp pattern) {
    _triggerCharsPattern = pattern;
    _formatTagsCallback ??= () => _formatTags(null, null);
    _formatTagsCallback?.call();
  }

  void setTags(Map<TaggedText, String> tags) {
    _tags = tags;
  }

  void setDeferCallback(Function callback) {
    _deferCallback = callback;
  }

  int _cursorposition = 0;

  int get cursorPosition => _cursorposition;

  int _getCursorPosition(int selectionOffset) {
    String subText = text.substring(0, selectionOffset);
    int offset = 0;

    for (var tag in _tags.keys) {
      if (tag.startIndex < selectionOffset && tag.endIndex <= selectionOffset) {
        final id = _tags[tag]!;
        final tagText = tag.text.substring(1);
        final triggerCharacter = tag.text[0];

        final formattedTagText = _formatTagTextCallback?.call(id, tagText, triggerCharacter);

        if (formattedTagText != null) {
          final newText = subText.replaceRange(tag.startIndex + offset, tag.endIndex + offset, formattedTagText);

          offset = newText.length - subText.length;
          subText = newText;
        }
      }
    }
    return subText.length;
  }

  @override
  set selection(TextSelection newSelection) {
    if (newSelection.isValid) {
      _cursorposition = _getCursorPosition(newSelection.baseOffset);
    } else {
      _cursorposition = _text.length;
    }
    super.selection = newSelection;
  }

  Function? _deferCallback;
  Function? _clearCallback;
  Function? _dismissOverlayCallback;
  Function(String id, String name)? _addTagCallback;
  String Function(String id, String tag, String triggerCharacter)? _formatTagTextCallback;

  String _text = "";

  String get formattedText => _text;

  Function? _formatTagsCallback;

  void formatTags({RegExp? pattern, List<String> Function(String)? parser}) {
    if (_triggerCharsPattern == null) {
      _formatTagsCallback = () => _formatTags(pattern, parser);
    } else {
      _formatTagsCallback?.call();
    }
  }

  void _formatTags([RegExp? pattern, List<String> Function(String)? parser]) {
    _clearCallback?.call();
    _text = text;
    String newText = text;

    pattern ??= RegExp(r'([@#]\w+\#.+?\#)');
    parser ??= (value) {
      final split = value.split("#");
      if (split.length == 4) {
        return [split[1].trim(), split[2].trim()];
      }
      final id = split.first.trim().replaceFirst("@", "");
      return [id, split[split.length - 2].trim()];
    };

    final matches = pattern.allMatches(text);

    int diff = 0;

    for (var match in matches) {
      try {
        final matchValue = match.group(1)!;

        final idAndTag = parser(matchValue);
        final triggerChar = text.substring(match.start, match.start + 1);

        final tag = "$triggerChar${idAndTag.last.trim()}";
        final startIndex = match.start;
        final endIndex = startIndex + tag.length;

        newText = newText.replaceRange(startIndex - diff, startIndex + matchValue.length - diff, tag);

        final taggedText = TaggedText(startIndex: startIndex - diff, endIndex: endIndex - diff, text: tag);
        _tags[taggedText] = idAndTag.first;
        trie.insert(taggedText);

        diff += matchValue.length - tag.length;
      } catch (_) {}
    }

    if (newText.isNotEmpty) {
      _runDeferedAction(() => text = newText);
      _runDeferedAction(() => selection = TextSelection.fromPosition(TextPosition(offset: newText.length)));
    }
  }

  void _runDeferedAction(Function action) {
    _deferCallback?.call();
    action.call();
  }

  @override
  void clear() {
    _clearCallback?.call();
    _text = '';
    super.clear();
  }

  void dismissOverlay() {
    _dismissOverlayCallback?.call();
  }

  void addTag({required String id, required String name}) {
    _addTagCallback?.call(id, name);
  }

  void onClear(Function callback) {
    _clearCallback = callback;
  }

  void onDismissOverlay(Function callback) {
    _dismissOverlayCallback = callback;
  }

  void onTextChanged(String newText) {
    _text = newText;
  }

  void registerAddTagCallback(Function(String id, String name) callback) {
    _addTagCallback = callback;
  }

  void registerFormatTagTextCallback(String Function(String id, String tag, String triggerCharacter) callback) {
    _formatTagTextCallback = callback;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    assert(!value.composing.isValid || !withComposing || value.isComposingRangeValid);

    return _buildTextSpan(style);
  }

  List<TextSpan> _getNestedSpans(String text, int startIndex) {
    if (text.isEmpty) return [];

    List<TextSpan> spans = [];
    int start = startIndex;

    final nestedWords = text.splitWithDelim(_triggerCharactersPattern);
    bool startsWithTrigger = text[0].contains(_triggerCharactersPattern) && nestedWords.first.isNotEmpty;

    String triggerChar = "";
    int triggerCharIndex = 0;

    for (int i = 0; i < nestedWords.length; i++) {
      final nestedWord = nestedWords[i];

      if (nestedWord.contains(_triggerCharactersPattern)) {
        if (triggerChar.isNotEmpty && triggerCharIndex == i - 2) {
          spans.add(TextSpan(text: triggerChar));
          start += triggerChar.length;
          triggerChar = "";
          triggerCharIndex = i;
          continue;
        }
        triggerChar = nestedWord;
        triggerCharIndex = i;
        continue;
      }

      String word;
      if (i == 0) {
        word = startsWithTrigger ? "$triggerChar$nestedWord" : nestedWord;
      } else {
        word = "$triggerChar$nestedWord";
      }

      TaggedText? taggedText;

      if (word.isNotEmpty) {
        taggedText = trie.search(word, start);
      }

      if (taggedText == null) {
        spans.add(TextSpan(text: word));
      } else if (taggedText.startIndex == start) {
        String suffix = word.substring(taggedText.text.length);

        spans.add(TextSpan(text: taggedText.text, style: _tagStyles[triggerChar]));
        if (suffix.isNotEmpty) spans.add(TextSpan(text: suffix));
      } else {
        spans.add(TextSpan(text: word));
      }

      start += word.length;
      triggerChar = "";
    }

    return spans;
  }

  TextSpan _buildTextSpan(TextStyle? style) {
    if (text.isEmpty) return const TextSpan();

    final splitText = text.split(" ");

    List<TextSpan> spans = [];
    int start = 0;
    int end = splitText.first.length;

    for (int i = 0; i < splitText.length; i++) {
      final currentText = splitText[i];

      if (currentText.contains(_triggerCharactersPattern)) {
        final nestedSpans = _getNestedSpans(currentText, start);
        spans.addAll(nestedSpans);
        if (i < splitText.length - 1 && splitText[i + 1].isNotEmpty) {
          spans.add(const TextSpan(text: " "));
        }

        start = end + 1;
        if (i + 1 < splitText.length) {
          end = start + splitText[i + 1].length;
        }
      } else {
        start = end + 1;
        if (i + 1 < splitText.length) {
          end = start + splitText[i + 1].length;
        }
        spans.add(TextSpan(text: "$currentText "));
      }
    }
    return TextSpan(children: spans, style: style);
  }

  List<Tag> _getTags(String text, int startIndex) {
    if (text.isEmpty) return [];
    List<Tag> result = [];
    int start = startIndex;

    final nestedWords = text.splitWithDelim(_triggerCharactersPattern);
    bool startsWithTrigger = text[0].contains(_triggerCharactersPattern) && nestedWords.first.isNotEmpty;

    String triggerChar = "";
    int triggerCharIndex = 0;

    for (int i = 0; i < nestedWords.length; i++) {
      final nestedWord = nestedWords[i];

      if (nestedWord.contains(_triggerCharactersPattern)) {
        if (triggerChar.isNotEmpty && triggerCharIndex == i - 2) {
          start += triggerChar.length;
          triggerChar = "";
          triggerCharIndex = i;
          continue;
        }
        triggerChar = nestedWord;
        triggerCharIndex = i;
        continue;
      }

      String word;
      if (i == 0) {
        word = startsWithTrigger ? "$triggerChar$nestedWord" : nestedWord;
      } else {
        word = "$triggerChar$nestedWord";
      }

      TaggedText? taggedText;

      if (word.isNotEmpty) {
        taggedText = trie.search(word, start);
      }

      if (taggedText != null && taggedText.startIndex == start) {
        final tag = Tag(id: _tags[taggedText]!, text: taggedText.text.replaceAll(triggerChar, ""), triggerCharacter: triggerChar);
        result.add(tag);
      }

      start += word.length;
      triggerChar = "";
    }

    return result;
  }

  Iterable<Tag> get tags {
    if (text.isEmpty) return [];

    final splitText = text.split(" ");

    List<Tag> result = [];
    int start = 0;
    int end = splitText.first.length;
    int length = splitText.length;

    for (int i = 0; i < length; i++) {
      final text = splitText[i];

      if (text.contains(_triggerCharactersPattern)) {
        final tags = _getTags(text, start);
        result.addAll(tags);
      }

      start = end + 1;
      if (i + 1 < length) {
        end = start + splitText[i + 1].length;
      }
    }

    return result;
  }
}

extension _RegExpExtension on RegExp {
  List<String> allMatchesWithSep(String input, [int start = 0]) {
    var result = <String>[];
    for (var match in allMatches(input, start)) {
      result.add(input.substring(start, match.start));
      result.add(match[0]!);
      start = match.end;
    }
    result.add(input.substring(start));
    return result;
  }
}

extension _StringExtension on String {
  List<String> splitWithDelim(RegExp pattern) => pattern.allMatchesWithSep(this);
}
