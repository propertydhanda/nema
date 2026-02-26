import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeumaColors {
  // Core palette
  static const bg          = Color(0xFF080B14);   // deep navy black
  static const surface     = Color(0xFF0F1520);   // card surface
  static const surfaceHigh = Color(0xFF162030);   // elevated surface
  static const border      = Color(0xFF1E2D45);   // subtle border

  // Accent
  static const cyan        = Color(0xFF00D4FF);   // primary accent
  static const cyanDim     = Color(0xFF0099BB);   // dim cyan
  static const indigo      = Color(0xFF6366F1);   // secondary
  static const indigoDim   = Color(0xFF4447A8);

  // Text
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSub     = Color(0xFF8A9BB5);
  static const textDim     = Color(0xFF4A5A72);

  // Emotion colors
  static const positive    = Color(0xFF10B981);
  static const negative    = Color(0xFFEF4444);
  static const neutral     = Color(0xFF8A9BB5);
  static const warning     = Color(0xFFF59E0B);

  // Layer colors
  static const layerEpisodic   = Color(0xFF6366F1);
  static const layerSemantic   = Color(0xFF00D4FF);
  static const layerEmotional  = Color(0xFFEC4899);
  static const layerProcedural = Color(0xFF10B981);
  static const layerSocial     = Color(0xFFF59E0B);
  static const layerValues     = Color(0xFFEF4444);
  static const layerNarrative  = Color(0xFF8B5CF6);
  static const layerFuture     = Color(0xFF06B6D4);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NeumaColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: NeumaColors.cyan,
      secondary: NeumaColors.indigo,
      surface: NeumaColors.surface,
      onPrimary: NeumaColors.bg,
      onSecondary: Colors.white,
      onSurface: NeumaColors.textPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        color: NeumaColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.inter(
        color: NeumaColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(
        color: NeumaColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(
        color: NeumaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(
        color: NeumaColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(
        color: NeumaColors.textSub, fontSize: 13, fontWeight: FontWeight.w400),
      labelSmall: GoogleFonts.inter(
        color: NeumaColors.textDim, fontSize: 11, fontWeight: FontWeight.w500,
        letterSpacing: 0.8),
    ),
    cardTheme: CardThemeData(
      color: NeumaColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NeumaColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NeumaColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NeumaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NeumaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: NeumaColors.cyan, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: NeumaColors.textDim, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerColor: NeumaColors.border,
    iconTheme: const IconThemeData(color: NeumaColors.textSub, size: 20),
  );
}

// Layer metadata helper
class LayerMeta {
  final String label;
  final String emoji;
  final Color color;
  const LayerMeta(this.label, this.emoji, this.color);
}

const layerMap = {
  'episodic':     LayerMeta('Event',     '📍', NeumaColors.layerEpisodic),
  'semantic_self':LayerMeta('About Me',  '🧠', NeumaColors.layerSemantic),
  'emotional':    LayerMeta('Feeling',   '❤️', NeumaColors.layerEmotional),
  'procedural':   LayerMeta('Habit',     '⚙️', NeumaColors.layerProcedural),
  'social':       LayerMeta('People',    '👥', NeumaColors.layerSocial),
  'values':       LayerMeta('Value',     '⭐', NeumaColors.layerValues),
  'narrative':    LayerMeta('Story',     '📖', NeumaColors.layerNarrative),
  'future_self':  LayerMeta('Dream',     '🚀', NeumaColors.layerFuture),
};
