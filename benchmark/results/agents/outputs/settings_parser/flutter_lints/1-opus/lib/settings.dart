import 'dart:convert';

/// User preferences that can be serialised to and from JSON.
class Settings {
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
  });

  /// Display name of the user. Never empty.
  final String username;

  /// Editor font size, always within [minFontSize]..[maxFontSize].
  final int fontSize;

  /// Whether the dark colour scheme is active.
  final bool darkMode;

  /// Free-form labels. Individual tags are never empty.
  final List<String> tags;

  /// Smallest accepted value for [fontSize].
  static const int minFontSize = 8;

  /// Largest accepted value for [fontSize].
  static const int maxFontSize = 72;

  /// The JSON representation understood by [parseSettings].
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
    if (other is! Settings) {
      return false;
    }
    if (other.username != username ||
        other.fontSize != fontSize ||
        other.darkMode != darkMode ||
        other.tags.length != tags.length) {
      return false;
    }
    for (var i = 0; i < tags.length; i++) {
      if (other.tags[i] != tags[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(username, fontSize, darkMode, Object.hashAll(tags));

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags)';
}

/// Thrown when a document cannot be turned into a valid [Settings].
class SettingsFormatException implements Exception {
  const SettingsFormatException(this.message);

  /// Human readable explanation naming the offending key, when there is one.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Decodes [json] into [Settings].
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
  } on Object {
    throw const SettingsFormatException('invalid JSON');
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
    throw const SettingsFormatException('"$key" is required');
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
  if (size < Settings.minFontSize || size > Settings.maxFontSize) {
    throw const SettingsFormatException(
      '"$key" must be between ${Settings.minFontSize} and '
      '${Settings.maxFontSize}',
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
    return const <String>[];
  }
  final value = map[key];
  if (value is! List) {
    throw const SettingsFormatException('"$key" must be a list of strings');
  }
  final tags = <String>[];
  for (final entry in value) {
    if (entry is! String) {
      throw const SettingsFormatException('"$key" must only contain strings');
    }
    if (entry.isEmpty) {
      throw const SettingsFormatException(
        '"$key" must not contain an empty string',
      );
    }
    tags.add(entry);
  }
  return List<String>.unmodifiable(tags);
}
