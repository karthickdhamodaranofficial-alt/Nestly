import 'package:flutter/material.dart';

class NestlyColors {
  // Normal mode colors
  static const Color bgBase = Color(0xFFFAF8F4);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgElevated = Color(0xFFFFFEFB);

  static const Color primary = Color(0xFF7D6B5D);
  static const Color primaryDark = Color(0xFF3E3028);
  static const Color primaryLight = Color(0xFFA8968A);
  static const Color secondary = Color(0xFF9C8E82);

  static const Color accent = Color(0xFFD9844A);
  static const Color accentDeep = Color(0xFFB8622A);
  static const Color accentSoft = Color(0xFFF6EDE0);
  static const Color accentGlow = Color(0x24D9844A); // 14% opacity

  static const Color sage = Color(0xFF7A9476);
  static const Color sageDark = Color(0xFF5C7558);
  static const Color sageSoft = Color(0xFFE5EDE4);
  static const Color sky = Color(0xFF8AADD8);
  static const Color skySoft = Color(0xFFEAF1FA);
  static const Color lavender = Color(0xFFA496BB);
  static const Color lavenderSoft = Color(0xFFF0EDF6);
  static const Color rose = Color(0xFFCC8E8E);
  static const Color roseSoft = Color(0xFFFAF0F0);

  static const Color success = Color(0xFF7A9476);
  static const Color warning = Color(0xFFD9844A);
  static const Color danger = Color(0xFFB87070);
  static const Color dangerSoft = Color(0xFFFAEAEA);

  static const Color textMain = Color(0xFF2E261F);
  static const Color textBody = Color(0xFF4A3F37);
  static const Color textMuted = Color(0xFF7A6E66);
  static const Color textSubtle = Color(0xFFA89A90);

  static const Color border = Color(0xFFEDE8E0);
  static const Color borderStrong = Color(0xFFD9D0C4);
  static const Color overlay = Color(0x126E5F54); // 7% opacity

  // Simplify mode colors (Overrides)
  static const Color simplifyBgBase = Color(0xFFECEAE5);
  static const Color simplifyBgCard = Color(0xFFF7F5F1);
  static const Color simplifyPrimary = Color(0xFF5A5048);
  static const Color simplifySecondary = Color(0xFF857A71);
  static const Color simplifyAccent = Color(0xFF7A9476);
  static const Color simplifyAccentDeep = Color(0xFF4E7A4A);
  static const Color simplifyAccentSoft = Color(0xFFDFE3DE);
  static const Color simplifyTextMain = Color(0xFF2D2825);
  static const Color simplifyTextMuted = Color(0xFF6E645C);
  static const Color simplifyBorder = Color(0xFFDFDAD1);

  // Helper to get color based on simplify mode status
  static Color getBgBase(bool simplify) => simplify ? simplifyBgBase : bgBase;
  static Color getBgCard(bool simplify) => simplify ? simplifyBgCard : bgCard;
  static Color getPrimary(bool simplify) => simplify ? simplifyPrimary : primary;
  static Color getSecondary(bool simplify) => simplify ? simplifySecondary : secondary;
  static Color getAccent(bool simplify) => simplify ? simplifyAccent : accent;
  static Color getAccentDeep(bool simplify) => simplify ? simplifyAccentDeep : accentDeep;
  static Color getAccentSoft(bool simplify) => simplify ? simplifyAccentSoft : accentSoft;
  static Color getTextMain(bool simplify) => simplify ? simplifyTextMain : textMain;
  static Color getTextMuted(bool simplify) => simplify ? simplifyTextMuted : textMuted;
  static Color getBorder(bool simplify) => simplify ? simplifyBorder : border;
}

class NestlyTheme {
  static const String fontSans = 'Outfit';
  static const String fontSerif = 'Playfair Display';

  // Typography Styles
  static TextStyle serifHeading({
    double fontSize = 24,
    Color color = NestlyColors.primaryDark,
    FontWeight fontWeight = FontWeight.w500,
    double height = 1.25,
  }) {
    return TextStyle(
      fontFamily: fontSerif,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: -0.03,
    );
  }

  static TextStyle sansBody({
    double fontSize = 13.5,
    Color color = NestlyColors.textBody,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.55,
  }) {
    return TextStyle(
      fontFamily: fontSans,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: -0.012,
    );
  }

  static TextStyle labelCaps({
    double fontSize = 10,
    Color color = NestlyColors.textSubtle,
  }) {
    return TextStyle(
      fontFamily: fontSans,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.09,
      color: color,
    );
  }

  // Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 22.0;
  static const double radiusXl = 30.0;

  static BorderRadius getBorderRadius(double radius) => BorderRadius.circular(radius);

  // Shadows
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x0D2E261F),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A2E261F),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F2E261F),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0D2E261F),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x172E261F),
      offset: Offset(0, 4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0F2E261F),
      offset: Offset(0, 8),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x212E261F),
      offset: Offset(0, 12),
      blurRadius: 40,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x142E261F),
      offset: Offset(0, 20),
      blurRadius: 60,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowAccent = [
    BoxShadow(
      color: Color(0x40D9844A),
      offset: Offset(0, 6),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  // Transitions
  static const Duration transitionFast = Duration(milliseconds: 160);
  static const Duration transitionSmooth = Duration(milliseconds: 280);
  static const Duration transitionBounce = Duration(milliseconds: 420);
  static const Duration transitionSpring = Duration(milliseconds: 480);
}
