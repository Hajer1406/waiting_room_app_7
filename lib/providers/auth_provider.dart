import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService) {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isStaff => _user?.role.isStaff ?? false;
  bool get isClient => _user?.role.isClient ?? true;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signInAsDemo({
    required String name,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _user = await _authService.signInAsDemo(name: name, role: role);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  String _cleanErrorMessage(String raw) {
    if (raw.contains('email rate limit exceeded') || raw.contains('over_email_send_rate_limit')) {
      return 'Limite d\'emails Supabase atteinte (429). Pour la désactiver : dans Supabase > Auth > Providers > Email, décochez "Confirm email". En attendant, utilisez les boutons Démo ci-dessous.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Email non confirmé par Supabase. Décochez "Confirm email" dans Supabase (Auth > Providers > Email) pour vous connecter directement sans validation d\'email.';
    }
    if (raw.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect. Assurez-vous d\'avoir bien créé ce compte ou d\'avoir le bon mot de passe.';
    }
    if (raw.contains('User already registered')) {
      return 'Cet email est déjà enregistré. Rendez-vous sur l\'onglet "Connexion".';
    }
    if (raw.contains('Password should be at least')) {
      return 'Le mot de passe doit comporter au moins 6 caractères.';
    }
    return raw.replaceFirst('Exception: ', '').replaceFirst('AuthApiException: ', '');
  }
}
