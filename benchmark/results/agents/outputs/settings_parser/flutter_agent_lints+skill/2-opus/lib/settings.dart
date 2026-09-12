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
}

class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;
}

Settings parseSettings(String json) {
  final document = _decode(json);
  if (document is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'The top level of the document must be a JSON object.',
    );
  }
  return Settings(
    username: _readUsername(document),
    fontSize: _readFontSize(document),
    darkMode: _readDarkMode(document),
    tags: _readTags(document),
  );
}

Object? _decode(String json) {
  try {
    return jsonDecode(json);
  } on FormatException {
    throw const SettingsFormatException('The text is not valid JSON.');
  }
}

String _readUsername(Map<String, Object?> json) {
  if (!json.containsKey('username')) {
    throw const SettingsFormatException('username is missing.');
  }
  final value = json['username'];
  if (value is! String) {
    throw const SettingsFormatException('username must be a string.');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('username must not be empty.');
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
      'fontSize must be an integer without a fractional part.',
    );
  }
  if (value < _minFontSize || value > _maxFontSize) {
    throw const SettingsFormatException(
      'fontSize must be between $_minFontSize and $_maxFontSize.',
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
    throw const SettingsFormatException('darkMode must be a boolean.');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  if (!json.containsKey('tags')) {
    return const [];
  }
  final value = json['tags'];
  if (value is! List<Object?>) {
    throw const SettingsFormatException('tags must be a list of strings.');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException('tags must contain strings only.');
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException(
        'tags must not contain an empty string.',
      );
    }
    tags.add(tag);
  }
  return List<String>.unmodifiable(tags);
}
