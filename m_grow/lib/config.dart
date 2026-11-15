/// Edit these before you publish.
class Config {
  /// URL of your AI coach proxy (see backend/worker.js). Leave empty to turn
  /// the AI coach off. NEVER put an AI provider key inside the app.
  static const aiEndpoint = '';

  /// Shared token your proxy checks. It only deters casual abuse, it is not
  /// real security. Also set rate limits and a spending cap on the proxy.
  static const appToken = 'change-me';

  /// Where feedback emails are sent.
  static const feedbackEmail = 'your-email@example.com';

  /// Shown in the privacy policy.
  static const developerName = 'Your Name or Company';
}
