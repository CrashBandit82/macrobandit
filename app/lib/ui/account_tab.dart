import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/session.dart';
import 'theme.dart';
import 'widgets.dart';

const _files = MethodChannel('at.macrobandit.app/files');

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    final session = SessionScope.of(context);
    final user = session.user;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: t.changeAvatar,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _avatarMenu(context),
                        child: UserAvatar(user: user),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.username, style: context.tt.titleLarge),
                          Text(user.email, style: context.tt.bodyMedium!.copyWith(color: c.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _item(
                        context,
                        Icons.person_outline,
                        t.changeUsername,
                        user.username,
                        () => _changeUsername(context),
                      ),
                      const Divider(),
                      _item(context, Icons.key_outlined, t.changePassword, null, () => _changePassword(context)),
                      const Divider(),
                      _item(context, Icons.photo_camera_outlined, t.changeAvatar, null, () => _avatarMenu(context)),
                      const Divider(),
                      _item(context, Icons.download_outlined, t.exportTitle, t.exportSub, () => _export(context)),
                      const Divider(),
                      _item(
                        context,
                        Icons.chat_bubble_outline,
                        t.feedbackTitle,
                        t.feedbackSub,
                        () => _feedback(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.themeTitle, style: context.tt.titleSmall),
                        const SizedBox(height: 10),
                        SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(t.themeSystem),
                              icon: const Icon(Icons.brightness_auto_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(t.themeLight),
                              icon: const Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(t.themeDark),
                              icon: const Icon(Icons.dark_mode_outlined),
                            ),
                          ],
                          selected: {session.themeMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => session.setThemeMode(s.first),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _item(context, Icons.logout, t.logout, t.logoutSub, () => context.session.logout()),
                      const Divider(),
                      _item(
                        context,
                        Icons.delete_forever_outlined,
                        t.deleteAccount,
                        t.deleteAccountSub,
                        () => _deleteAccount(context),
                        danger: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Crash',
                          style: TextStyle(color: dark ? const Color(0xFFFB923C) : const Color(0xFFC2410C)),
                        ),
                        TextSpan(
                          text: 'Bandit',
                          style: TextStyle(color: c.accent),
                        ),
                        TextSpan(
                          text: '82',
                          style: TextStyle(color: c.faint, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    style: context.tt.titleSmall,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text('macrobandit.at', style: context.tt.bodySmall!.copyWith(color: c.faint)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String? sub,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final c = context.c;
    return ListTile(
      leading: Icon(icon, color: danger ? c.fatText : null),
      title: Text(title, style: danger ? TextStyle(color: c.fatText) : null),
      subtitle: sub == null ? null : Text(sub, overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.chevron_right, color: c.faint),
      onTap: onTap,
    );
  }

  Future<void> _avatarMenu(BuildContext context) async {
    final t = context.t;
    final hasAvatar = context.session.user.avatarPath != null;
    final remove = await showModalBottomSheet<bool>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.changeAvatar),
              onTap: () => Navigator.pop(c, false),
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(t.removeAvatar),
                onTap: () => Navigator.pop(c, true),
              ),
          ],
        ),
      ),
    );
    if (remove == null || !context.mounted) return;
    final session = context.session;
    try {
      if (remove) {
        session.updateUser(await session.api.deleteAvatar());
        return;
      }
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null || !context.mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (context.mounted) showMsg(context, t.avatarTooBig, error: true);
        return;
      }
      final name = file.name.toLowerCase();
      final mime = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
      session.updateUser(await session.api.uploadAvatar(bytes, file.name, mime));
      if (context.mounted) showMsg(context, t.avatarUpdated);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _changeUsername(BuildContext context) async {
    final t = context.t;
    final session = context.session;
    final name = await _prompt(context, t.changeUsername, t.newUsername, initial: session.user.username);
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    try {
      session.updateUser(await session.api.changeUsername(name.trim()));
      if (context.mounted) showMsg(context, t.usernameChanged);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final ok = await showSheet<bool>(context, (_) => const _PasswordSheet());
    if (ok == true && context.mounted) showMsg(context, context.t.passwordChanged);
  }

  Future<void> _export(BuildContext context) async {
    final t = context.t;
    try {
      final Uint8List csv = await context.api.exportCsv();
      final now = DateTime.now();
      final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final saved = await _files.invokeMethod<bool>('saveFile', {
        'name': 'macrobandit_export_$stamp.csv',
        'mime': 'text/csv',
        'bytes': csv,
      });
      if (saved == true && context.mounted) showMsg(context, t.exportSaved);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _feedback(BuildContext context) async {
    final t = context.t;
    final msg = await _prompt(context, t.feedbackTitle, t.feedbackHint, multiline: true, action: t.send);
    if (msg == null || !context.mounted) return;
    if (msg.trim().length < 5) {
      showMsg(context, t.feedbackMin, error: true);
      return;
    }
    try {
      await context.api.sendFeedback(msg.trim());
      if (context.mounted) showMsg(context, t.feedbackThanks);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await showSheet<bool>(context, (_) => const _DeleteSheet());
    if (ok == true && context.mounted) await context.session.logout();
  }

  Future<String?> _prompt(
    BuildContext context,
    String title,
    String label, {
    String initial = '',
    bool multiline = false,
    String? action,
  }) => showDialog<String>(
    context: context,
    builder: (_) => PromptDialog(
      title: title,
      label: label,
      initial: initial,
      multiline: multiline,
      maxLength: multiline ? 2000 : 50,
      action: action,
    ),
  );
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.api.changePassword(_current.text, _next.text);
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.changePassword, style: context.tt.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: InputDecoration(labelText: t.currentPassword),
              validator: requiredText(context),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(labelText: t.newPassword, helperText: t.passwordRulesHint, helperMaxLines: 2),
              validator: requiredText(context),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _repeat,
              obscureText: true,
              decoration: InputDecoration(labelText: t.confirmPassword),
              validator: (v) => v != _next.text ? t.passwordMismatch : null,
            ),
            const SizedBox(height: 20),
            GradientButton(label: t.changePassword, busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet();

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  final _password = TextEditingController();
  final _word = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _word.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _word.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await context.api.deleteAccount(_password.text);
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final word = t.deleteConfirmWord;
    final ready = _word.text.trim() == word && _password.text.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.deleteAccount, style: context.tt.titleLarge!.copyWith(color: context.c.fatText)),
          const SizedBox(height: 12),
          Text(t.deleteWarning, style: TextStyle(color: context.c.soft)),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: t.currentPassword),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _word,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: t.deleteConfirmLabel(word)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.c.error, foregroundColor: Colors.white),
            onPressed: ready && !_busy ? _delete : null,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(t.deleteFinal),
          ),
        ],
      ),
    );
  }
}
