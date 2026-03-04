import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sync_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  late final SyncService _sync;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _sync = SyncService();
    _online = _sync.isOnline;
    _sync.onlineStream.listen((v) {
      if (!mounted) return;
      setState(() => _online = v);
    });
  }

  Future<void> _login() async {
    if (!_online) {
      setState(() => _error = 'No internet connection');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (_) {
      try {
        await client.auth.signUp(email: email, password: password);
        await client.auth.signInWithPassword(email: email, password: password);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } catch (e) {
        setState(() => _error = 'Login failed');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            SvgPicture.asset(
              'assets/images/jajo_motorparts_logo.svg',
              height: 64,
            ),
            const SizedBox(height: 12),
            if (!_online)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('Connect to the internet to sign in')),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
