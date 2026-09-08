import 'dart:convert';

/// User preferences for the app.
///
/// The invariants documented on each field are enforced by [parseSettings];
/// values built in code are trusted.
class Settings {
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
  });

  /// The account name. Never empty.
  final String username;

  /// The editor font size, between [minFontSize] and [maxFontSize] inclusive.
  final int fontSize;

  /// Whether the dark theme is selected.
  final bool darkMode;

  /// Free-form labels. Never contains an empty tag.
  final List<String> tags;

  /// The smallest accepted [fontSize].
  static const int minFontSize = 8;

  /// The largest accepted [fontSize].
  static const int maxFontSize = 72;

  /// A JSON representation that [parseSettings] reads back into an equal value.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      _usernameKey: username,
      _fontSizeKey: fontSize,
      _darkModeKey: darkMode,
      _tagsKey: List<String>.of(tags),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Settings &&
        other.username == username &&
        other.fontSize == fontSize &&
        other.darkMode == darkMode &&
        _tagsEqual(other.tags, tags);
  }

  @override
  int get hashCode =>
      Object.hash(username, fontSize, darkMode, Object.hashAll(tags));

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags)';
}

/// Thrown by [parseSettings] when a document cannot be read as [Settings].
///
/// The [message] names the offending key whenever one can be identified.
class SettingsFormatException implements Exception {
  const SettingsFormatException(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

const String _usernameKey = 'username';
const String _fontSizeKey = 'fontSize';
const String _darkModeKey = 'darkMode';
const String _tagsKey = 'tags';

/// Reads a [Settings] value from a JSON document.
///
/// Throws a [SettingsFormatException] — and nothing else — when [json] is not
/// valid JSON, when its top level is not an object, or when a key is missing,
/// has the wrong type, or falls outside its accepted range. Keys other than
/// `username`, `fontSize`, `darkMode` and `tags` are ignored.
Settings parseSettings(String json) {
  final Object? decoded = _decode(json);
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'The top level of the document must be a JSON object.',
    );
  }
  return Settings(
    username: _readUsername(decoded),
    fontSize: _readFontSize(decoded),
    darkMode: _readDarkMode(decoded),
    tags: _readTags(decoded),
  );
}

Object? _decode(String json) {
  try {
    return jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException(
      'The document is not valid JSON: '
      '${error.message}',
    );
  }
}

String _readUsername(Map<String, Object?> json) {
  final Object? value = json[_usernameKey];
  if (value == null) {
    throw const SettingsFormatException(
      'The required key "$_usernameKey" is missing.',
    );
  }
  if (value is! String) {
    throw const SettingsFormatException(
      'The key "$_usernameKey" must hold a string.',
    );
  }
  if (value.isEmpty) {
    throw const SettingsFormatException(
      'The key "$_usernameKey" must not be empty.',
    );
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  if (!json.containsKey(_fontSizeKey)) {
    return 14;
  }
  final Object? value = json[_fontSizeKey];
  final int fontSize;
  if (value is int) {
    fontSize = value;
  } else if (value is double &&
      value.isFinite &&
      value == value.roundToDouble()) {
    fontSize = value.toInt();
  } else {
    throw const SettingsFormatException(
      'The key "$_fontSizeKey" must hold a whole number.',
    );
  }
  if (fontSize < Settings.minFontSize || fontSize > Settings.maxFontSize) {
    throw const SettingsFormatException(
      'The key "$_fontSizeKey" must be between ${Settings.minFontSize} and '
      '${Settings.maxFontSize}.',
    );
  }
  return fontSize;
}

bool _readDarkMode(Map<String, Object?> json) {
  if (!json.containsKey(_darkModeKey)) {
    return false;
  }
  final Object? value = json[_darkModeKey];
  if (value is! bool) {
    throw const SettingsFormatException(
      'The key "$_darkModeKey" must hold a boolean.',
    );
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  if (!json.containsKey(_tagsKey)) {
    return const <String>[];
  }
  final Object? value = json[_tagsKey];
  if (value is! List<Object?>) {
    throw const SettingsFormatException(
      'The key "$_tagsKey" must hold a list of strings.',
    );
  }
  final List<String> tags = <String>[];
  for (final Object? element in value) {
    if (element is! String) {
      throw const SettingsFormatException(
        'The key "$_tagsKey" must hold a list of strings.',
      );
    }
    if (element.isEmpty) {
      throw const SettingsFormatException(
        'The key "$_tagsKey" must not contain an empty tag.',
      );
    }
    tags.add(element);
  }
  return List<String>.unmodifiable(tags);
}

bool _tagsEqual(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
