import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/settings.dart';

Matcher _namesLocale() => throwsA(
  isA<SettingsFormatException>().having(
    (e) => e.message,
    'message',
    contains('locale'),
  ),
);

void main() {
  test('parses a locale with a region', () {
    expect(
      parseSettings('{"username":"ada","locale":"de_DE"}').locale,
      'de_DE',
    );
    expect(parseSettings('{"username":"ada","locale":"fr"}').locale, 'fr');
  });

  test('defaults to en', () {
    expect(parseSettings('{"username":"ada"}').locale, 'en');
    expect(const Settings(username: 'ada').locale, 'en');
  });

  test('a malformed locale names the key', () {
    for (final bad in ['EN', 'de-DE', 'deu', 'de_de', '', 'e1', 'de_DEU']) {
      expect(
        () => parseSettings('{"username":"ada","locale":"$bad"}'),
        _namesLocale(),
        reason: bad,
      );
    }
  });

  test('a locale of the wrong type names the key', () {
    expect(
      () => parseSettings('{"username":"ada","locale":42}'),
      _namesLocale(),
    );
  });

  test('locale is part of toJson and the round trip', () {
    const settings = Settings(username: 'ada', locale: 'pt_BR');
    expect(settings.toJson()['locale'], 'pt_BR');
    expect(parseSettings(jsonEncode(settings.toJson())), settings);
  });

  test('locale is part of equality and hashCode', () {
    const a = Settings(username: 'ada', locale: 'en_GB');
    const b = Settings(username: 'ada', locale: 'pt_BR');
    expect(a, isNot(equals(b)));
    expect(a, equals(const Settings(username: 'ada', locale: 'en_GB')));
    expect(
      a.hashCode,
      const Settings(username: 'ada', locale: 'en_GB').hashCode,
    );
  });
}
