import 'dart:convert';

import 'package:flutter/foundation.dart';

const _defaultFontSize = 14;
const _minFontSize = 8;
const _maxFontSize = 72;

/// The settings of the app, as stored in a JSON document.
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

/// Thrown when a settings document cannot be read as a valid Settings value.
class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Reads a settings document. Every failure is a SettingsFormatException.
Settings parseSettings(String json) {
  final Object? document;
  try {
    document = jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException(
      'The text is not valid JSON: ${error.message}',
    );
  }
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

String _readUsername(Map<String, Object?> document) {
  const key = 'username';
  final value = document[key];
  if (value == null) {
    throw const SettingsFormatException('The key "$key" is required.');
  }
  if (value is! String) {
    throw const SettingsFormatException('The key "$key" must be a string.');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('The key "$key" must not be empty.');
  }
  return value;
}

int _readFontSize(Map<String, Object?> document) {
  const key = 'fontSize';
  final value = document[key];
  if (value == null) {
    return _defaultFontSize;
  }
  if (value is! num || !value.isFinite) {
    throw const SettingsFormatException('The key "$key" must be an integer.');
  }
  final size = value.toInt();
  if (size != value) {
    throw const SettingsFormatException(
      'The key "$key" must not have a fractional part.',
    );
  }
  if (size < _minFontSize || size > _maxFontSize) {
    throw const SettingsFormatException(
      'The key "$key" must be within $_minFontSize..$_maxFontSize.',
    );
  }
  return size;
}

bool _readDarkMode(Map<String, Object?> document) {
  const key = 'darkMode';
  final value = document[key];
  if (value == null) {
    return false;
  }
  if (value is! bool) {
    throw const SettingsFormatException('The key "$key" must be a boolean.');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> document) {
  const key = 'tags';
  final value = document[key];
  if (value == null) {
    return const [];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException(
      'The key "$key" must be a list of strings.',
    );
  }
  final tags = <String>[];
  for (final element in value) {
    if (element is! String) {
      throw const SettingsFormatException(
        'The key "$key" must contain strings only.',
      );
    }
    if (element.isEmpty) {
      throw const SettingsFormatException(
        'The key "$key" must not contain an empty string.',
      );
    }
    tags.add(element);
  }
  return List<String>.unmodifiable(tags);
}
