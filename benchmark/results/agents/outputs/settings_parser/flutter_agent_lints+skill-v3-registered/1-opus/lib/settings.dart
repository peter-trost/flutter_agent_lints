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
      'The top level of the document must be a JSON object',
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
    return jsonDecode(json) as Object?;
  } on FormatException catch (error) {
    throw SettingsFormatException(
      'The text is not valid JSON: ${error.message}',
    );
  }
}

String _readUsername(Map<String, Object?> json) {
  final value = json['username'];
  if (value == null) {
    throw const SettingsFormatException('Missing required key: username');
  }
  if (value is! String) {
    throw const SettingsFormatException('Expected a string for key: username');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('Key username must not be empty');
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  final value = json['fontSize'];
  if (value == null) {
    return _defaultFontSize;
  }
  if (value is! num || value != value.truncate()) {
    throw const SettingsFormatException(
      'Expected a whole number for key: fontSize',
    );
  }
  final fontSize = value.toInt();
  if (fontSize < _minFontSize || fontSize > _maxFontSize) {
    throw const SettingsFormatException(
      'Key fontSize must be between $_minFontSize and $_maxFontSize',
    );
  }
  return fontSize;
}

bool _readDarkMode(Map<String, Object?> json) {
  final value = json['darkMode'];
  if (value == null) {
    return false;
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
      'Expected a list of strings for key: tags',
    );
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException(
        'Expected only strings in the list for key: tags',
      );
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException(
        'Key tags must not contain an empty string',
      );
    }
    tags.add(tag);
  }
  return List.unmodifiable(tags);
}
