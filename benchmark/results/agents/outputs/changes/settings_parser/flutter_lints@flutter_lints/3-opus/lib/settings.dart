import 'dart:convert';

/// Smallest accepted value for [Settings.fontSize].
const int _minFontSize = 8;

/// Largest accepted value for [Settings.fontSize].
const int _maxFontSize = 72;

/// Value used for [Settings.locale] when the key is absent.
const String _defaultLocale = 'en';

/// Matches a language code, optionally followed by an upper case region.
final RegExp _localePattern = RegExp(r'^[a-z]{2}(_[A-Z]{2})?$');

/// User preferences that can be stored as, and restored from, JSON.
class Settings {
  /// Creates a settings snapshot.
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
    this.locale = _defaultLocale,
  });

  /// Name of the user owning these settings. Never empty.
  final String username;

  /// Editor font size, always within 8..72 inclusive.
  final int fontSize;

  /// Whether the dark colour scheme is preferred.
  final bool darkMode;

  /// Free-form labels attached to the user. No tag is empty.
  final List<String> tags;

  /// Preferred locale, as two lower case letters optionally followed by an
  /// underscore and two upper case letters, such as `en` or `de_DE`.
  final String locale;

  /// Returns a JSON-encodable representation of these settings.
  Map<String, Object?> toJson() => <String, Object?>{
    'username': username,
    'fontSize': fontSize,
    'darkMode': darkMode,
    'tags': List<String>.of(tags),
    'locale': locale,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Settings &&
        other.username == username &&
        other.fontSize == fontSize &&
        other.darkMode == darkMode &&
        other.locale == locale &&
        _tagsEqual(other.tags, tags);
  }

  @override
  int get hashCode =>
      Object.hash(username, fontSize, darkMode, Object.hashAll(tags), locale);

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags, locale: $locale)';

  static bool _tagsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Thrown when a JSON document cannot be read as a [Settings] value.
class SettingsFormatException implements Exception {
  /// Creates an exception describing why parsing failed.
  const SettingsFormatException(this.message);

  /// Human readable description of the problem. Mentions the offending key
  /// when the failure can be attributed to one.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Parses [json] into a [Settings] value.
///
/// Throws a [SettingsFormatException] if the text is not a JSON object, if a
/// required key is missing, or if any known key holds a value of the wrong
/// type or outside its allowed range. No other exception type escapes.
Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on Object {
    throw const SettingsFormatException('the text is not valid JSON');
  }
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'the top level of the document is not a JSON object',
    );
  }
  return Settings(
    username: _readUsername(decoded),
    fontSize: _readFontSize(decoded),
    darkMode: _readDarkMode(decoded),
    tags: _readTags(decoded),
    locale: _readLocale(decoded),
  );
}

String _readUsername(Map<String, Object?> map) {
  const key = 'username';
  if (!map.containsKey(key)) {
    throw const SettingsFormatException('"$key" is required but missing');
  }
  final value = map[key];
  if (value is! String) {
    throw const SettingsFormatException('"$key" must be a string');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('"$key" must not be empty');
  }
  return value;
}

int _readFontSize(Map<String, Object?> map) {
  const key = 'fontSize';
  if (!map.containsKey(key)) {
    return 14;
  }
  final value = map[key];
  final int size;
  if (value is int) {
    size = value;
  } else if (value is double &&
      value.isFinite &&
      value == value.roundToDouble()) {
    size = value.toInt();
  } else {
    throw const SettingsFormatException('"$key" must be an integer');
  }
  if (size < _minFontSize || size > _maxFontSize) {
    throw const SettingsFormatException(
      '"$key" must be within $_minFontSize..$_maxFontSize',
    );
  }
  return size;
}

bool _readDarkMode(Map<String, Object?> map) {
  const key = 'darkMode';
  if (!map.containsKey(key)) {
    return false;
  }
  final value = map[key];
  if (value is! bool) {
    throw const SettingsFormatException('"$key" must be a boolean');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> map) {
  const key = 'tags';
  if (!map.containsKey(key)) {
    return const [];
  }
  final value = map[key];
  if (value is! List<Object?>) {
    throw const SettingsFormatException('"$key" must be a list of strings');
  }
  final tags = <String>[];
  for (final entry in value) {
    if (entry is! String) {
      throw const SettingsFormatException('"$key" must contain only strings');
    }
    if (entry.isEmpty) {
      throw const SettingsFormatException('"$key" must not contain empty tags');
    }
    tags.add(entry);
  }
  return tags;
}

String _readLocale(Map<String, Object?> map) {
  const key = 'locale';
  if (!map.containsKey(key)) {
    return _defaultLocale;
  }
  final value = map[key];
  if (value is! String) {
    throw const SettingsFormatException('"$key" must be a string');
  }
  if (!_localePattern.hasMatch(value)) {
    throw const SettingsFormatException(
      '"$key" must be a language code such as "en" or "de_DE"',
    );
  }
  return value;
}
