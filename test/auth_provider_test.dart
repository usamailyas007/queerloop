// Tests for AuthProvider, running against the mock AuthService.

import 'package:flutter_test/flutter_test.dart';
import 'package:queerloop/core/api/api_client.dart';
import 'package:queerloop/features/auth/auth_provider.dart';

AuthProvider buildProvider() =>
    AuthProvider(client: ApiClient(baseUrl: 'https://test.local'));

void main() {
  group('AuthProvider', () {
    test('starts unknown and resolves to signedOut on restore', () async {
      final AuthProvider provider = buildProvider();

      expect(provider.status, AuthStatus.unknown);

      await provider.restoreSession();

      expect(provider.status, AuthStatus.signedOut);
      expect(provider.isSignedIn, isFalse);
    });

    test('restoreSession does not override a signed in session', () async {
      final AuthProvider provider = buildProvider();
      await provider.signIn(email: 'user@example.com', password: 'secret');

      await provider.restoreSession();

      expect(provider.status, AuthStatus.signedIn);
    });

    test('rejects an invalid email without calling the service', () async {
      final AuthProvider provider = buildProvider();

      final bool result =
          await provider.signIn(email: 'not-an-email', password: 'secret');

      expect(result, isFalse);
      expect(provider.status, AuthStatus.unknown);
      expect(provider.error, isNotNull);
    });

    test('rejects an empty password', () async {
      final AuthProvider provider = buildProvider();

      final bool result =
          await provider.signIn(email: 'user@example.com', password: '');

      expect(result, isFalse);
      expect(provider.isSignedIn, isFalse);
    });

    test('signs in with a normalized user and clears the error', () async {
      final AuthProvider provider = buildProvider();
      await provider.signIn(email: 'bad', password: '');

      final bool result =
          await provider.signIn(email: '  User@Example.com ', password: 'secret');

      expect(result, isTrue);
      expect(provider.status, AuthStatus.signedIn);
      expect(provider.user?.email, 'user@example.com');
      expect(provider.error, isNull);
      expect(provider.isBusy, isFalse);
    });

    test('signOut clears the session', () async {
      final AuthProvider provider = buildProvider();
      await provider.signIn(email: 'user@example.com', password: 'secret');

      await provider.signOut();

      expect(provider.status, AuthStatus.signedOut);
      expect(provider.user, isNull);
    });

    test('notifies listeners on every state change', () async {
      final AuthProvider provider = buildProvider();
      final List<AuthStatus> seen = <AuthStatus>[];
      provider.addListener(() => seen.add(provider.status));

      await provider.restoreSession();
      await provider.signIn(email: 'user@example.com', password: 'secret');
      await provider.signOut();

      expect(seen.first, AuthStatus.signedOut);
      expect(seen.contains(AuthStatus.signedIn), isTrue);
      expect(seen.last, AuthStatus.signedOut);
    });
  });
}
