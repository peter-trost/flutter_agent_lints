import 'dart:convert';

import 'package:flutter/foundation.dart';

const _minFontSize = 8;
const _maxFontSize = 72;
const _defaultFontSize = 14;

/// User preferences, as stored in a JSON document.
@immutable
class Settings {
  const new({
    required this.username,
    this.fontSize = _defaultFontSize,
    this.darkMode = false,
    this.tags = const [],
  }) : assert(username != '', 'username must not be empty'),
       assert(
         fontSize >= _minFontSize && fontSize <= _maxFontSize,
         'fontSize must be between $_minFontSize and $_maxFontSize',
       );

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

/// Thrown when a document cannot be read as settings.
class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Reads settings from a JSON document, throwing a
/// SettingsFormatException for anything this library cannot accept.
Settings parseSettings(String json) {
  final decoded = _decode(json);
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'Expected a JSON object at the top level',
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
    return jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException('Not valid JSON: ${error.message}');
  }
}

String _readUsername(Map<String, Object?> json) {
  final value = json['username'];
  if (value is! String) {
    throw const SettingsFormatException('Expected a string for key: username');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('Empty value for key: username');
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  if (!json.containsKey('fontSize')) {
    return _defaultFontSize;
  }
  final value = json['fontSize'];
  if (value is! num || value % 1 != 0) {
    throw const SettingsFormatException(
      'Expected a whole number for key: fontSize',
    );
  }
  final fontSize = value.toInt();
  if (fontSize < _minFontSize || fontSize > _maxFontSize) {
    throw const SettingsFormatException(
      'Expected a value between $_minFontSize and $_maxFontSize '
      'for key: fontSize',
    );
  }
  return fontSize;
}

bool _readDarkMode(Map<String, Object?> json) {
  if (!json.containsKey('darkMode')) {
    return false;
  }
  final value = json['darkMode'];
  if (value is! bool) {
    throw const SettingsFormatException('Expected a boolean for key: darkMode');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  if (!json.containsKey('tags')) {
    return const [];
  }
  final value = json['tags'];
  if (value is! List<Object?>) {
    throw const SettingsFormatException(
      'Expected a list of strings for key: tags',
    );
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException(
        'Expected a list of strings for key: tags',
      );
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException('Empty entry for key: tags');
    }
    tags.add(tag);
  }
  return List<String>.unmodifiable(tags);
}
