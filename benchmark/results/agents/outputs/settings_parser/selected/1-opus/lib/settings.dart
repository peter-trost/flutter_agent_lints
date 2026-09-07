import 'dart:convert';

/// The JSON keys understood by [Settings.toJson] and [parseSettings].
const String _usernameKey = 'username';
const String _fontSizeKey = 'fontSize';
const String _darkModeKey = 'darkMode';
const String _tagsKey = 'tags';

/// The value used for [Settings.fontSize] when the key is absent.
const int _defaultFontSize = 14;

/// The inclusive bounds accepted for [Settings.fontSize].
const int _minFontSize = 8;
const int _maxFontSize = 72;

/// The user preferences of the application.
class Settings {
  /// Creates a settings value.
  ///
  /// [username] must not be empty, [fontSize] must lie within `8..72` and
  /// every entry of [tags] must be a non-empty string. Values produced by
  /// [parseSettings] always satisfy those constraints.
  const Settings({
    required this.username,
    this.fontSize = _defaultFontSize,
    this.darkMode = false,
    this.tags = const <String>[],
  });

  /// The name the settings belong to. Never empty.
  final String username;

  /// The preferred font size, within `8..72`.
  final int fontSize;

  /// Whether the dark colour scheme is preferred.
  final bool darkMode;

  /// The labels attached to the account. Every entry is non-empty.
  final List<String> tags;

  /// Returns a JSON representation of these settings.
  ///
  /// `parseSettings(jsonEncode(settings.toJson()))` is equal to `settings`.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      _usernameKey: username,
      _fontSizeKey: fontSize,
      _darkModeKey: darkMode,
      _tagsKey: List<String>.of(tags),
    };
  }

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
}

/// Thrown by [parseSettings] when a document cannot be read as [Settings].
///
/// The [message] names the offending key whenever the failure can be
/// attributed to one.
class SettingsFormatException implements Exception {
  /// Creates an exception describing why a document was rejected.
  const SettingsFormatException(this.message);

  /// A human readable description of the failure.
  final String message;

  @override
  String toString() => 'SettingsFormatException: $message';
}

/// Reads [json] as a settings document.
///
/// Throws a [SettingsFormatException], and nothing else, when [json] is not
/// valid JSON, when its top level is not an object, or when a value is
/// missing, of the wrong type, or out of range. Unknown keys are ignored.
Settings parseSettings(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (error) {
    throw SettingsFormatException(
      'The text is not valid JSON: ${error.message}',
    );
  }

  if (decoded is! Map<String, Object?>) {
    throw const SettingsFormatException(
      'The top level of the document must be a JSON object.',
    );
  }

  return Settings(
    username: _readUsername(decoded[_usernameKey]),
    fontSize: _readFontSize(decoded[_fontSizeKey]),
    darkMode: _readDarkMode(decoded[_darkModeKey]),
    tags: _readTags(decoded[_tagsKey]),
  );
}

String _readUsername(Object? value) {
  if (value == null) {
    throw const SettingsFormatException(
      "The required key '$_usernameKey' is missing.",
    );
  }
  if (value is! String) {
    throw const SettingsFormatException(
      "The value of '$_usernameKey' must be a string.",
    );
  }
  if (value.isEmpty) {
    throw const SettingsFormatException(
      "The value of '$_usernameKey' must not be empty.",
    );
  }
  return value;
}

int _readFontSize(Object? value) {
  if (value == null) {
    return _defaultFontSize;
  }

  final int fontSize;
  if (value is int) {
    fontSize = value;
  } else if (value is double &&
      value.isFinite &&
      value.truncateToDouble() == value) {
    fontSize = value.toInt();
  } else {
    throw const SettingsFormatException(
      "The value of '$_fontSizeKey' must be an integer.",
    );
  }

  if (fontSize < _minFontSize || fontSize > _maxFontSize) {
    throw SettingsFormatException(
      "The value of '$_fontSizeKey' must be within "
      '$_minFontSize..$_maxFontSize, but was $fontSize.',
    );
  }
  return fontSize;
}

bool _readDarkMode(Object? value) {
  if (value == null) {
    return false;
  }
  if (value is! bool) {
    throw const SettingsFormatException(
      "The value of '$_darkModeKey' must be a boolean.",
    );
  }
  return value;
}

List<String> _readTags(Object? value) {
  if (value == null) {
    return const <String>[];
  }
  if (value is! List<Object?>) {
    throw const SettingsFormatException(
      "The value of '$_tagsKey' must be a list of strings.",
    );
  }

  final List<String> tags = <String>[];
  for (final Object? element in value) {
    if (element is! String) {
      throw const SettingsFormatException(
        "Every element of '$_tagsKey' must be a string.",
      );
    }
    if (element.isEmpty) {
      throw const SettingsFormatException(
        "Every element of '$_tagsKey' must not be empty.",
      );
    }
    tags.add(element);
  }
  return List<String>.unmodifiable(tags);
}

bool _tagsEqual(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
