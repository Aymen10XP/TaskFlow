import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/l10n/app_strings.dart';

void main() {
  test('translations cover the three supported languages', () {
    expect(AppStrings.supportedLocales, const [
      Locale('fr'),
      Locale('en'),
      Locale('ar'),
    ]);
    expect(AppStrings(const Locale('fr')).get('dashboard'), 'Tableau de bord');
    expect(AppStrings(const Locale('en')).get('dashboard'), 'Dashboard');
    expect(AppStrings(const Locale('ar')).get('dashboard'), 'لوحة التحكم');
  });
}
