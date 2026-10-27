import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/api.dart';
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
                          Text(user.username.isEmpty ? t.profileTitle : user.username, style: context.tt.titleLarge),
                          Text(t.localDataInfo, style: context.tt.bodyMedium!.copyWith(color: c.muted)),
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
                        user.username.isEmpty ? null : user.username,
                        () => _changeUsername(context),
                      ),
                      const Divider(),
                      _item(context, Icons.photo_camera_outlined, t.changeAvatar, null, () => _avatarMenu(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _item(context, Icons.save_outlined, t.backupTitle, t.backupSub, () => _backup(context)),
                      const Divider(),
                      _item(context, Icons.restore, t.restoreTitle, t.restoreSub, () => _restore(context)),
                      const Divider(),
                      _item(context, Icons.download_outlined, t.exportTitle, t.exportSub, () => _export(context)),
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
                            segment(ThemeMode.system, t.themeSystem),
                            segment(ThemeMode.light, t.themeLight),
                            segment(ThemeMode.dark, t.themeDark),
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
                  child: _item(
                    context,
                    Icons.delete_forever_outlined,
                    t.deleteAllData,
                    t.deleteAllDataSub,
                    () => _deleteAll(context),
                    danger: true,
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
                  child: SelectableText(
                    'github.com/CrashBandit82/macrobandit',
                    style: context.tt.bodySmall!.copyWith(color: c.faint),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.dataSources,
                  textAlign: TextAlign.center,
                  style: context.tt.bodySmall!.copyWith(color: c.faint),
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
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null || !context.mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (context.mounted) showMsg(context, t.avatarTooBig, error: true);
        return;
      }
      final name = file.name.toLowerCase();
      final ext = name.endsWith('.png')
          ? 'png'
          : name.endsWith('.webp')
          ? 'webp'
          : 'jpg';
      session.updateUser(await session.api.setAvatar(bytes, ext));
      if (context.mounted) showMsg(context, t.avatarUpdated);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _changeUsername(BuildContext context) async {
    final t = context.t;
    final session = context.session;
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          PromptDialog(title: t.changeUsername, label: t.newUsername, initial: session.user.username, maxLength: 50),
    );
    if (name == null || !context.mounted) return;
    session.updateUser(await session.api.changeUsername(name));
    if (context.mounted) showMsg(context, t.usernameChanged);
  }

  static String get _stamp => DateFormat('yyyyMMdd').format(DateTime.now());

  Future<void> _save(BuildContext context, String name, String mime, Uint8List bytes, String done) async {
    final saved = await _files.invokeMethod<bool>('saveFile', {'name': name, 'mime': mime, 'bytes': bytes});
    if (saved == true && context.mounted) showMsg(context, done);
  }

  Future<void> _export(BuildContext context) async {
    final done = context.t.exportSaved;
    try {
      final csv = await context.api.exportCsv();
      if (context.mounted) await _save(context, 'macrobandit_export_$_stamp.csv', 'text/csv', csv, done);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _backup(BuildContext context) async {
    final done = context.t.backupSaved;
    try {
      final json = await context.api.exportBackup();
      if (context.mounted) await _save(context, 'macrobandit_sicherung_$_stamp.json', 'application/json', json, done);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _restore(BuildContext context) async {
    final t = context.t;
    final session = context.session;
    try {
      final bytes = await _files.invokeMethod<Uint8List>('openFile');
      if (bytes == null || !context.mounted) return;
      final DateTime? when;
      try {
        when = session.api.checkBackup(bytes);
      } on ApiException catch (e) {
        showMsg(context, e.status == 426 ? t.backupTooNew : t.backupInvalid, error: true);
        return;
      }
      final date = when == null
          ? ''
          : ' ${t.backupFrom(DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm().format(when.toLocal()))}';
      if (!await confirm(context, t.restoreConfirm(date), action: t.restoreAction) || !context.mounted) return;
      await session.api.importBackup(bytes);
      await session.dataReplaced();
      if (context.mounted) showMsg(context, t.restoreDone);
    } on ApiException catch (e) {
      if (context.mounted) showMsg(context, e.status == 426 ? t.backupTooNew : t.backupInvalid, error: true);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _deleteAll(BuildContext context) async {
    final ok = await showSheet<bool>(context, (_) => const _DeleteSheet());
    if (ok == true && context.mounted) showMsg(context, context.t.allDataDeleted);
  }
}

class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet();

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  final _word = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _word.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    final session = context.session;
    try {
      await session.api.deleteAllData();
      await session.dataReplaced();
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
    final ready = _word.text.trim() == word;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.deleteAllData, style: context.tt.titleLarge!.copyWith(color: context.c.fatText)),
          const SizedBox(height: 12),
          Text(t.deleteWarning, style: TextStyle(color: context.c.soft)),
          const SizedBox(height: 16),
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
