import 'package:flutter/material.dart';

import '../data/session.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Mode { login, register, registered, forgot }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _mode = _Mode.login;
  var _busy = false;
  var _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = SessionScope.read(context);
      if (session.expired) {
        session.expired = false;
        showMsg(context, context.t.sessionExpired, error: true);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final api = context.api;
    try {
      switch (_mode) {
        case _Mode.login:
          await context.session.login(_email.text, _password.text);
          return; // root switches to the home screen
        case _Mode.register:
          await api.register(_email.text.trim(), _username.text.trim(), _password.text);
          if (mounted) setState(() => _mode = _Mode.registered);
        case _Mode.forgot:
          await api.forgotPassword(_email.text.trim());
          if (mounted) {
            showMsg(context, context.t.resetLinkSent);
            setState(() => _mode = _Mode.login);
          }
        case _Mode.registered:
          break;
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('assets/logo.png', width: 88, height: 88),
                  ),
                  const SizedBox(height: 16),
                  Text(t.appName, style: context.tt.headlineSmall),
                  const SizedBox(height: 4),
                  Text(t.authSubtitle, style: context.tt.bodyMedium!.copyWith(color: context.c.muted)),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _mode == _Mode.registered ? _registered(context) : _formBody(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(t.authFooter, style: context.tt.bodySmall!.copyWith(color: context.c.faint)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _registered(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        Icon(Icons.mark_email_read_outlined, size: 48, color: context.c.accent),
        const SizedBox(height: 12),
        Text(t.registeredTitle, style: context.tt.titleLarge),
        const SizedBox(height: 12),
        Text(
          t.registeredText(_email.text.trim()),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.c.soft),
        ),
        const SizedBox(height: 8),
        Text(
          t.registeredSpam,
          textAlign: TextAlign.center,
          style: context.tt.bodySmall!.copyWith(color: context.c.faint),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: t.toLogin,
            onPressed: () => setState(() {
              _mode = _Mode.login;
              _password.clear();
            }),
          ),
        ),
      ],
    );
  }

  Widget _formBody(BuildContext context) {
    final t = context.t;
    final forgot = _mode == _Mode.forgot;
    return Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (forgot) ...[
              Text(t.forgotTitle, style: context.tt.titleMedium),
              const SizedBox(height: 6),
              Text(t.forgotSubtitle, style: context.tt.bodySmall),
              const SizedBox(height: 16),
            ] else ...[
              SegmentedButton<_Mode>(
                segments: [
                  ButtonSegment(value: _Mode.login, label: Text(t.loginTab)),
                  ButtonSegment(value: _Mode.register, label: Text(t.registerTab)),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: t.emailLabel),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: (v) => (v ?? '').contains('@') ? null : t.requiredField,
            ),
            if (_mode == _Mode.register) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(labelText: t.usernameLabel),
                autofillHints: const [AutofillHints.newUsername],
                textInputAction: TextInputAction.next,
                validator: requiredText(context),
              ),
            ],
            if (!forgot) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: t.passwordLabel,
                  helperText: _mode == _Mode.register ? t.passwordRulesHint : null,
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                autofillHints: [_mode == _Mode.register ? AutofillHints.newPassword : AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: requiredText(context),
              ),
            ],
            const SizedBox(height: 20),
            GradientButton(
              label: switch (_mode) {
                _Mode.register => t.registerButton,
                _Mode.forgot => t.sendResetLink,
                _ => t.loginButton,
              },
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            if (_mode == _Mode.login)
              TextButton(onPressed: () => setState(() => _mode = _Mode.forgot), child: Text(t.forgotPassword)),
            if (forgot) TextButton(onPressed: () => setState(() => _mode = _Mode.login), child: Text(t.back)),
          ],
        ),
      ),
    );
  }
}
