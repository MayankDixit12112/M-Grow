import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'l10n.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _c = TextEditingController();
  String _type = 'fb_suggest';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _c.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('fb_empty'))));
      return;
    }
    final subject = 'M Grow 2.0 - ${tr(_type)}';
    final uri = Uri.parse(
        'mailto:${Config.feedbackEmail}?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(text)}');
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('fb_fail'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('fb_title'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(tr('fb_info')),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final k in ['fb_suggest', 'fb_bug', 'fb_other'])
                    ChoiceChip(
                      label: Text(tr(k)),
                      selected: _type == k,
                      onSelected: (_) => setState(() => _type = k),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _c,
                minLines: 6,
                maxLines: 12,
                decoration: InputDecoration(
                  hintText: tr('fb_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _send,
                icon: const Icon(Icons.send),
                label: Text(tr('fb_send')),
              ),
            ],
          ),
        ),
      );
    });
  }
}
