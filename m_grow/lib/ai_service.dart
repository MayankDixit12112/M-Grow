import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'l10n.dart';
import 'models.dart';

class AiService {
  static bool get enabled => Config.aiEndpoint.isNotEmpty;

  static const _crisisWords = [
    'suicide', 'kill myself', 'end my life', 'want to die', 'self harm',
    'self-harm', 'hurt myself', 'starve myself', 'cut myself',
  ];

  /// Checked on the phone before anything is sent anywhere.
  static bool looksLikeCrisis(String text) {
    final t = text.toLowerCase();
    return _crisisWords.any(t.contains);
  }

  /// [history] is a list of {role: user|assistant, content: text}.
  static Future<String> ask(
      List<Map<String, String>> history, UserProfile p) async {
    final recent =
        history.length > 12 ? history.sublist(history.length - 12) : history;
    if (p.age < 13) throw Exception('Coach is for ages 13 and up');

    final body = <String, dynamic>{
      'messages': recent,
      'lang': L10n.lang.value,
      'minor': p.isMinor,
    };

    // Only a coarse summary, and only if the person turned sharing on.
    // Never the name, exact age, height or weight.
    if (p.shareWithCoach && !p.isMinor) {
      body['profile'] = {
        'ageGroup': p.age < 13 ? 'child' : (p.age < 18 ? 'teen' : 'adult'),
        'goal': p.goal.name,
        'diet': p.diet.name,
        'allergies': p.allergies,
        'conditions': p.conditions,
      };
    }

    final res = await http
        .post(
          Uri.parse(Config.aiEndpoint),
          headers: {
            'content-type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 40));

    if (res.statusCode != 200) {
      throw Exception('Coach error ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final reply = (data['reply'] as String?)?.trim() ?? '';
    if (reply.isEmpty) throw Exception('Empty reply');
    return reply;
  }
}
