import 'dart:convert';

/// Thrown when a settings document cannot be parsed into a [Settings].
class SettingsFormatException implements Exception {
  /// Creates an exception describing why parsing failed.
  const SettingsFormatException(this.message);

  /// Human readable description of the problem, naming the offending key.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// User preferences for the app.
class Settings {
  /// Creates a settings value.
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
    this.locale = 'en',
  });

  /// Name of the user the settings belong to. Must not be empty.
  final String username;

  /// Editor font size in logical pixels. Must be within `8..72`.
  final int fontSize;

  /// Whether the dark theme is selected.
  final bool darkMode;

  /// Free form labels. Every tag must be non-empty.
  final List<String> tags;

  /// Language tag such as `en` or `de_DE`.
  ///
  /// Two lowercase ASCII letters, optionally followed by an underscore and two
  /// uppercase ASCII letters.
  final String locale;

  /// Converts these settings into a JSON compatible map.
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

/// Parses [json] into a [Settings].
///
/// Throws a [SettingsFormatException] if the text is not a JSON object, if a
/// required key is missing, or if a value has the wrong type or is out of
/// range. No other exception type escapes this function.
Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException('invalid JSON: ${error.message}');
  }

  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException('top level value must be an object');
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
    throw const SettingsFormatException('missing required key "$key"');
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
  if (size < 8 || size > 72) {
    throw const SettingsFormatException('"$key" must be within 8..72');
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
    return const <String>[];
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
      throw const SettingsFormatException('"$key" entries must not be empty');
    }
    tags.add(entry);
  }
  return List<String>.unmodifiable(tags);
}

/// Matches `en` and `de_DE`, but not `EN`, `de-DE`, `deu` or `de_de`.
final RegExp _localePattern = RegExp(r'^[a-z]{2}(_[A-Z]{2})?$');

String _readLocale(Map<String, Object?> map) {
  const key = 'locale';
  if (!map.containsKey(key)) {
    return 'en';
  }
  final value = map[key];
  if (value is! String) {
    throw const SettingsFormatException('"$key" must be a string');
  }
  if (!_localePattern.hasMatch(value)) {
    throw const SettingsFormatException(
      '"$key" must look like "en" or "de_DE"',
    );
  }
  return value;
}
