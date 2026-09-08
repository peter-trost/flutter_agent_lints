import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Thrown by [parseSettings] when a document cannot be read as [Settings].
///
/// The [message] always names the offending key when one key is at fault.
class SettingsFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// User preferences, as stored in a JSON document.
///
/// The constructor does not validate; [parseSettings] is the checked entry
/// point and rejects an empty [username], a [fontSize] outside
/// [minFontSize]..[maxFontSize], and an empty tag.
@immutable
class Settings {
  const new({
    required this.username,
    this.fontSize = defaultFontSize,
    this.darkMode = false,
    this.tags = const [],
  });

  /// Smallest accepted [fontSize].
  static const minFontSize = 8;

  /// Largest accepted [fontSize].
  static const maxFontSize = 72;

  /// Value used when the `fontSize` key is absent.
  static const defaultFontSize = 14;

  final String username;
  final int fontSize;
  final bool darkMode;
  final List<String> tags;

  /// The JSON representation read back by [parseSettings].
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

/// Reads [json] as a settings document.
///
/// Throws [SettingsFormatException], and nothing else, for any input that is
/// not a settings document. Unknown keys are ignored.
Settings parseSettings(String json) {
  final Object? document;
  try {
    document = jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException('not valid JSON: ${error.message}');
  }
  if (document is! Map<String, Object?>) {
    throw const SettingsFormatException('top level must be a JSON object');
  }
  return Settings(
    username: _readUsername(document),
    fontSize: _readFontSize(document),
    darkMode: _readDarkMode(document),
    tags: _readTags(document),
  );
}

String _readUsername(Map<String, Object?> document) {
  final value = document['username'];
  if (value is! String) {
    throw const SettingsFormatException('username: expected a string');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('username: must not be empty');
  }
  return value;
}

int _readFontSize(Map<String, Object?> document) {
  final value = document['fontSize'];
  if (value == null) {
    return Settings.defaultFontSize;
  }
  if (value is! num || !value.isFinite) {
    throw const SettingsFormatException('fontSize: expected an integer');
  }
  final fontSize = value.toInt();
  if (fontSize != value) {
    throw const SettingsFormatException(
      'fontSize: expected an integer without a fractional part',
    );
  }
  if (fontSize < Settings.minFontSize || fontSize > Settings.maxFontSize) {
    throw const SettingsFormatException(
      'fontSize: must be between '
      '${Settings.minFontSize} and ${Settings.maxFontSize}',
    );
  }
  return fontSize;
}

bool _readDarkMode(Map<String, Object?> document) {
  final value = document['darkMode'];
  if (value == null) {
    return false;
  }
  if (value is! bool) {
    throw const SettingsFormatException('darkMode: expected a boolean');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> document) {
  final value = document['tags'];
  if (value == null) {
    return const [];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException('tags: expected a list of strings');
  }
  final tags = <String>[];
  for (final tag in value) {
    if (tag is! String) {
      throw const SettingsFormatException('tags: every entry must be a string');
    }
    if (tag.isEmpty) {
      throw const SettingsFormatException('tags: no entry may be empty');
    }
    tags.add(tag);
  }
  return List.unmodifiable(tags);
}
