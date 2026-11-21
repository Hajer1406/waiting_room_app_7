import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final success = await auth.signUp(
        email: email,
        password: password,
        name: name.isEmpty ? email.split('@').first : name,
        role: _selectedRole,
      );
      if (!mounted) return;
      if (!success && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      final success = await auth.signIn(email: email, password: password);
      if (!mounted) return;
      if (!success && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.meeting_room_outlined,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Salle d\'Attente',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSignUp
                            ? 'Créez votre compte pour rejoindre la file'
                            : 'Connectez-vous pour accéder à votre espace',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Mode switch (Connexion / Inscription)
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Connexion'),
                            icon: Icon(Icons.login),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Inscription'),
                            icon: Icon(Icons.person_add),
                          ),
                        ],
                        selected: {_isSignUp},
                        onSelectionChanged: (set) {
                          setState(() {
                            _isSignUp = set.first;
                            auth.clearError();
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Name field (if sign up)
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_isSignUp && (value == null || value.trim().isEmpty)) {
                              return 'Veuillez saisir votre nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Role selection
                        Text(
                          'Rôle utilisateur :',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('👤 Client / Patient'),
                                selected: _selectedRole == UserRole.client,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedRole = UserRole.client);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('👨‍⚕️ Agent / Staff'),
                                selected: _selectedRole == UserRole.staff,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedRole = UserRole.staff);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez renseigner votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Format d\'email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Minimum 6 caractères requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Créer mon compte' : 'Se connecter',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Accès rapide (Démonstration)',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.local_hospital_outlined, size: 18),
                              label: const Text('Agent (Dr)'),
                              onPressed: auth.isLoading
                                  ? null
                                  : () => auth.signInAsDemo(
                                        name: 'Dr. Martin',
                                        role: UserRole.staff,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_outline, size: 18),
                              label: const Text('Client (Patient)'),
                              onPressed: auth.isLoading
                                  ? null
                                  : () => auth.signInAsDemo(
                                        name: 'Patient Sarah',
                                        role: UserRole.client,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
