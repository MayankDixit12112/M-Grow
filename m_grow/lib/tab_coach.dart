import 'package:flutter/material.dart';

import 'ai_service.dart';
import 'l10n.dart';
import 'models.dart';
import 'storage.dart';

class CoachTab extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onChanged;

  const CoachTab({super.key, required this.profile, required this.onChanged});

  @override
  State<CoachTab> createState() => _CoachTabState();
}

class _Msg {
  final String role; // user | assistant
  final String text;
  final bool local; // local messages are never sent to the server

  const _Msg(this.role, this.text, {this.local = false});
}

class _CoachTabState extends State<CoachTab> {
  final _c = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _c.text.trim();
    if (text.isEmpty || _busy) return;
    if (text.length > 1000) {
      _c.text = text.substring(0, 1000);
    }
    final msg = text.length > 1000 ? text.substring(0, 1000) : text;
    _c.clear();
    setState(() => _msgs.add(_Msg('user', msg)));
    _toBottom();

    // Safety check on the phone, before anything is sent.
    if (AiService.looksLikeCrisis(msg)) {
      setState(() => _msgs.add(_Msg('assistant', tr('coach_crisis'), local: true)));
      _toBottom();
      return;
    }

    setState(() => _busy = true);
    try {
      final history = [
        for (final m in _msgs)
          if (!m.local) {'role': m.role, 'content': m.text},
      ];
      final reply = await AiService.ask(history, widget.profile);
      if (!mounted) return;
      setState(() => _msgs.add(_Msg('assistant', reply)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _msgs.add(_Msg('assistant', tr('coach_err'), local: true)));
    } finally {
      if (mounted) setState(() => _busy = false);
      _toBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final theme = Theme.of(context);
      final p = widget.profile;

      if (p.age < 13) {
        return _info(Icons.family_restroom, tr('coach_kids'));
      }
      if (!AiService.enabled) {
        return _info(Icons.cloud_off, tr('coach_off'));
      }

      return Column(
        children: [
          if (!p.isMinor)
            SwitchListTile(
              dense: true,
              title: Text(tr('coach_share'), style: theme.textTheme.bodySmall),
              value: p.shareWithCoach,
              onChanged: (v) async {
                await Storage.saveProfile(p.copyWith(shareWithCoach: v));
                widget.onChanged();
              },
            ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              children: [
                _bubble(context, tr('coach_welcome'), false),
                for (final m in _msgs) _bubble(context, m.text, m.role == 'user'),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(tr('coach_note'), style: theme.textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: tr('coach_hint'),
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _info(IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _bubble(BuildContext context, String text, bool mine) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: mine ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(text),
      ),
    );
  }
}
