Place the font files here, then uncomment the fonts section in pubspec.yaml:

  OpenSauceOne-Regular.ttf
  OpenSauceOne-Medium.ttf
  OpenSauceOne-SemiBold.ttf
  OpenSauceOne-Bold.ttf
  PeaceSans-Regular.ttf

Family names must stay 'OpenSauce' and 'PeaceSans' to match
lib/core/theme/app_fonts.dart. Until the files are added the app
falls back to the default system font automatically.
