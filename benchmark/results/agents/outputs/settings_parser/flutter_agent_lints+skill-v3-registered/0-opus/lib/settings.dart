import 'dart:convert';

import 'package:flutter/foundation.dart';

const _defaultFontSize = 14;
const _minFontSize = 8;
const _maxFontSize = 72;
const _defaultDarkMode = false;

@immutable
class Settings {
  const new({
    required this.username,
    this.fontSize = _defaultFontSize,
    this.darkMode = _defaultDarkMode,
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

class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Reads a settings object out of [json], rejecting anything that does not
/// match the schema with a SettingsFormatException.
Settings parseSettings(String json) {
  final root = _decodeObject(json);
  return Settings(
    username: _readUsername(root),
    fontSize: _readFontSize(root),
    darkMode: _readDarkMode(root),
    tags: _readTags(root),
  );
}

Map<String, Object?> _decodeObject(String json) {
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
  return decoded;
}

String _readUsername(Map<String, Object?> json) {
  final value = json['username'];
  if (value is! String || value.isEmpty) {
    throw const SettingsFormatException(
      'Expected a non-empty string for key: username',
    );
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  final value = json['fontSize'];
  if (value == null) {
    return _defaultFontSize;
  }
  if (value is! int || value < _minFontSize || value > _maxFontSize) {
    throw const SettingsFormatException(
      'Expected a whole number between $_minFontSize and $_maxFontSize '
      'for key: fontSize',
    );
  }
  return value;
}

bool _readDarkMode(Map<String, Object?> json) {
  final value = json['darkMode'];
  if (value == null) {
    return _defaultDarkMode;
  }
  if (value is! bool) {
    throw const SettingsFormatException('Expected a boolean for key: darkMode');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  final value = json['tags'];
  if (value == null) {
    return const [];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException(
      'Expected a list of non-empty strings for key: tags',
    );
  }
  return [for (final entry in value) _readTag(entry)];
}

String _readTag(Object? entry) {
  if (entry is! String || entry.isEmpty) {
    throw const SettingsFormatException(
      'Expected every element to be a non-empty string for key: tags',
    );
  }
  return entry;
}
