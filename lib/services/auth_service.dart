import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class AuthService {
  final SupabaseClient? _supabase;
  AppUser? _currentUser;
  final _authStateController = StreamController<AppUser?>.broadcast();

  AuthService(this._supabase) {
    _initFromSupabase();
  }

  AppUser? get currentUser => _currentUser;
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  void _initFromSupabase() {
    final client = _supabase;
    if (client == null) return;

    final session = client.auth.currentSession;
    if (session?.user != null) {
      _currentUser = _mapSupabaseUser(session!.user);
    }

    client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _currentUser = _mapSupabaseUser(user);
      } else {
        _currentUser = null;
      }
      _authStateController.add(_currentUser);
    });
  }

  AppUser _mapSupabaseUser(User user) {
    final meta = user.userMetadata ?? {};
    final roleStr = meta['role'] as String?;
    final role = (roleStr == 'staff' || roleStr == 'agent' || roleStr == 'admin')
        ? UserRole.staff
        : UserRole.client;
    final name = meta['name'] as String? ?? (user.email ?? 'Utilisateur').split('@').first;

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: name,
      role: role,
    );
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) {
      // Offline fallback: create session from email
      final isStaff = email.toLowerCase().contains('agent') || email.toLowerCase().contains('admin');
      final user = AppUser(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: email.split('@').first,
        role: isStaff ? UserRole.staff : UserRole.client,
      );
      _currentUser = user;
      _authStateController.add(user);
      return user;
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw Exception('Identifiants invalides');
      final appUser = _mapSupabaseUser(user);
      _currentUser = appUser;
      _authStateController.add(appUser);
      return appUser;
    } catch (e) {
      debugPrint('Auth sign-in error: $e');
      rethrow;
    }
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final client = _supabase;
    if (client == null) {
      final user = AppUser(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        role: role,
      );
      _currentUser = user;
      _authStateController.add(user);
      return user;
    }

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.name,
        },
      );
      final user = response.user;
      if (user == null) throw Exception('Impossible de créer le compte');
      final appUser = _mapSupabaseUser(user);
      _currentUser = appUser;
      _authStateController.add(appUser);
      return appUser;
    } catch (e) {
      debugPrint('Auth sign-up error: $e');
      rethrow;
    }
  }

  Future<AppUser> signInAsDemo({
    required String name,
    required UserRole role,
  }) async {
    final user = AppUser(
      id: 'demo_${role.name}_${DateTime.now().millisecondsSinceEpoch}',
      email: '${name.toLowerCase().replaceAll(' ', '.')}@waitingroom.local',
      name: name,
      role: role,
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  Future<void> signOut() async {
    final client = _supabase;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
