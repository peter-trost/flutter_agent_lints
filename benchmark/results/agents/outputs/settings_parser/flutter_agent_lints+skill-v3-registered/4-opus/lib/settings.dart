import 'dart:convert';

import 'package:flutter/foundation.dart';

const _minFontSize = 8;
const _maxFontSize = 72;

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

@immutable
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
    throw SettingsFormatException('Not valid JSON: ${error.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'Expected a JSON object at the top level',
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
  if (value == null) {
    throw const SettingsFormatException('Missing required key: username');
  }
  if (value is! String) {
    throw const SettingsFormatException('Expected a string for key: username');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('Empty value for key: username');
  }
  return value;
}

int _parseFontSize(Map<String, Object?> json) {
  final value = json['fontSize'];
  if (value == null) {
    return 14;
  }
  if (value is! int) {
    throw const SettingsFormatException(
      'Expected a whole number for key: fontSize',
    );
  }
  if (value < _minFontSize || value > _maxFontSize) {
    throw SettingsFormatException(
      'Value for key fontSize must be between $_minFontSize and '
      '$_maxFontSize, but was $value',
    );
  }
  return value;
}

bool _parseDarkMode(Map<String, Object?> json) {
  final value = json['darkMode'];
  if (value == null) {
    return false;
  }
  if (value is! bool) {
    throw const SettingsFormatException('Expected a boolean for key: darkMode');
  }
  return value;
}

List<String> _parseTags(Map<String, Object?> json) {
  final value = json['tags'];
  if (value == null) {
    return const [];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException('Expected a list for key: tags');
  }
  return [for (final tag in value) _parseTag(tag)];
}

String _parseTag(Object? tag) {
  if (tag is! String) {
    throw const SettingsFormatException(
      'Expected only strings in the list for key: tags',
    );
  }
  if (tag.isEmpty) {
    throw const SettingsFormatException('Empty entry for key: tags');
  }
  return tag;
}
