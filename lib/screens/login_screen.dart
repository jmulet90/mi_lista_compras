import 'package:flutter/material.dart';
import '/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión / Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Correo"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Contraseña (mínimo 6 caracteres)"),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                setState(() => _isLoading = true);

                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Rellena todos los campos")),
                  );
                  setState(() => _isLoading = false);
                  return;
                }

                // 1. Intentamos iniciar sesión primero
                var user = await _authService.signInWithEmailAndPassword(email, password);

                // 2. Si no existe (falla el login), intentamos registrarlo automáticamente
                if (user == null) {
                  user = await _authService.registerWithEmailAndPassword(email, password);
                }

                setState(() => _isLoading = false);

                if (user == null) {
                  // Si aun así falla, mostramos error (contraseña corta, formato inválido, etc.)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error: Verifica el correo o usa una contraseña de al menos 6 caracteres")),
                  );
                }
              },
              child: const Text("Ingresar / Crear cuenta"),
            ),
          ],
        ),
      ),
    );
  }
}