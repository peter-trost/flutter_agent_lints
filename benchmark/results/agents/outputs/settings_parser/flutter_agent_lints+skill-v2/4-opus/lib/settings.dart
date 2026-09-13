import 'dart:convert';

import 'package:flutter/foundation.dart';

const _defaultFontSize = 14;
const _minFontSize = 8;
const _maxFontSize = 72;

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

Object? _decode(String source) {
  try {
    return jsonDecode(source);
  } on FormatException catch (error) {
    throw SettingsFormatException('Not valid JSON: ${error.message}');
  }
}

Never _reject(String key, String expected) =>
    throw SettingsFormatException('Expected $expected for key: $key');

String _readUsername(Map<String, Object?> json) {
  final value = json['username'];
  if (value is! String || value.isEmpty) {
    _reject('username', 'a non-empty string');
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  if (!json.containsKey('fontSize')) {
    return _defaultFontSize;
  }
  final value = json['fontSize'];
  if (value is! int) {
    _reject('fontSize', 'an integer');
  }
  if (value < _minFontSize || value > _maxFontSize) {
    _reject('fontSize', 'an integer from $_minFontSize to $_maxFontSize');
  }
  return value;
}

bool _readDarkMode(Map<String, Object?> json) {
  if (!json.containsKey('darkMode')) {
    return false;
  }
  final value = json['darkMode'];
  if (value is! bool) {
    _reject('darkMode', 'a boolean');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  if (!json.containsKey('tags')) {
    return const [];
  }
  final value = json['tags'];
  if (value is! List<Object?>) {
    _reject('tags', 'a list of non-empty strings');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String || tag.isEmpty) {
      _reject('tags', 'a list of non-empty strings');
    }
    tags.add(tag);
  }
  return tags;
}
