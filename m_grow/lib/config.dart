/// Values are filled in by the GitHub build (see .github/workflows/build.yml).
class Config {
  /// URL of the AI coach server. Empty means the coach uses built-in quick tips.
  static const aiEndpoint = String.fromEnvironment('AI_ENDPOINT');

  /// Where feedback emails go. Set the GitHub variable FEEDBACK_EMAIL.
  static const feedbackEmail = String.fromEnvironment('FEEDBACK_EMAIL');

  static const developerName =
      String.fromEnvironment('DEVELOPER_NAME', defaultValue: 'The M Grow team');
}
