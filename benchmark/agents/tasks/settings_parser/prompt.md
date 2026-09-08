Implement `lib/settings.dart` in this Flutter app. It must export exactly this
public API:

```dart
class Settings {
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
  });

  final String username;   // required, must not be empty
  final int fontSize;      // optional, default 14, must be within 8..72
  final bool darkMode;     // optional, default false
  final List<String> tags; // optional, default empty, every tag non-empty

  Map<String, Object?> toJson();
}

class SettingsFormatException implements Exception {
  const SettingsFormatException(this.message);
  final String message;
}

Settings parseSettings(String json);
```

Rules for `parseSettings`:

- The text is a JSON document whose top level must be an object; keys
  are `username`, `fontSize`, `darkMode`, `tags`. Unknown keys are ignored.
- A missing required key, a value of the wrong JSON type (an integer key
  given a string, a number with a fractional part, a list containing a
  non-string), or a value outside its range throws
  `SettingsFormatException` with a message that contains the offending key
  name.
- Text that is not valid JSON, or whose top level is not an object, throws
  `SettingsFormatException` as well.
- No other exception type may escape `parseSettings`.
- `Settings` implements `==` and `hashCode` over all four fields, and
  `parseSettings(jsonEncode(settings.toJson()))` equals `settings`.

Finish when `dart analyze` reports no issues and `dart format .` changes
nothing. Do not edit `analysis_options.yaml` and do not add `ignore`
comments. You may add tests of your own under `test/`.
