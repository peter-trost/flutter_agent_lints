import 'dart:convert';

import 'package:flutter/foundation.dart';

const _minFontSize = 8;
const _maxFontSize = 72;
const _defaultFontSize = 14;

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

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags)';
}

/// Thrown by [parseSettings] for every input it refuses.
class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Reads a [Settings] from a JSON object, throwing
/// [SettingsFormatException] for anything else.
Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException('Not valid JSON: ${error.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'The top level value must be a JSON object.',
    );
  }
  return Settings(
    username: _parseUsername(decoded),
    fontSize: _parseFontSize(decoded),
    darkMode: _parseDarkMode(decoded),
    tags: _parseTags(decoded),
  );
}

String _parseUsername(Map<String, Object?> json) {
  final value = json['username'];
  if (value is! String) {
    throw const SettingsFormatException("Key 'username' must be a string.");
  }
  if (value.isEmpty) {
    throw const SettingsFormatException("Key 'username' must not be empty.");
  }
  return value;
}

int _parseFontSize(Map<String, Object?> json) {
  final value = json['fontSize'];
  if (value == null) {
    return _defaultFontSize;
  }
  if (value is! num) {
    throw const SettingsFormatException("Key 'fontSize' must be an integer.");
  }
  final fontSize = value.toInt();
  if (fontSize != value) {
    throw const SettingsFormatException(
      "Key 'fontSize' must not have a fractional part.",
    );
  }
  if (fontSize < _minFontSize || fontSize > _maxFontSize) {
    throw const SettingsFormatException(
      "Key 'fontSize' must be between $_minFontSize and $_maxFontSize.",
    );
  }
  return fontSize;
}

bool _parseDarkMode(Map<String, Object?> json) {
  final value = json['darkMode'];
  if (value == null) {
    return false;
  }
  if (value is! bool) {
    throw const SettingsFormatException("Key 'darkMode' must be a boolean.");
  }
  return value;
}

List<String> _parseTags(Map<String, Object?> json) {
  final value = json['tags'];
  if (value == null) {
    return const [];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException(
      "Key 'tags' must be a list of strings.",
    );
  }
  final tags = <String>[];
  for (final element in value) {
    if (element is! String) {
      throw const SettingsFormatException(
        "Key 'tags' must contain strings only.",
      );
    }
    if (element.isEmpty) {
      throw const SettingsFormatException(
        "Key 'tags' must not contain an empty string.",
      );
    }
    tags.add(element);
  }
  return tags;
}
