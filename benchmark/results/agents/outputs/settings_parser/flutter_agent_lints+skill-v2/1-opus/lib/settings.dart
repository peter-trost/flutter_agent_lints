import 'dart:convert';

import 'package:flutter/foundation.dart';

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

class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

Settings parseSettings(String json) {
  final Object? document;
  try {
    document = jsonDecode(json) as Object?;
  } on FormatException {
    throw const SettingsFormatException('The text is not valid JSON');
  }
  if (document is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'The top level of the document must be a JSON object',
    );
  }
  return Settings(
    username: _readUsername(document),
    fontSize: _readFontSize(document),
    darkMode: _readDarkMode(document),
    tags: _readTags(document),
  );
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
    return 14;
  }
  final value = json['fontSize'];
  // A JSON number reaches Dart as `int` on the VM and as `double` on the web,
  // so the check is on `num` and on the absence of a fractional part.
  if (value is! num || value % 1 != 0) {
    throw const SettingsFormatException(
      'Expected a whole number for key: fontSize',
    );
  }
  final fontSize = value.toInt();
  if (fontSize < 8 || fontSize > 72) {
    throw const SettingsFormatException(
      'Expected a value between 8 and 72 for key: fontSize',
    );
  }
  return fontSize;
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
  for (final entry in value) {
    if (entry is! String) {
      throw const SettingsFormatException(
        'Expected a list of strings for key: tags',
      );
    }
    if (entry.isEmpty) {
      throw const SettingsFormatException(
        'Expected every entry to be non-empty for key: tags',
      );
    }
    tags.add(entry);
  }
  return List<String>.unmodifiable(tags);
}
