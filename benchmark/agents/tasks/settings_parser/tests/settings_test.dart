import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/settings.dart';

void main() {
  test('parses a full document', () {
    final s = parseSettings(
      '{"username":"ada","fontSize":20,"darkMode":true,"tags":["a","b"]}',
    );
    expect(s.username, 'ada');
    expect(s.fontSize, 20);
    expect(s.darkMode, isTrue);
    expect(s.tags, ['a', 'b']);
  });

  test('applies defaults for optional keys', () {
    final s = parseSettings('{"username":"ada"}');
    expect(s.fontSize, 14);
    expect(s.darkMode, isFalse);
    expect(s.tags, isEmpty);
  });

  test('ignores unknown keys', () {
    expect(parseSettings('{"username":"ada","theme":"x"}').username, 'ada');
  });

  test('missing username names the key', () {
    expect(
      () => parseSettings('{"fontSize":12}'),
      throwsA(
        isA<SettingsFormatException>().having(
          (e) => e.message,
          'message',
          contains('username'),
        ),
      ),
    );
  });

  test('empty username is rejected', () {
    expect(
      () => parseSettings('{"username":""}'),
      throwsA(isA<SettingsFormatException>()),
    );
  });

  test('fontSize of the wrong type names the key', () {
    expect(
      () => parseSettings('{"username":"ada","fontSize":"14"}'),
      throwsA(
        isA<SettingsFormatException>().having(
          (e) => e.message,
          'message',
          contains('fontSize'),
        ),
      ),
    );
  });

  test('fontSize with a fraction is the wrong type', () {
    expect(
      () => parseSettings('{"username":"ada","fontSize":14.5}'),
      throwsA(isA<SettingsFormatException>()),
    );
  });

  test('fontSize outside 8..72 is rejected', () {
    expect(
      () => parseSettings('{"username":"ada","fontSize":100}'),
      throwsA(isA<SettingsFormatException>()),
    );
    expect(parseSettings('{"username":"ada","fontSize":8}').fontSize, 8);
    expect(parseSettings('{"username":"ada","fontSize":72}').fontSize, 72);
  });

  test('darkMode of the wrong type names the key', () {
    expect(
      () => parseSettings('{"username":"ada","darkMode":"yes"}'),
      throwsA(
        isA<SettingsFormatException>().having(
          (e) => e.message,
          'message',
          contains('darkMode'),
        ),
      ),
    );
  });

  test('tags with a non-string or an empty string are rejected', () {
    expect(
      () => parseSettings('{"username":"ada","tags":["a",1]}'),
      throwsA(isA<SettingsFormatException>()),
    );
    expect(
      () => parseSettings('{"username":"ada","tags":[""]}'),
      throwsA(isA<SettingsFormatException>()),
    );
    expect(
      () => parseSettings('{"username":"ada","tags":"a"}'),
      throwsA(isA<SettingsFormatException>()),
    );
  });

  test('invalid JSON and non-object documents throw the same exception', () {
    expect(
      () => parseSettings('{username: ada'),
      throwsA(isA<SettingsFormatException>()),
    );
    expect(
      () => parseSettings('["ada"]'),
      throwsA(isA<SettingsFormatException>()),
    );
    expect(
      () => parseSettings('null'),
      throwsA(isA<SettingsFormatException>()),
    );
  });

  test('toJson round-trips and equality covers every field', () {
    const s = Settings(
      username: 'ada',
      fontSize: 30,
      darkMode: true,
      tags: ['x'],
    );
    expect(parseSettings(jsonEncode(s.toJson())), s);
    expect(
      s,
      const Settings(
        username: 'ada',
        fontSize: 30,
        darkMode: true,
        tags: ['x'],
      ),
    );
    expect(
      s,
      isNot(const Settings(username: 'ada', fontSize: 30, darkMode: true)),
    );
    expect(
      s.hashCode,
      const Settings(
        username: 'ada',
        fontSize: 30,
        darkMode: true,
        tags: ['x'],
      ).hashCode,
    );
  });
}
