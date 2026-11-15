import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings_bn.dart';
import 'strings_en.dart';
import 'strings_es.dart';
import 'strings_hi.dart';
import 'strings_mr.dart';
import 'strings_ta.dart';
import 'strings_te.dart';

/// To add a language: copy strings_en.dart to strings_xx.dart, translate the
/// values, then register it in the two maps below.
class L10n {
  static final ValueNotifier<String> lang = ValueNotifier('en');

  static const languages = <String, String>{
    'en': 'English',
    'hi': 'हिन्दी',
    'bn': 'বাংলা',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'mr': 'मराठी',
    'es': 'Español',
  };

  static const _all = <String, Map<String, String>>{
    'en': stringsEn,
    'hi': stringsHi,
    'bn': stringsBn,
    'ta': stringsTa,
    'te': stringsTe,
    'mr': stringsMr,
    'es': stringsEs,
  };
}

/// Wrap a screen's content in this so it redraws when the language changes.
class LangScope extends StatelessWidget {
  final WidgetBuilder builder;

  const LangScope({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: L10n.lang,
        builder: (context, _, __) => builder(context),
      );
}

/// Translate a key. Missing keys fall back to English, then to the key itself.
String tr(String key, [Map<String, Object?>? args]) {
  var s = L10n._all[L10n.lang.value]?[key] ?? stringsEn[key] ?? key;
  if (args != null) {
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  }
  return s;
}
