import 'dart:convert';

import 'package:flutter/foundation.dart';

const _defaultFontSize = 14;
const _minFontSize = 8;
const _maxFontSize = 72;

/// Thrown when a settings document cannot be turned into a [Settings].
///
/// The [message] always names the offending key when one can be blamed.
class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// User preferences, as stored in a JSON document.
@immutable
class Settings {
  const new({
    required this.username,
    this.fontSize = _defaultFontSize,
    this.darkMode = false,
    this.tags = const [],
  });

  final String username;
  final int fontSize;
  final bool darkMode;
  final List<String> tags;

  Map<String, Object?> toJson() => <String, Object?>{
    'username': username,
    'fontSize': fontSize,
    'darkMode': darkMode,
    'tags': tags,
  };

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.username == username &&
      other.fontSize == fontSize &&
      other.darkMode == darkMode &&
      listEquals(other.tags, tags);

  @override
  int get hashCode =>
      Object.hash(username, fontSize, darkMode, Object.hashAll(tags));
}

/// Parses [json] into a [Settings].
///
/// Throws a [SettingsFormatException], and nothing else, for any document
/// that is not a settings object.
Settings parseSettings(String json) {
  final decoded = _decode(json);
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

Object? _decode(String json) {
  try {
    return jsonDecode(json) as Object?;
  } on FormatException catch (error) {
    throw SettingsFormatException('not valid JSON: ${error.message}');
  }
}

String _readUsername(Map<String, Object?> json) {
  final value = json['username'];
  if (value == null) {
    throw const SettingsFormatException("'username' is required");
  }
  if (value is! String) {
    throw const SettingsFormatException("'username' must be a string");
  }
  if (value.isEmpty) {
    throw const SettingsFormatException("'username' must not be empty");
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  if (!json.containsKey('fontSize')) {
    return _defaultFontSize;
  }
  final value = json['fontSize'];
  if (value is! int) {
    throw const SettingsFormatException(
      "'fontSize' must be an integer without a fractional part",
    );
  }
  if (value < _minFontSize || value > _maxFontSize) {
    throw const SettingsFormatException(
      "'fontSize' must be between $_minFontSize and $_maxFontSize",
    );
  }
  return value;
}

bool _readDarkMode(Map<String, Object?> json) {
  if (!json.containsKey('darkMode')) {
    return false;
  }
  final value = json['darkMode'];
  if (value is! bool) {
    throw const SettingsFormatException("'darkMode' must be a boolean");
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  if (!json.containsKey('tags')) {
    return const [];
  }
  final value = json['tags'];
  if (value is! List<Object?>) {
    throw const SettingsFormatException("'tags' must be a list");
  }
  final tags = <String>[];
  for (final entry in value) {
    if (entry is! String) {
      throw const SettingsFormatException("'tags' must contain only strings");
    }
    if (entry.isEmpty) {
      throw const SettingsFormatException(
        "'tags' must not contain an empty string",
      );
    }
    tags.add(entry);
  }
  return List<String>.unmodifiable(tags);
}
