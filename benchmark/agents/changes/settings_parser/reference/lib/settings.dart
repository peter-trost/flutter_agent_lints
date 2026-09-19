import 'dart:convert';

import 'package:flutter/foundation.dart';

class Settings {
  const Settings({
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
}

class SettingsFormatException implements Exception {
  const SettingsFormatException(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (e) {
    throw SettingsFormatException('invalid JSON: ${e.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException('top level must be an object');
  }

  final username = decoded['username'];
  if (username is! String) {
    throw const SettingsFormatException('username must be a string');
  }
  if (username.isEmpty) {
    throw const SettingsFormatException('username must not be empty');
  }

  final fontSize = decoded['fontSize'] ?? 14;
  if (fontSize is! int) {
    throw const SettingsFormatException('fontSize must be an integer');
  }
  if (fontSize < 8 || fontSize > 72) {
    throw const SettingsFormatException('fontSize must be within 8..72');
  }

  final darkMode = decoded['darkMode'] ?? false;
  if (darkMode is! bool) {
    throw const SettingsFormatException('darkMode must be a boolean');
  }

  final tags = decoded['tags'] ?? const <Object?>[];
  if (tags is! List<Object?>) {
    throw const SettingsFormatException('tags must be a list');
  }
  final parsedTags = <String>[];
  for (final tag in tags) {
    if (tag is! String || tag.isEmpty) {
      throw const SettingsFormatException(
        'tags must contain non-empty strings',
      );
    }
    parsedTags.add(tag);
  }

  final locale = decoded['locale'] ?? 'en';
  if (locale is! String || !_localePattern.hasMatch(locale)) {
    throw const SettingsFormatException(
      'locale must be a string like en or de_DE',
    );
  }

  return Settings(
    username: username,
    fontSize: fontSize,
    darkMode: darkMode,
    tags: parsedTags,
    locale: locale,
  );
}

final _localePattern = RegExp(r'^[a-z]{2}(_[A-Z]{2})?$');
