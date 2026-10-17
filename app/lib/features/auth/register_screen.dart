import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'CUSTOMER';
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).register(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _role,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not create your account. That email or phone may already be in use.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_role == 'PROVIDER' ? 'Create your provider account' : 'Create your account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('I am a...', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'CUSTOMER', label: Text('Customer'), icon: Icon(Icons.search)),
                  ButtonSegment(value: 'PROVIDER', label: Text('Provider'), icon: Icon(Icons.work_outline)),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
              ),
              if (_role == 'PROVIDER') ...[
                const SizedBox(height: 8),
                Text(
                  'New providers start at Star Tier 1. Higher tiers are granted by Moka after verification.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
