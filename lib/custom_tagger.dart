import 'package:flutter/material.dart';
import 'package:mahakka/tagged_text.dart';
import 'package:mahakka/trie.dart';

import 'custom_flutter_tagger_controller.dart';

typedef FlutterTaggerWidgetBuilder = Widget Function(BuildContext context, GlobalKey key);

typedef TagTextFormatter = String Function(String id, String tag, String triggerCharacter);

typedef FlutterTaggerSearchCallback = void Function(String query, String triggerCharacter);

enum OverlayPosition { top, bottom }

enum TriggerStrategy { eager, deferred }

class CustomFlutterTagger extends StatefulWidget {
  const CustomFlutterTagger({
    Key? key,
    required this.overlay,
    required this.controller,
    required this.onSearch,
    required this.builder,
    this.padding = EdgeInsets.zero,
    this.overlayHeight = 200,
    this.triggerCharacterAndStyles = const {},
    this.overlayPosition = OverlayPosition.top,
    this.triggerStrategy = TriggerStrategy.deferred,
    this.onFormattedTextChanged,
    this.searchRegex,
    this.triggerCharactersRegex,
    this.tagTextFormatter,
    this.animationController,
  }) : assert(triggerCharacterAndStyles != const {}, "triggerCharacterAndStyles cannot be empty"),
       super(key: key);

  final Widget overlay;
  final EdgeInsetsGeometry padding;
  final double overlayHeight;
  final TagTextFormatter? tagTextFormatter;
  final CustomFlutterTaggerController controller;
  final void Function(String)? onFormattedTextChanged;
  final FlutterTaggerSearchCallback onSearch;
  final FlutterTaggerWidgetBuilder builder;
  final RegExp? searchRegex;
  final RegExp? triggerCharactersRegex;
  final AnimationController? animationController;
  final Map<String, TextStyle> triggerCharacterAndStyles;
  final OverlayPosition overlayPosition;
  final TriggerStrategy triggerStrategy;

  @override
  State<CustomFlutterTagger> createState() => _CustomFlutterTaggerState();
}

class _CustomFlutterTaggerState extends State<CustomFlutterTagger> {
  CustomFlutterTaggerController get controller => widget.controller;

  late final _textFieldKey = GlobalKey(debugLabel: "FlutterTagger's child TextField key");

  late bool _hideOverlay = false;

  String _formatTagText(String id, String tag, String triggerCharacter) {
    return widget.tagTextFormatter?.call(id, tag, triggerCharacter) ?? "@$id#$tag#";
  }

  void _onFormattedTextChanged() {
    controller.onTextChanged(_formattedText);
    widget.onFormattedTextChanged?.call(_formattedText);
  }

  void _shouldHideOverlay(bool val) {
    try {
      if (_hideOverlay == val) return;
      _hideOverlay = val;
      if (_hideOverlay) {
        widget.animationController?.reverse();
      } else {
        widget.animationController?.forward();
      }
    } catch (_) {}
  }

  void _animationControllerListener() {
    if (widget.animationController?.status == AnimationStatus.dismissed) {
      setState(() {
        _hideOverlay = true;
      });
    }
  }

  late Trie _tagTrie;
  late final Map<TaggedText, String> _tags = {};

  Iterable<String> get triggerCharacters => widget.triggerCharacterAndStyles.keys;

  RegExp get _triggerCharactersPattern {
    if (widget.triggerCharactersRegex != null) {
      return widget.triggerCharactersRegex!;
    }
    String pattern = triggerCharacters.first;
    int count = triggerCharacters.length;

    if (count > 1) {
      for (int i = 1; i < count; i++) {
        pattern += "|${triggerCharacters.elementAt(i)}";
      }
    }

    return RegExp(pattern);
  }

  String _parseAndFormatNestedTags(String text, int startIndex) {
    if (text.isEmpty) return "";
    List<String> result = [];
    int start = startIndex;

    final nestedWords = text.splitWithDelim(_triggerCharactersPattern);
    bool startsWithTrigger = triggerCharacters.contains(text[0]) && nestedWords.first.isNotEmpty;

    String triggerChar = "";
    int triggerCharIndex = 0;

    for (int i = 0; i < nestedWords.length; i++) {
      final nestedWord = nestedWords[i];

      if (nestedWord.contains(_triggerCharactersPattern)) {
        if (triggerChar.isNotEmpty && triggerCharIndex == i - 2) {
          result.add(triggerChar);
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
        taggedText = _tagTrie.search(word, start);
      }

      if (taggedText == null) {
        result.add(word);
      } else if (taggedText.startIndex == start) {
        String suffix = word.substring(taggedText.text.length);
        String formattedTagText = taggedText.text.replaceAll(triggerChar, "");
        formattedTagText = _formatTagText(_tags[taggedText]!, formattedTagText, triggerChar);

        result.add(formattedTagText);
        if (suffix.isNotEmpty) result.add(suffix);
      } else {
        result.add(word);
      }

      start += word.length;
      triggerChar = "";
    }

    return result.join("");
  }

  String get _formattedText {
    String controllerText = controller.text;

    if (controllerText.isEmpty) return "";

    final splitText = controllerText.split(" ");

    List<String> result = [];
    int start = 0;
    int end = splitText.first.length;
    int length = splitText.length;

    for (int i = 0; i < length; i++) {
      final text = splitText[i];

      if (text.contains(_triggerCharactersPattern)) {
        final parsedText = _parseAndFormatNestedTags(text, start);
        result.add(parsedText);
      } else {
        result.add(text);
      }

      start = end + 1;
      if (i + 1 < length) {
        end = start + splitText[i + 1].length;
      }
    }

    final resultString = result.join(" ");

    return resultString;
  }

  bool _defer = false;
  TaggedText? _selectedTag;

  void _addTag(String id, String tag) {
    _shouldSearch = false;
    _shouldHideOverlay(true);

    tag = "$_currentTriggerChar${tag.trim()}";
    id = id.trim();

    final text = controller.text;
    late final position = controller.selection.base.offset - 1;
    int index = 0;
    int selectionOffset = 0;

    if (position != text.length - 1) {
      index = text.substring(0, position + 1).lastIndexOf(_currentTriggerChar);
    } else {
      index = text.lastIndexOf(_currentTriggerChar);
    }

    if (index >= 0) {
      _defer = true;

      String newText;

      if (index - 1 > 0 && text[index - 1] != " ") {
        newText = text.replaceRange(index, position + 1, " $tag");
        index++;
      } else {
        newText = text.replaceRange(index, position + 1, tag);
      }

      if (text.length - 1 == position) {
        newText += " ";
        selectionOffset++;
      }

      final oldCachedText = _lastCachedText;
      _lastCachedText = newText;
      controller.text = newText;
      _defer = true;

      int offset = index + tag.length;

      final taggedText = TaggedText(startIndex: offset - tag.length, endIndex: offset, text: tag);
      _tags[taggedText] = id;
      _tagTrie.insert(taggedText);

      controller.selection = TextSelection.fromPosition(TextPosition(offset: offset + selectionOffset));

      _recomputeTags(oldCachedText, newText, taggedText.startIndex + 1);

      _onFormattedTextChanged();
    }
  }

  bool _removeEditedTags() {
    try {
      final text = controller.text;
      if (_isTagSelected) {
        _removeSelection();
        return true;
      }
      if (text.isEmpty) {
        _tags.clear();
        _tagTrie.clear();
        _lastCachedText = text;
        return false;
      }
      final position = controller.selection.base.offset - 1;
      if (position >= 0 && triggerCharacters.contains(text[position])) {
        _shouldSearch = true;
        return false;
      }

      for (var tag in _tags.keys) {
        if (tag.endIndex - 1 == position + 1) {
          if (!_isTagSelected) {
            if (_backtrackAndSelect(tag)) return true;
          }
        }
      }
    } catch (_, trace) {
      debugPrint(trace.toString());
    }
    _lastCachedText = controller.text;
    _defer = false;
    return false;
  }

  bool _backtrackAndSelect(TaggedText tag) {
    String text = controller.text;
    if (!text.contains(_triggerCharactersPattern)) return false;

    final length = controller.selection.base.offset;

    if (tag.startIndex > length || tag.endIndex - 1 > length) {
      return false;
    }
    _defer = true;
    controller.text = _lastCachedText;
    text = _lastCachedText;
    _defer = true;
    controller.selection = TextSelection.fromPosition(TextPosition(offset: length));

    late String temp = "";

    for (int i = length; i >= 0; i--) {
      if (i == length && triggerCharacters.contains(text[i])) return false;

      temp = text[i] + temp;
      if (triggerCharacters.contains(text[i]) && temp.length > 1 && temp == tag.text && i == tag.startIndex) {
        _selectedTag = TaggedText(startIndex: i, endIndex: length + 1, text: tag.text);
        _isTagSelected = true;
        _startOffset = i;
        _endOffset = length + 1;
        _defer = true;
        controller.selection = TextSelection(baseOffset: _startOffset!, extentOffset: _endOffset!);
        return true;
      }
    }

    return false;
  }

  void _removeSelection() {
    _tags.remove(_selectedTag);
    _tagTrie.clear();
    _tagTrie.insertAll(_tags.keys);
    _selectedTag = null;
    final oldCachedText = _lastCachedText;
    _lastCachedText = controller.text;

    final pos = _startOffset!;
    _startOffset = null;
    _endOffset = null;
    _isTagSelected = false;

    _recomputeTags(oldCachedText, _lastCachedText, pos);
    _onFormattedTextChanged();
  }

  bool _isTagSelected = false;
  int? _startOffset;
  int? _endOffset;
  String _lastCachedText = "";
  bool _shouldSearch = false;
  late final _searchRegexPattern = widget.searchRegex ?? RegExp(r'^[a-zA-Z-]*$');
  int _lastCursorPosition = 0;
  bool _isBacktrackingToSearch = false;
  String _currentTriggerChar = "";

  bool _backtrackAndSearch() {
    String text = controller.text;
    if (!text.contains(_triggerCharactersPattern)) return false;

    _lastCachedText = text;
    final length = controller.selection.base.offset - 1;

    for (int i = length; i >= 0; i--) {
      if ((i == length && triggerCharacters.contains(text[i])) ||
          !triggerCharacters.contains(text[i]) && !_searchRegexPattern.hasMatch(text[i])) {
        return false;
      }

      if (triggerCharacters.contains(text[i])) {
        final doesTagExistInRange = _tags.keys.any((tag) => tag.startIndex == i && tag.endIndex == length + 1);

        if (doesTagExistInRange) return false;

        _currentTriggerChar = text[i];
        _shouldSearch = true;
        _isTagSelected = false;
        _isBacktrackingToSearch = true;
        if (text.isNotEmpty) {
          _extractAndSearch(text, length);
        }

        return true;
      }
    }

    _isBacktrackingToSearch = false;
    return false;
  }

  void _tagListener() {
    final currentCursorPosition = controller.selection.baseOffset;
    final text = controller.text;

    if (_shouldSearch &&
        _isBacktrackingToSearch &&
        ((text.trim().length < _lastCachedText.trim().length && _lastCursorPosition - 1 != currentCursorPosition) ||
            _lastCursorPosition + 1 != currentCursorPosition)) {
      _shouldSearch = false;
      _isBacktrackingToSearch = false;
      _shouldHideOverlay(true);
    }

    if (_defer) {
      _lastCachedText = text;
      _defer = false;

      int position = currentCursorPosition - 1;
      if (position >= 0 && triggerCharacters.contains(text[position])) {
        _shouldSearch = true;
        _currentTriggerChar = text[position];
        if (widget.triggerStrategy == TriggerStrategy.eager) {
          _extractAndSearch(text, position);
        }
      }
      _onFormattedTextChanged();
      return;
    }

    _lastCursorPosition = currentCursorPosition;

    if (text.isEmpty && _selectedTag != null) {
      _removeSelection();
    }

    if (_startOffset != null && currentCursorPosition != _startOffset) {
      _selectedTag = null;
      _startOffset = null;
      _endOffset = null;
      _isTagSelected = false;
    }

    final position = currentCursorPosition - 1;
    final oldCachedText = _lastCachedText;

    if (_shouldSearch && position >= 0) {
      if (!_searchRegexPattern.hasMatch(text[position])) {
        _shouldSearch = false;
        _shouldHideOverlay(true);
      } else {
        _extractAndSearch(text, position);
        _recomputeTags(oldCachedText, text, position);
        _lastCachedText = text;
        return;
      }
    }

    if (_lastCachedText == text) {
      if (position >= 0 && triggerCharacters.contains(text[position])) {
        _shouldSearch = true;
        _currentTriggerChar = text[position];
        if (widget.triggerStrategy == TriggerStrategy.eager) {
          _extractAndSearch(text, position);
        }
      }
      _recomputeTags(oldCachedText, text, position);
      _onFormattedTextChanged();
      return;
    }

    if (_lastCachedText.length > text.length || currentCursorPosition < text.length) {
      if (_removeEditedTags()) {
        _shouldHideOverlay(true);
        _onFormattedTextChanged();
        return;
      }

      final hideOverlay = !_backtrackAndSearch();
      if (hideOverlay) _shouldHideOverlay(true);

      if (position < 0 || !triggerCharacters.contains(text[position])) {
        _recomputeTags(oldCachedText, text, position);
        _onFormattedTextChanged();
        return;
      }
    }

    _lastCachedText = text;

    if (position >= 0 && triggerCharacters.contains(text[position])) {
      _shouldSearch = true;
      _currentTriggerChar = text[position];
      if (widget.triggerStrategy == TriggerStrategy.eager) {
        _extractAndSearch(text, position);
      }
      _recomputeTags(oldCachedText, text, position);
      _onFormattedTextChanged();
      return;
    }

    if (position >= 0 && !_searchRegexPattern.hasMatch(text[position])) {
      _shouldSearch = false;
    }

    if (_shouldSearch && text.isNotEmpty) {
      _extractAndSearch(text, position);
    } else {
      _shouldHideOverlay(true);
    }

    _recomputeTags(oldCachedText, text, position);
    _onFormattedTextChanged();
  }

  void _recomputeTags(String oldCachedText, String currentText, int position) {
    final currentCursorPosition = controller.selection.baseOffset;
    if (currentCursorPosition != currentText.length) {
      Map<TaggedText, String> newTable = {};
      _tagTrie.clear();

      for (var tag in _tags.keys) {
        if (tag.startIndex >= position) {
          final newTag = TaggedText(
            startIndex: tag.startIndex + currentText.length - oldCachedText.length,
            endIndex: tag.endIndex + currentText.length - oldCachedText.length,
            text: tag.text,
          );

          _tagTrie.insert(newTag);
          newTable[newTag] = _tags[tag]!;
        } else {
          _tagTrie.insert(tag);
          newTable[tag] = _tags[tag]!;
        }
      }

      _tags.clear();
      _tags.addAll(newTable);
    }
  }

  void _extractAndSearch(String text, int endOffset) {
    try {
      int index = text.substring(0, endOffset + 1).lastIndexOf(_currentTriggerChar);

      if (index < 0) return;

      final query = text.substring(index + 1, endOffset + 1);

      _shouldHideOverlay(false);
      widget.onSearch(query, _currentTriggerChar);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _tagTrie = controller.trie;
    controller.setDeferCallback(() => _defer = true);
    controller.setTags(_tags);
    controller.setTagStyles(widget.triggerCharacterAndStyles);
    controller.setTriggerCharactersRegExpPattern(_triggerCharactersPattern);
    controller.registerFormatTagTextCallback(_formatTagText);
    controller.addListener(_tagListener);
    controller.onClear(() {
      _tags.clear();
      _tagTrie.clear();
    });
    controller.onDismissOverlay(() {
      _shouldHideOverlay(true);
    });
    controller.registerAddTagCallback(_addTag);
    widget.animationController?.addListener(_animationControllerListener);
  }

  @override
  void dispose() {
    controller.removeListener(_tagListener);
    widget.animationController?.removeListener(_animationControllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: Column(
        children: [
          // if (!_hideOverlay)
          Container(height: 130, child: widget.overlay),
          Container(height: 140, padding: widget.padding, child: widget.builder(context, _textFieldKey)),
        ],
      ),
    );
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
