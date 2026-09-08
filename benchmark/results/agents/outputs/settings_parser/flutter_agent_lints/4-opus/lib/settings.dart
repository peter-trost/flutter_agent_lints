import 'dart:convert';

import 'package:flutter/foundation.dart';

const _usernameKey = 'username';
const _fontSizeKey = 'fontSize';
const _darkModeKey = 'darkMode';
const _tagsKey = 'tags';

const _minFontSize = 8;
const _maxFontSize = 72;

/// User preferences, as stored in and restored from a JSON document.
@immutable
class Settings {
  const new({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
  }) : assert(username != '', 'username must not be empty'),
       assert(
         fontSize >= _minFontSize && fontSize <= _maxFontSize,
         'fontSize must be within $_minFontSize..$_maxFontSize',
       );

  final String username;
  final int fontSize;
  final bool darkMode;
  final List<String> tags;

  Map<String, Object?> toJson() => {
    _usernameKey: username,
    _fontSizeKey: fontSize,
    _darkModeKey: darkMode,
    _tagsKey: tags,
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

/// Thrown by [parseSettings] for any document it cannot turn into [Settings].
class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Reads a [Settings] value from a JSON document.
///
/// Throws a [SettingsFormatException] when [json] is not valid JSON, when its
/// top level is not an object, or when a known key is missing, holds a value
/// of the wrong type, or holds a value outside its range. The message always
/// names the offending key. Unknown keys are ignored.
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
  } on FormatException {
    throw const SettingsFormatException('The document is not valid JSON.');
  }
}

String _readUsername(Map<String, Object?> json) {
  final value = json[_usernameKey];
  if (value == null) {
    throw const SettingsFormatException(
      'Key "$_usernameKey" is required and is missing.',
    );
  }
  if (value is! String) {
    throw const SettingsFormatException(
      'Key "$_usernameKey" must hold a string.',
    );
  }
  if (value.isEmpty) {
    throw const SettingsFormatException(
      'Key "$_usernameKey" must not hold an empty string.',
    );
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  if (!json.containsKey(_fontSizeKey)) {
    return 14;
  }
  final value = json[_fontSizeKey];
  if (value is! int) {
    throw const SettingsFormatException(
      'Key "$_fontSizeKey" must hold an integer without a fractional part.',
    );
  }
  if (value < _minFontSize || value > _maxFontSize) {
    throw const SettingsFormatException(
      'Key "$_fontSizeKey" must hold a value '
      'within $_minFontSize..$_maxFontSize.',
    );
  }
  return value;
}

bool _readDarkMode(Map<String, Object?> json) {
  if (!json.containsKey(_darkModeKey)) {
    return false;
  }
  final value = json[_darkModeKey];
  if (value is! bool) {
    throw const SettingsFormatException(
      'Key "$_darkModeKey" must hold a boolean.',
    );
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  if (!json.containsKey(_tagsKey)) {
    return const [];
  }
  final value = json[_tagsKey];
  if (value is! List<Object?>) {
    throw const SettingsFormatException(
      'Key "$_tagsKey" must hold a list of strings.',
    );
  }
  final tags = <String>[];
  for (final element in value) {
    if (element is! String) {
      throw const SettingsFormatException(
        'Key "$_tagsKey" must hold strings only.',
      );
    }
    if (element.isEmpty) {
      throw const SettingsFormatException(
        'Key "$_tagsKey" must not hold an empty string.',
      );
    }
    tags.add(element);
  }
  return tags;
}
