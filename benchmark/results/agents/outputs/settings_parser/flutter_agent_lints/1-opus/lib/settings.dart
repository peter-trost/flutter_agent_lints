import 'dart:convert';

import 'package:flutter/foundation.dart';

const _minFontSize = 8;
const _maxFontSize = 72;

/// User preferences that survive a round trip through JSON.
@immutable
class Settings {
  const new({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
  });

  final String username;
  final int fontSize;
  final bool darkMode;
  final List<String> tags;

  Map<String, Object?> toJson() => {
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

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags)';
}

/// Thrown by [parseSettings] for any input it cannot turn into [Settings].
class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Parses a JSON object into [Settings].
///
/// Throws a [SettingsFormatException] when [json] is not a JSON object, when a
/// required key is missing, or when a value has the wrong type or lies outside
/// its range. Unknown keys are ignored.
Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json) as Object?;
  } on FormatException catch (error) {
    throw SettingsFormatException('not valid JSON: ${error.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException('the top level is not a JSON object');
  }
  return Settings(
    username: _username(decoded),
    fontSize: _fontSize(decoded),
    darkMode: _darkMode(decoded),
    tags: _tags(decoded),
  );
}

String _username(Map<String, Object?> map) {
  final value = map['username'];
  if (value is! String) {
    throw const SettingsFormatException('username must be a string');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('username must not be empty');
  }
  return value;
}

int _fontSize(Map<String, Object?> map) {
  if (!map.containsKey('fontSize')) {
    return 14;
  }
  final value = map['fontSize'];
  if (value is! int) {
    throw const SettingsFormatException('fontSize must be a whole number');
  }
  if (value < _minFontSize || value > _maxFontSize) {
    throw const SettingsFormatException(
      'fontSize must be between $_minFontSize and $_maxFontSize',
    );
  }
  return value;
}

bool _darkMode(Map<String, Object?> map) {
  if (!map.containsKey('darkMode')) {
    return false;
  }
  final value = map['darkMode'];
  if (value is! bool) {
    throw const SettingsFormatException('darkMode must be a boolean');
  }
  return value;
}

List<String> _tags(Map<String, Object?> map) {
  if (!map.containsKey('tags')) {
    return const [];
  }
  final value = map['tags'];
  if (value is! List<Object?>) {
    throw const SettingsFormatException('tags must be a list of strings');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException('tags must contain only strings');
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException('tags must not contain empty tags');
    }
    tags.add(tag);
  }
  return List.unmodifiable(tags);
}
