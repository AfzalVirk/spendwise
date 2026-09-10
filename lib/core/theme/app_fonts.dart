/// Centralized font family names.
///
/// The actual font files live under assets/fonts/ and are registered in
/// pubspec.yaml. If the files are not bundled yet, Flutter silently falls
/// back to the default system font, so the UI keeps working.
class AppFonts {
  AppFonts._();

  /// Used for headings, prominent titles and important numbers.
  static const String heading = 'OpenSauce';

  /// Used for body text, labels and supporting text.
  static const String body = 'PeaceSans';
}
