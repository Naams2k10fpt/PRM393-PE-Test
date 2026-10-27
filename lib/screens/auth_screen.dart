import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_session.dart';
import '../theme.dart';
import '../validation.dart';
import '../widgets/shared.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.register});
  final bool register;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final session = context.read<AuthSession>();
    try {
      if (widget.register) {
        await session.register(_email.text.trim(), _password.text);
      } else {
        await session.login(_email.text.trim(), _password.text);
      }
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.register ? 'Register' : 'Login';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: PageWidth(
          maxWidth: 500,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                size: 42,
                color: ShelfColors.green,
              ),
              const SizedBox(height: 24),
              Text(
                widget.register
                    ? 'Make room for\nyour next chapter.'
                    : 'Welcome back\nto your shelf.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                widget.register
                    ? 'Create an account for your own private library.'
                    : 'Your books and reading notes are waiting for you.',
                style: const TextStyle(color: ShelfColors.muted),
              ),
              const SizedBox(height: 30),
              Form(
                key: _form,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      autofillHints: [
                        widget.register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      textInputAction: widget.register
                          ? TextInputAction.next
                          : TextInputAction.done,
                      validator: (value) =>
                          Validators.password(value, register: widget.register),
                      onChanged: (_) {
                        if (_submitted) _form.currentState!.validate();
                      },
                      onFieldSubmitted: (_) {
                        if (!widget.register && !_busy) _submit();
                      },
                      enabled: !_busy,
                    ),
                    if (widget.register) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) =>
                            Validators.confirmPassword(value, _password.text),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_busy) _submit();
                        },
                        enabled: !_busy,
                      ),
                    ],
                    const SizedBox(height: 26),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(title),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      InlineNotice(_error!, error: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AuthScreen(register: !widget.register),
                        ),
                      ),
                child: Text(
                  widget.register
                      ? 'Already have an account? Login'
                      : 'New here? Register',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
