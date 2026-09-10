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

class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException('not valid JSON: ${error.message}');
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

String _readUsername(Map<String, Object?> json) {
  final value = json['username'];
  if (value == null) {
    throw const SettingsFormatException('username is required');
  }
  if (value is! String) {
    throw const SettingsFormatException('username must be a string');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('username must not be empty');
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  final value = json['fontSize'];
  if (value == null) {
    if (json.containsKey('fontSize')) {
      throw const SettingsFormatException('fontSize must be an integer');
    }
    return 14;
  }
  if (value is! num || value != value.truncate()) {
    throw const SettingsFormatException('fontSize must be an integer');
  }
  final fontSize = value.toInt();
  if (fontSize < _minFontSize || fontSize > _maxFontSize) {
    throw const SettingsFormatException(
      'fontSize must be between $_minFontSize and $_maxFontSize',
    );
  }
  return fontSize;
}

bool _readDarkMode(Map<String, Object?> json) {
  final value = json['darkMode'];
  if (value == null) {
    if (json.containsKey('darkMode')) {
      throw const SettingsFormatException('darkMode must be a boolean');
    }
    return false;
  }
  if (value is! bool) {
    throw const SettingsFormatException('darkMode must be a boolean');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  final value = json['tags'];
  if (value == null) {
    if (json.containsKey('tags')) {
      throw const SettingsFormatException('tags must be a list of strings');
    }
    return const [];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException('tags must be a list of strings');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException('tags must contain only strings');
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException('tags must not contain an empty tag');
    }
    tags.add(tag);
  }
  return tags;
}
