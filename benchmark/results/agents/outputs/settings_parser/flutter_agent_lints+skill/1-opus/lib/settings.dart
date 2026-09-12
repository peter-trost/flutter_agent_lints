import 'dart:convert';

import 'package:flutter/foundation.dart';

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

  Map<String, Object?> toJson() => <String, Object?>{
    'username': username,
    'fontSize': fontSize,
    'darkMode': darkMode,
    'tags': tags,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
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

class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json) as Object?;
  } on FormatException catch (error) {
    throw SettingsFormatException('not valid JSON: ${error.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'the top level value must be a JSON object',
    );
  }
  return Settings(
    username: _username(decoded['username']),
    fontSize: _fontSize(decoded['fontSize']),
    darkMode: _darkMode(decoded['darkMode']),
    tags: _tags(decoded['tags']),
  );
}

String _username(Object? value) {
  if (value is! String) {
    throw const SettingsFormatException('username must be a string');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('username must not be empty');
  }
  return value;
}

int _fontSize(Object? value) {
  if (value == null) {
    return 14;
  }
  if (value is! num) {
    throw const SettingsFormatException('fontSize must be an integer');
  }
  final truncated = value.toInt();
  if (truncated != value) {
    throw const SettingsFormatException(
      'fontSize must be a whole number without a fractional part',
    );
  }
  if (truncated < 8 || truncated > 72) {
    throw const SettingsFormatException(
      'fontSize must be between 8 and 72 inclusive',
    );
  }
  return truncated;
}

bool _darkMode(Object? value) {
  if (value == null) {
    return false;
  }
  if (value is! bool) {
    throw const SettingsFormatException('darkMode must be a boolean');
  }
  return value;
}

List<String> _tags(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException('tags must be a list of strings');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException('tags must contain strings only');
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException('tags must not contain an empty tag');
    }
    tags.add(tag);
  }
  return List<String>.unmodifiable(tags);
}
