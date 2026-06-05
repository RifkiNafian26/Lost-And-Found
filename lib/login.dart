import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lostandfound/api_config.dart';
import 'package:lostandfound/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  String _message = '';

  Future<void> login() async {
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    final String endpoint = _isRegister ? 'register.php' : 'login.php';
    final String url = '$apiBaseUrl/$endpoint';

    final Map<String, String> bodyData = _isRegister
        ? {'name': name, 'email': email, 'password': password}
        : {'email': email, 'password': password};

    final response = await http.post(Uri.parse(url), body: bodyData);

    final data = json.decode(response.body);

    if (response.statusCode != 200) {
      setState(() {
        _message = data['message']?.toString() ?? 'Login gagal';
      });
      return;
    }

    if (_isRegister) {
      setState(() {
        _isRegister = false;
        _message = 'Registrasi berhasil, silakan masuk';
      });
      return;
    }

    final user = Map<String, dynamic>.from(data['user']);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LaporanScreen(
          userId: int.parse(user['id'].toString()),
          userName: user['name'].toString(),
          role: user['role'].toString(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.travel_explore,
                      size: 64,
                      color: Color(0xFF0F766E),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Lost and Found',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF12312D),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aplikasi untuk melaporkan barang hilang dan ditemukan dengan mudah.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _isRegister &&
                                (value == null || value.trim().isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password minimal 6 karakter'
                          : null,
                    ),
                    const SizedBox(
                      height: 22,
                    ), // Menggabungkan space yang menggantung tadi
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isRegister ? Icons.person_add_alt : Icons.login,
                            ),
                      label: Text(_isRegister ? 'Daftar' : 'Masuk'),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister
                            ? 'Sudah punya akun? Masuk'
                            : 'Belum punya akun? Daftar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    try {
      await login();
    } catch (e) {
      return;
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
