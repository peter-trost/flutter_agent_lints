import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The smallest font size a valid [Settings] may carry.
const int _minFontSize = 8;

/// The largest font size a valid [Settings] may carry.
const int _maxFontSize = 72;

const String _usernameKey = 'username';
const String _fontSizeKey = 'fontSize';
const String _darkModeKey = 'darkMode';
const String _tagsKey = 'tags';

/// The user preferences of the app, as stored in a JSON document.
@immutable
class Settings {
  /// Creates settings for [username].
  ///
  /// [username] must not be empty and [fontSize] must be within
  /// [_minFontSize]..[_maxFontSize]; every entry of [tags] must be non-empty.
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const <String>[],
  }) : assert(username != '', 'username must not be empty'),
       assert(
         fontSize >= _minFontSize && fontSize <= _maxFontSize,
         'fontSize must be within $_minFontSize..$_maxFontSize',
       );

  /// The name the settings belong to. Never empty.
  final String username;

  /// The editor font size, within [_minFontSize]..[_maxFontSize].
  final int fontSize;

  /// Whether the dark theme is selected.
  final bool darkMode;

  /// The labels attached to these settings. Every entry is non-empty.
  final List<String> tags;

  /// Returns a JSON encodable representation of these settings.
  ///
  /// `parseSettings(jsonEncode(settings.toJson()))` equals `settings`.
  Map<String, Object?> toJson() => <String, Object?>{
    _usernameKey: username,
    _fontSizeKey: fontSize,
    _darkModeKey: darkMode,
    _tagsKey: List<String>.of(tags),
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

/// Thrown by [parseSettings] when a document is not a valid [Settings].
///
/// The [message] names the offending key whenever the failure can be
/// attributed to one.
class SettingsFormatException implements Exception {
  /// Creates an exception described by [message].
  const SettingsFormatException(this.message);

  /// A human readable description of why parsing failed.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Parses [json], a JSON document holding a settings object.
///
/// Unknown keys are ignored. Throws a [SettingsFormatException] — and nothing
/// else — when the text is not JSON, when its top level is not an object, or
/// when a key is missing, of the wrong type, or out of range.
Settings parseSettings(String json) {
  final Object? decoded = _decode(json);
  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'the top level of the document must be a JSON object',
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
    return jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException(
      'the text is not valid JSON: ${error.message}',
    );
  }
}

String _readUsername(Map<String, Object?> json) {
  final Object? value = json[_usernameKey];
  if (value == null) {
    throw const SettingsFormatException('"$_usernameKey" is required');
  }
  if (value is! String) {
    throw const SettingsFormatException('"$_usernameKey" must be a string');
  }
  if (value.isEmpty) {
    throw const SettingsFormatException('"$_usernameKey" must not be empty');
  }
  return value;
}

int _readFontSize(Map<String, Object?> json) {
  if (!json.containsKey(_fontSizeKey)) {
    return 14;
  }
  final Object? value = json[_fontSizeKey];
  final int fontSize;
  if (value is int) {
    fontSize = value;
  } else if (value is double) {
    if (!value.isFinite || value != value.truncateToDouble()) {
      throw const SettingsFormatException(
        '"$_fontSizeKey" must be a whole number',
      );
    }
    fontSize = value.toInt();
  } else {
    throw const SettingsFormatException('"$_fontSizeKey" must be an integer');
  }
  if (fontSize < _minFontSize || fontSize > _maxFontSize) {
    throw const SettingsFormatException(
      '"$_fontSizeKey" must be within $_minFontSize..$_maxFontSize',
    );
  }
  return fontSize;
}

bool _readDarkMode(Map<String, Object?> json) {
  if (!json.containsKey(_darkModeKey)) {
    return false;
  }
  final Object? value = json[_darkModeKey];
  if (value is! bool) {
    throw const SettingsFormatException('"$_darkModeKey" must be a boolean');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> json) {
  if (!json.containsKey(_tagsKey)) {
    return const <String>[];
  }
  final Object? value = json[_tagsKey];
  if (value is! List<Object?>) {
    throw const SettingsFormatException(
      '"$_tagsKey" must be a list of strings',
    );
  }
  final List<String> tags = <String>[];
  for (final Object? element in value) {
    if (element is! String) {
      throw const SettingsFormatException(
        '"$_tagsKey" must contain only strings',
      );
    }
    if (element.isEmpty) {
      throw const SettingsFormatException(
        '"$_tagsKey" must not contain an empty string',
      );
    }
    tags.add(element);
  }
  return List<String>.unmodifiable(tags);
}
