//for temporary log in
import 'package:flutter/material.dart';
import '../core/firebase_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'cuceta@oswego.edu');
  final _passCtrl = TextEditingController(text: '123456');
  final _service = FirebaseService();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.signInWithEmailPassword(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 251, 229),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // 👈 allows scrolling on small screens
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Thrive Wear Login',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(hintText: 'Password'),
                ),
                const SizedBox(height: 10),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 10),
                  ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB6039),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
