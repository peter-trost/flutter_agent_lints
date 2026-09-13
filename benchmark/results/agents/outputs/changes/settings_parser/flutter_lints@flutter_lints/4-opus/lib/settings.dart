import 'dart:convert';

/// User-facing configuration that can be serialised to and from JSON.
class Settings {
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
    this.locale = 'en',
  });

  /// The account name. Never empty.
  final String username;

  /// The editor font size, always within [minFontSize] .. [maxFontSize].
  final int fontSize;

  /// Whether the dark colour scheme is selected.
  final bool darkMode;

  /// Free-form labels. Never contains an empty entry.
  final List<String> tags;

  /// The language tag, always matching [localePattern].
  final String locale;

  /// Smallest accepted value for [fontSize].
  static const int minFontSize = 8;

  /// Largest accepted value for [fontSize].
  static const int maxFontSize = 72;

  /// The shape accepted for [locale]: two lowercase letters, optionally
  /// followed by an underscore and two uppercase letters.
  static final RegExp localePattern = RegExp(r'^[a-z]{2}(_[A-Z]{2})?$');

  /// The JSON representation understood by [parseSettings].
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'username': username,
      'fontSize': fontSize,
      'darkMode': darkMode,
      'tags': List<String>.of(tags),
      'locale': locale,
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

/// Thrown when a JSON document cannot be turned into a [Settings].
class SettingsFormatException implements Exception {
  const SettingsFormatException(this.message);

  /// Human readable description of the problem.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
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
    throw SettingsFormatException('not valid JSON: ${error.message}');
  }

  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException('top level value is not a JSON object');
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
    throw const SettingsFormatException('key "$key" must be a string');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('key "$key" must not be empty');
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
  } else if (value is double) {
    if (!value.isFinite || value != value.roundToDouble()) {
      throw const SettingsFormatException('key "$key" must be an integer');
    }
    size = value.toInt();
  } else {
    throw const SettingsFormatException('key "$key" must be an integer');
  }
  if (size < Settings.minFontSize || size > Settings.maxFontSize) {
    throw const SettingsFormatException(
      'key "$key" must be between ${Settings.minFontSize} '
      'and ${Settings.maxFontSize}',
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
    throw const SettingsFormatException('key "$key" must be a boolean');
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
    throw const SettingsFormatException('key "$key" must be a list of strings');
  }
  final tags = <String>[];
  for (final entry in value) {
    if (entry is! String) {
      throw const SettingsFormatException(
        'key "$key" must contain only strings',
      );
    }
    if (entry.isEmpty) {
      throw const SettingsFormatException(
        'key "$key" must not contain empty strings',
      );
    }
    tags.add(entry);
  }
  return List<String>.unmodifiable(tags);
}

String _readLocale(Map<String, Object?> map) {
  const key = 'locale';
  if (!map.containsKey(key)) {
    return 'en';
  }
  final value = map[key];
  if (value is! String) {
    throw const SettingsFormatException('key "$key" must be a string');
  }
  if (!Settings.localePattern.hasMatch(value)) {
    throw const SettingsFormatException(
      'key "$key" must be a language code such as "en" or "de_DE"',
    );
  }
  return value;
}
