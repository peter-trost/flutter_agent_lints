import 'dart:convert';

/// User preferences that can be serialised to and from JSON.
class Settings {
  /// Creates a set of settings.
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
  });

  /// The account name. Never empty.
  final String username;

  /// The preferred font size, within `8..72`.
  final int fontSize;

  /// Whether the dark colour scheme is selected.
  final bool darkMode;

  /// Free-form labels. No element is empty.
  final List<String> tags;

  /// Returns a JSON-encodable representation of these settings.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'username': username,
      'fontSize': fontSize,
      'darkMode': darkMode,
      'tags': List<String>.of(tags),
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
        _sameTags(other.tags, tags);
  }

  @override
  int get hashCode =>
      Object.hash(username, fontSize, darkMode, Object.hashAll(tags));

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags)';

  static bool _sameTags(List<String> a, List<String> b) {
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

/// Thrown when a JSON document cannot be read as a [Settings].
class SettingsFormatException implements Exception {
  /// Creates an exception describing why parsing failed.
  const SettingsFormatException(this.message);

  /// A human readable description that names the offending key, if any.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Parses [json] into a [Settings].
///
/// Throws a [SettingsFormatException] if the text is not a JSON object, if a
/// required key is missing, or if a value has the wrong type or is out of
/// range. No other exception escapes this function.
Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException('invalid JSON: ${error.message}');
  }

  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'the top level value must be a JSON object',
    );
  }

  return Settings(
    username: _readUsername(decoded),
    fontSize: _readFontSize(decoded),
    darkMode: _readDarkMode(decoded),
    tags: _readTags(decoded),
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
  final value = map[key];
  if (value == null) {
    return 14;
  }
  final int size;
  if (value is int) {
    size = value;
  } else if (value is double && value == value.roundToDouble()) {
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
  final value = map[key];
  if (value == null) {
    return false;
  }
  if (value is! bool) {
    throw const SettingsFormatException('"$key" must be a boolean');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> map) {
  const key = 'tags';
  final value = map[key];
  if (value == null) {
    return const <String>[];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException('"$key" must be a list of strings');
  }
  final tags = <String>[];
  for (final element in value) {
    if (element is! String) {
      throw const SettingsFormatException('"$key" must contain only strings');
    }
    if (element.isEmpty) {
      throw const SettingsFormatException(
        '"$key" must not contain an empty string',
      );
    }
    tags.add(element);
  }
  return List<String>.unmodifiable(tags);
}
