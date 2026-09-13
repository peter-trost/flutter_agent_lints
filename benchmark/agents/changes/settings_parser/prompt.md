Extend `lib/settings.dart` in this Flutter app. It already implements
`Settings`, `SettingsFormatException` and `parseSettings`, and
`test/settings_test.dart` covers them; keep every existing test passing.
Add a field to `Settings`:

```dart
class Settings {
  const Settings({
    required this.username,
    this.fontSize = 14,
    this.darkMode = false,
    this.tags = const [],
    this.locale = 'en',
  });

  final String locale; // optional, default 'en'
}
```

Rules:

- A valid `locale` is two lowercase ASCII letters, optionally followed by
  an underscore and two uppercase ASCII letters: `en` and `de_DE` are
  valid; `EN`, `de-DE`, `deu` and `de_de` are not.
- `parseSettings` reads the `locale` key. A value that is not a string, or
  a string that is not valid, throws `SettingsFormatException` with a
  message that contains `locale`.
- `locale` takes part in `toJson`, `==` and `hashCode`, and the round trip
  `parseSettings(jsonEncode(settings.toJson()))` still equals `settings`.

Finish when `dart analyze` reports no issues and `dart format .` changes
nothing. Do not edit `analysis_options.yaml` and do not add `ignore`
comments. You may add tests of your own under `test/`.
