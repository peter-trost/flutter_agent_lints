import 'dart:convert';

import 'package:flutter/foundation.dart';

const _defaultFontSize = 14;
const _minFontSize = 8;
const _maxFontSize = 72;
const _defaultLocale = 'en';

final _localePattern = RegExp(r'^[a-z]{2}(_[A-Z]{2})?$');

@immutable
class Settings {
  const new({
    required this.username,
    this.fontSize = _defaultFontSize,
    this.darkMode = false,
    this.tags = const [],
    this.locale = _defaultLocale,
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
    locale: _readLocale(decoded),
  );
}

Object? _decode(String json) {
  try {
    return jsonDecode(json);
  } on FormatException {
    throw const SettingsFormatException('The text is not valid JSON');
  }
}

String _readUsername(Map<String, Object?> json) {
  final value = json['username'];
  if (value is! String) {
    throw const SettingsFormatException('Expected a string for key: username');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException(
      'Expected a non-empty string for key: username',
    );
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
      'Expected an integer for key: fontSize',
    );
  }
  if (value < _minFontSize || value > _maxFontSize) {
    throw const SettingsFormatException(
      'Expected an integer from $_minFontSize to $_maxFontSize '
      'for key: fontSize',
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
    throw const SettingsFormatException('Expected a boolean for key: darkMode');
  }
  return value;
}

String _readLocale(Map<String, Object?> json) {
  if (!json.containsKey('locale')) {
    return _defaultLocale;
  }
  final value = json['locale'];
  if (value is! String) {
    throw const SettingsFormatException('Expected a string for key: locale');
  }
  if (!_localePattern.hasMatch(value)) {
    throw const SettingsFormatException(
      'Expected a language code such as en or de_DE for key: locale',
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
    throw const SettingsFormatException(
      'Expected a list of strings for key: tags',
    );
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String || tag.isEmpty) {
      throw const SettingsFormatException(
        'Expected a list of non-empty strings for key: tags',
      );
    }
    tags.add(tag);
  }
  return tags;
}
