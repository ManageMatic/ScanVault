import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanvault/app/app.dart';
import 'package:scanvault/core/services/preferences_service.dart';

void main() {
  testWidgets('ScanVault app launches and renders splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.create();

    await tester.pumpWidget(ScanVaultApp(preferencesService: prefs));
    await tester.pump();

    // Verify RichText containing ScanVault
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('ScanVault'),
      ),
      findsWidgets,
    );

    // Verify Tagline
    expect(find.text('Offline-First Document Vault & PDF Studio'), findsOneWidget);
  });
}
