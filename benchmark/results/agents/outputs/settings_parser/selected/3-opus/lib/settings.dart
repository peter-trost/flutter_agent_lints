import 'dart:convert';

/// Thrown when a settings document cannot be turned into a [Settings].
///
/// The [message] always mentions the offending key, when there is one, so a
/// caller can point a user straight at the part of the document to fix.
class SettingsFormatException implements Exception {
  /// Creates an exception described by [message].
  const SettingsFormatException(this.message);

  /// A human readable description of what is wrong with the document.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// The user preferences of the app.
class Settings {
  /// Creates a set of preferences.
  ///
  /// [username] must not be empty, [fontSize] must be within 8..72 and every
  /// entry of [tags] must be non-empty.
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

  static const int _defaultFontSize = 14;
  static const int _minFontSize = 8;
  static const int _maxFontSize = 72;

  static const String _usernameKey = 'username';
  static const String _fontSizeKey = 'fontSize';
  static const String _darkModeKey = 'darkMode';
  static const String _tagsKey = 'tags';

  /// The name the user goes by. Never empty.
  final String username;

  /// The size of the app's body text, within 8..72.
  final int fontSize;

  /// Whether the dark colour scheme is used.
  final bool darkMode;

  /// The labels the user has picked. Every entry is non-empty.
  final List<String> tags;

  /// Returns a JSON encodable representation of these settings.
  ///
  /// Feeding the encoded form back to [parseSettings] yields an equal object.
  Map<String, Object?> toJson() => <String, Object?>{
    _usernameKey: username,
    _fontSizeKey: fontSize,
    _darkModeKey: darkMode,
    _tagsKey: List<String>.of(tags),
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
        _tagsEqual(other.tags, tags);
  }

  @override
  int get hashCode =>
      Object.hash(username, fontSize, darkMode, Object.hashAll(tags));

  @override
  String toString() =>
      'Settings(username: $username, fontSize: $fontSize, '
      'darkMode: $darkMode, tags: $tags)';

  static bool _tagsEqual(List<String> a, List<String> b) {
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
}

/// Parses [json] into a [Settings].
///
/// The document must be a JSON object holding `username` and, optionally,
/// `fontSize`, `darkMode` and `tags`; any other key is ignored. Anything the
/// rules above reject — malformed text, a top level that is not an object, a
/// missing `username`, a value of the wrong type or one outside its range —
/// throws a [SettingsFormatException] and nothing else.
Settings parseSettings(String json) {
  final Object? document = _decode(json);
  if (document is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'The top level of the document must be a JSON object.',
    );
  }

  final String username = _readString(document, Settings._usernameKey);
  if (username.isEmpty) {
    throw const SettingsFormatException(
      'Key "${Settings._usernameKey}" must not be empty.',
    );
  }

  final int fontSize = _readInt(
    document,
    Settings._fontSizeKey,
    orElse: Settings._defaultFontSize,
  );
  if (fontSize < Settings._minFontSize || fontSize > Settings._maxFontSize) {
    throw SettingsFormatException(
      'Key "${Settings._fontSizeKey}" must be within '
      '${Settings._minFontSize}..${Settings._maxFontSize}, was $fontSize.',
    );
  }

  return Settings(
    username: username,
    fontSize: fontSize,
    darkMode: _readBool(document, Settings._darkModeKey, orElse: false),
    tags: _readTags(document, Settings._tagsKey),
  );
}

Object? _decode(String json) {
  try {
    return jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException(
      'The document is not valid JSON: '
      '${error.message}',
    );
  }
}

/// Returns the value stored under [key], or `null` when the key is absent.
///
/// A key holding an explicit `null` is reported as a wrong type rather than as
/// an absent key, so both forms are told apart by the callers.
Object? _lookUp(Map<String, Object?> document, String key) {
  if (!document.containsKey(key)) {
    return null;
  }
  final Object? value = document[key];
  if (value == null) {
    throw SettingsFormatException('Key "$key" must not be null.');
  }
  return value;
}

String _readString(Map<String, Object?> document, String key) {
  final Object? value = _lookUp(document, key);
  if (value == null) {
    throw SettingsFormatException('Key "$key" is required but missing.');
  }
  if (value is! String) {
    throw SettingsFormatException('Key "$key" must be a string.');
  }
  return value;
}

int _readInt(Map<String, Object?> document, String key, {required int orElse}) {
  final Object? value = _lookUp(document, key);
  if (value == null) {
    return orElse;
  }
  if (value is int) {
    return value;
  }
  if (value is double && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw SettingsFormatException('Key "$key" must be a whole number.');
}

bool _readBool(
  Map<String, Object?> document,
  String key, {
  required bool orElse,
}) {
  final Object? value = _lookUp(document, key);
  if (value == null) {
    return orElse;
  }
  if (value is! bool) {
    throw SettingsFormatException('Key "$key" must be a boolean.');
  }
  return value;
}

List<String> _readTags(Map<String, Object?> document, String key) {
  final Object? value = _lookUp(document, key);
  if (value == null) {
    return const <String>[];
  }
  if (value is! List<Object?>) {
    throw SettingsFormatException('Key "$key" must be a list of strings.');
  }
  final tags = <String>[];
  for (final Object? entry in value) {
    if (entry is! String) {
      throw SettingsFormatException('Key "$key" must only hold strings.');
    }
    if (entry.isEmpty) {
      throw SettingsFormatException('Key "$key" must not hold an empty tag.');
    }
    tags.add(entry);
  }
  return tags;
}
