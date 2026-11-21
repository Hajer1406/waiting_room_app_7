import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/app_user.dart';
import 'package:waiting_room_app/providers/auth_provider.dart';
import 'package:waiting_room_app/services/auth_service.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthService authService;
    late AuthProvider authProvider;

    setUp(() {
      authService = AuthService(null); // Offline/mock mode
      authProvider = AuthProvider(authService);
    });

    tearDown(() {
      authService.dispose();
    });

    test('Initial state is not authenticated', () {
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.isLoading, isFalse);
    });

    test('signInAsDemo with staff role creates staff user', () async {
      await authProvider.signInAsDemo(
        name: 'Dr. Test',
        role: UserRole.staff,
      );

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.name, 'Dr. Test');
      expect(authProvider.user?.role, UserRole.staff);
      expect(authProvider.isStaff, isTrue);
      expect(authProvider.isClient, isFalse);
    });

    test('signInAsDemo with client role creates client user', () async {
      await authProvider.signInAsDemo(
        name: 'Patient Sarah',
        role: UserRole.client,
      );

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.name, 'Patient Sarah');
      expect(authProvider.user?.role, UserRole.client);
      expect(authProvider.isStaff, isFalse);
      expect(authProvider.isClient, isTrue);
    });

    test('signOut resets user to null', () async {
      await authProvider.signInAsDemo(
        name: 'Dr. Martin',
        role: UserRole.staff,
      );
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.signOut();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
    });

    test('signIn in offline mode works with email fallback', () async {
      final success = await authProvider.signIn(
        email: 'agent@clinic.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isStaff, isTrue);
    });

    test('signUp in offline mode preserves custom role', () async {
      final success = await authProvider.signUp(
        email: 'alice@example.com',
        password: 'password123',
        name: 'Alice',
        role: UserRole.client,
      );

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.name, 'Alice');
      expect(authProvider.isClient, isTrue);
    });
  });
}
