import 'dart:convert';

/// Smallest font size a valid [Settings] may carry.
const int _minFontSize = 8;

/// Largest font size a valid [Settings] may carry.
const int _maxFontSize = 72;

const String _usernameKey = 'username';
const String _fontSizeKey = 'fontSize';
const String _darkModeKey = 'darkMode';
const String _tagsKey = 'tags';

/// Thrown by [parseSettings] when its input cannot be turned into [Settings].
///
/// The [message] always names the offending key when the failure can be
/// attributed to one.
class SettingsFormatException implements Exception {
  /// Creates an exception describing why settings could not be parsed.
  const SettingsFormatException(this.message);

  /// Human readable description of the problem.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// User preferences that can be round-tripped through JSON.
///
/// A valid instance has a non-empty [username], a [fontSize] between
/// [_minFontSize] and [_maxFontSize] inclusive, and only non-empty [tags].
class Settings {
  /// Creates settings for a user.
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
  }) : assert(username != '', 'username must not be empty'),
       assert(
         fontSize >= _minFontSize && fontSize <= _maxFontSize,
         'fontSize must be between $_minFontSize and $_maxFontSize',
       );

  /// Name the settings belong to. Never empty.
  final String username;

  /// Font size in logical pixels, within `$_minFontSize..$_maxFontSize`.
  final int fontSize;

  /// Whether the dark colour scheme is preferred.
  final bool darkMode;

  /// Labels attached to the user. Every entry is non-empty.
  final List<String> tags;

  /// Returns a JSON encodable representation of these settings.
  ///
  /// Feeding [jsonEncode] of the result back into [parseSettings] yields an
  /// equal [Settings].
  Map<String, Object?> toJson() => <String, Object?>{
    _usernameKey: username,
    _fontSizeKey: fontSize,
    _darkModeKey: darkMode,
    _tagsKey: List<String>.unmodifiable(tags),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Settings &&
        other.username == username &&
        other.fontSize == fontSize &&
        other.darkMode == darkMode &&
        _sameTags(other.tags, tags);
  }

  @override
  int get hashCode =>
      Object.hash(username, fontSize, darkMode, Object.hashAll(tags));

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags)';
}

/// Parses [json], a JSON document describing a single settings object.
///
/// Throws a [SettingsFormatException] — and nothing else — when the text is
/// not a JSON object, when a required key is missing, or when a value has the
/// wrong type or falls outside its allowed range. Unknown keys are ignored.
Settings parseSettings(String json) {
  final decoded = _decode(json);
  if (decoded is! Map<String, Object?>) {
    throw SettingsFormatException(
      'Expected a JSON object at the top level, but was ${_describe(decoded)}.',
    );
  }
  return Settings(
    username: _readUsername(decoded),
    fontSize: _readFontSize(decoded) ?? 14,
    darkMode: _readDarkMode(decoded) ?? false,
    tags: _readTags(decoded) ?? const <String>[],
  );
}

Object? _decode(String source) {
  try {
    return jsonDecode(source) as Object?;
  } on FormatException catch (error) {
    throw SettingsFormatException('Not valid JSON: ${error.message}');
  }
}

String _readUsername(Map<String, Object?> json) {
  if (!json.containsKey(_usernameKey)) {
    throw _missing(_usernameKey);
  }
  final value = json[_usernameKey];
  if (value is! String) {
    _wrongType(_usernameKey, 'a string', value);
  }
  if (value.isEmpty) {
    throw SettingsFormatException('Key "$_usernameKey" must not be empty.');
  }
  return value;
}

int? _readFontSize(Map<String, Object?> json) {
  final value = json[_fontSizeKey];
  if (value == null) {
    if (json.containsKey(_fontSizeKey)) {
      _wrongType(_fontSizeKey, 'an integer', value);
    }
    return null;
  }
  final int fontSize;
  if (value is int) {
    fontSize = value;
  } else if (value is double && value.isFinite && value.truncate() == value) {
    // JSON has a single number type, so 14.0 is an acceptable spelling of 14.
    fontSize = value.toInt();
  } else {
    _wrongType(_fontSizeKey, 'an integer', value);
  }
  if (fontSize < _minFontSize || fontSize > _maxFontSize) {
    throw SettingsFormatException(
      'Key "$_fontSizeKey" must be between $_minFontSize and $_maxFontSize, '
      'but was $fontSize.',
    );
  }
  return fontSize;
}

bool? _readDarkMode(Map<String, Object?> json) {
  final value = json[_darkModeKey];
  if (value == null) {
    if (json.containsKey(_darkModeKey)) {
      _wrongType(_darkModeKey, 'a boolean', value);
    }
    return null;
  }
  if (value is! bool) {
    _wrongType(_darkModeKey, 'a boolean', value);
  }
  return value;
}

List<String>? _readTags(Map<String, Object?> json) {
  final value = json[_tagsKey];
  if (value == null) {
    if (json.containsKey(_tagsKey)) {
      _wrongType(_tagsKey, 'a list of strings', value);
    }
    return null;
  }
  if (value is! List<Object?>) {
    _wrongType(_tagsKey, 'a list of strings', value);
  }
  final tags = <String>[];
  for (final element in value) {
    if (element is! String) {
      _wrongType(_tagsKey, 'a list of strings', element);
    }
    if (element.isEmpty) {
      throw SettingsFormatException(
        'Key "$_tagsKey" must not contain an empty tag.',
      );
    }
    tags.add(element);
  }
  return List<String>.unmodifiable(tags);
}

SettingsFormatException _missing(String key) =>
    SettingsFormatException('Missing required key "$key".');

Never _wrongType(String key, String expected, Object? value) {
  throw SettingsFormatException(
    'Key "$key" must be $expected, but was ${_describe(value)}.',
  );
}

String _describe(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return 'a string';
  }
  if (value is bool) {
    return 'a boolean';
  }
  if (value is num) {
    return 'a number';
  }
  if (value is List<Object?>) {
    return 'a list';
  }
  if (value is Map<String, Object?>) {
    return 'an object';
  }
  return 'unsupported';
}

bool _sameTags(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
