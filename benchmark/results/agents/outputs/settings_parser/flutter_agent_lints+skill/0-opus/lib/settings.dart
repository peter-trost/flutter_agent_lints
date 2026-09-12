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
  final decoded = _decodeJson(json);
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'The top level of the document must be a JSON object.',
    );
  }
  return Settings(
    username: _readUsername(decoded),
    fontSize: _readFontSize(decoded),
    darkMode: _readDarkMode(decoded),
    tags: _readTags(decoded),
  );
}

Object? _decodeJson(String source) {
  try {
    return jsonDecode(source) as Object?;
  } on FormatException catch (error) {
    throw SettingsFormatException(
      'The text is not valid JSON: ${error.message}',
    );
  }
}

String _readUsername(Map<String, Object?> json) {
  if (!json.containsKey('username')) {
    throw const SettingsFormatException(
      'The required key "username" is missing.',
    );
  }
  final value = json['username'];
  if (value is! String) {
    throw const SettingsFormatException('The key "username" must be a string.');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException(
      'The key "username" must not be empty.',
    );
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  if (!json.containsKey('fontSize')) {
    return _defaultFontSize;
  }
  final value = json['fontSize'];
  if (value is! num) {
    throw const SettingsFormatException('The key "fontSize" must be a number.');
  }
  final size = value.toInt();
  if (size != value) {
    throw SettingsFormatException(
      'The key "fontSize" must be a whole number, but was $value.',
    );
  }
  if (size < _minFontSize || size > _maxFontSize) {
    throw SettingsFormatException(
      'The key "fontSize" must be between $_minFontSize and $_maxFontSize, '
      'but was $size.',
    );
  }
  return size;
}

bool _readDarkMode(Map<String, Object?> json) {
  if (!json.containsKey('darkMode')) {
    return false;
  }
  final value = json['darkMode'];
  if (value is! bool) {
    throw const SettingsFormatException(
      'The key "darkMode" must be a boolean.',
    );
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  if (!json.containsKey('tags')) {
    return const [];
  }
  final value = json['tags'];
  if (value is! List<Object?>) {
    throw const SettingsFormatException('The key "tags" must be a list.');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException(
        'The key "tags" must contain strings only.',
      );
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException(
        'The key "tags" must not contain an empty string.',
      );
    }
    tags.add(tag);
  }
  return List.unmodifiable(tags);
}
