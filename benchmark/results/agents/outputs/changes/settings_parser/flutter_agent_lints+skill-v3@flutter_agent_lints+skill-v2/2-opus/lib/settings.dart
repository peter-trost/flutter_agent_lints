import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class Settings {
  const new({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
    this.locale = 'en',
  });

  final String username;
  final int fontSize;
  final bool darkMode;
  final List<String> tags;
  final String locale;

  Map<String, Object?> toJson() => {
    'username': username,
    'fontSize': fontSize,
    'darkMode': darkMode,
    'tags': tags,
    'locale': locale,
  };

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.username == username &&
      other.fontSize == fontSize &&
      other.darkMode == darkMode &&
      listEquals(other.tags, tags) &&
      other.locale == locale;

  @override
  int get hashCode =>
      Object.hash(username, fontSize, darkMode, Object.hashAll(tags), locale);

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags, locale: $locale)';
}

class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

Settings parseSettings(String json) {
  final object = _decodeObject(json);
  return Settings(
    username: _readUsername(object),
    fontSize: _readFontSize(object),
    darkMode: _readDarkMode(object),
    tags: _readTags(object),
    locale: _readLocale(object),
  );
}

const _minFontSize = 8;
const _maxFontSize = 72;

final _localePattern = RegExp(r'^[a-z]{2}(?:_[A-Z]{2})?$');

Never _reject(String key, String expected) =>
    throw SettingsFormatException('Expected $expected for key: $key');

Map<String, Object?> _decodeObject(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    throw const SettingsFormatException('The text is not valid JSON.');
  }
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'Expected a JSON object at the top level.',
    );
  }
  return decoded;
}

String _readUsername(Map<String, Object?> json) {
  const key = 'username';
  final value = json[key];
  if (value is! String) {
    _reject(key, 'a string');
  }
  if (value.isEmpty) {
    _reject(key, 'a non-empty string');
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  const key = 'fontSize';
  if (!json.containsKey(key)) {
    return 14;
  }
  final value = json[key];
  if (value is! num || value != value.truncate()) {
    _reject(key, 'an integer');
  }
  final fontSize = value.truncate();
  if (fontSize < _minFontSize || fontSize > _maxFontSize) {
    _reject(key, 'an integer from $_minFontSize to $_maxFontSize');
  }
  return fontSize;
}

bool _readDarkMode(Map<String, Object?> json) {
  const key = 'darkMode';
  if (!json.containsKey(key)) {
    return false;
  }
  final value = json[key];
  if (value is! bool) {
    _reject(key, 'a boolean');
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
    _reject(key, 'a list of strings');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      _reject(key, 'a list of strings');
    }
    if (tag.isEmpty) {
      _reject(key, 'a list of non-empty strings');
    }
    tags.add(tag);
  }
  return tags;
}

String _readLocale(Map<String, Object?> json) {
  const key = 'locale';
  if (!json.containsKey(key)) {
    return 'en';
  }
  final value = json[key];
  if (value is! String) {
    _reject(key, 'a string');
  }
  if (!_localePattern.hasMatch(value)) {
    _reject(key, 'a language code such as en or de_DE');
  }
  return value;
}
