import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/providers/auth_provider.dart';
import 'package:waiting_room_app/screens/login_screen.dart';
import 'package:waiting_room_app/services/auth_service.dart';

Widget _buildTestLoginScreen(AuthProvider authProvider) {
  return MaterialApp(
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const LoginScreen(),
    ),
  );
}

void main() {
  group('LoginScreen Tests', () {
    late AuthService authService;
    late AuthProvider authProvider;

    setUp(() {
      authService = AuthService(null);
      authProvider = AuthProvider(authService);
    });

    tearDown(() {
      authService.dispose();
    });

    testWidgets('Renders professional login screen with Connexion and Inscription options',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestLoginScreen(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Salle d\'Attente'), findsOneWidget);
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.text('Inscription'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('Switching to Inscription shows Name field and Role chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestLoginScreen(authProvider));
      await tester.pumpAndSettle();

      // Tap on Inscription tab
      await tester.tap(find.text('Inscription'));
      await tester.pumpAndSettle();

      expect(find.text('Nom complet'), findsOneWidget);
      expect(find.text('Rôle utilisateur :'), findsOneWidget);
      expect(find.text('👤 Client / Patient'), findsOneWidget);
      expect(find.text('👨‍⚕️ Agent / Staff'), findsOneWidget);
      expect(find.text('Créer mon compte'), findsOneWidget);
    });

    testWidgets('Entering credentials and submitting logs in user',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestLoginScreen(authProvider));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'agent@hospital.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'password123',
      );
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isStaff, isTrue);
      expect(authProvider.user?.email, 'agent@hospital.com');
    });
  });
}
