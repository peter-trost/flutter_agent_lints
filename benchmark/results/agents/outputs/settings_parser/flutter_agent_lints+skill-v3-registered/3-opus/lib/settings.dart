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
  } on FormatException catch (e) {
    throw SettingsFormatException('Invalid JSON: ${e.message}');
  }
}

String _readUsername(Map<String, Object?> json) {
  const key = 'username';
  if (!json.containsKey(key)) {
    throw const SettingsFormatException('Missing required key: $key');
  }
  final value = json[key];
  if (value is! String) {
    throw const SettingsFormatException('Expected a string for key: $key');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('Empty value for key: $key');
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  const key = 'fontSize';
  if (!json.containsKey(key)) {
    return 14;
  }
  final value = json[key];
  if (value is! int) {
    throw const SettingsFormatException('Expected an integer for key: $key');
  }
  if (value < _minFontSize || value > _maxFontSize) {
    throw const SettingsFormatException(
      'Value out of range ($_minFontSize..$_maxFontSize) for key: $key',
    );
  }
  return value;
}

bool _readDarkMode(Map<String, Object?> json) {
  const key = 'darkMode';
  if (!json.containsKey(key)) {
    return false;
  }
  final value = json[key];
  if (value is! bool) {
    throw const SettingsFormatException('Expected a boolean for key: $key');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  const key = 'tags';
  if (!json.containsKey(key)) {
    return const [];
  }
  final value = json[key];
  if (value is! List<Object?>) {
    throw const SettingsFormatException('Expected a list for key: $key');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException(
        'Expected a list of strings for key: $key',
      );
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException('Empty tag in key: $key');
    }
    tags.add(tag);
  }
  return List.unmodifiable(tags);
}
