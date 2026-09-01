// Verifies ModeratorShell renders ARB strings for the active locale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:queerloop/admin/auth/provider/admin_auth_provider.dart';
import 'package:queerloop/admin/moderator_view/moderator_shell.dart';
import 'package:queerloop/core/api/api_client.dart';
import 'package:queerloop/l10n/app_localizations.dart';

Widget wrap(Locale locale) {
  return ChangeNotifierProvider<AdminAuthProvider>(
    create: (BuildContext context) =>
        AdminAuthProvider(client: ApiClient(baseUrl: 'http://localhost')),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ModeratorShell(),
    ),
  );
}

void main() {
  testWidgets('renders English strings', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const Locale('en')));

    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('renders Spanish strings', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const Locale('es')));

    expect(find.text('Administración'), findsOneWidget);
    expect(find.text('Panel'), findsWidgets);
    expect(find.text('Ajustes'), findsOneWidget);
  });
}
