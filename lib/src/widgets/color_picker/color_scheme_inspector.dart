import 'package:flutter/material.dart';

class ColorSchemeInspector {
  /// Checks if a color matches any color in the given ColorScheme
  /// Returns a string describing the match, or empty string if no match found
  static String identifyColorSchemeMatch(Color color, ColorScheme colorScheme) {
    final matches = <String>[];

    final colorSchemeMap = {
      'primary': colorScheme.primary,
      'onPrimary': colorScheme.onPrimary,
      'primaryContainer': colorScheme.primaryContainer,
      'onPrimaryContainer': colorScheme.onPrimaryContainer,
      'primaryFixed': colorScheme.primaryFixed,
      'onPrimaryFixed': colorScheme.onPrimaryFixed,
      'primaryFixedDim': colorScheme.primaryFixedDim,
      'onPrimaryFixedVariant': colorScheme.onPrimaryFixedVariant,
      'secondary': colorScheme.secondary,
      'onSecondary': colorScheme.onSecondary,
      'secondaryContainer': colorScheme.secondaryContainer,
      'onSecondaryContainer': colorScheme.onSecondaryContainer,
      'secondaryFixed': colorScheme.secondaryFixed,
      'onSecondaryFixed': colorScheme.onSecondaryFixed,
      'secondaryFixedDim': colorScheme.secondaryFixedDim,
      'onSecondaryFixedVariant': colorScheme.onSecondaryFixedVariant,
      'tertiary': colorScheme.tertiary,
      'onTertiary': colorScheme.onTertiary,
      'tertiaryContainer': colorScheme.tertiaryContainer,
      'onTertiaryContainer': colorScheme.onTertiaryContainer,
      'tertiaryFixed': colorScheme.tertiaryFixed,
      'onTertiaryFixed': colorScheme.onTertiaryFixed,
      'tertiaryFixedDim': colorScheme.tertiaryFixedDim,
      'onTertiaryFixedVariant': colorScheme.onTertiaryFixedVariant,
      'error': colorScheme.error,
      'onError': colorScheme.onError,
      'errorContainer': colorScheme.errorContainer,
      'onErrorContainer': colorScheme.onErrorContainer,
      'outline': colorScheme.outline,
      'surface': colorScheme.surface,
      'onSurface': colorScheme.onSurface,
      'onSurfaceVariant': colorScheme.onSurfaceVariant,
      'inverseSurface': colorScheme.inverseSurface,
      'onInverseSurface': colorScheme.onInverseSurface,
      'inversePrimary': colorScheme.inversePrimary,
      'shadow': colorScheme.shadow,
      'surfaceTint': colorScheme.surfaceTint,
      'outlineVariant': colorScheme.outlineVariant,
      'scrim': colorScheme.scrim,
      'surfaceContainerHighest': colorScheme.surfaceContainerHighest,
      'surfaceContainerHigh': colorScheme.surfaceContainerHigh,
      'surfaceContainer': colorScheme.surfaceContainer,
      'surfaceContainerLow': colorScheme.surfaceContainerLow,
      'surfaceContainerLowest': colorScheme.surfaceContainerLowest,
      'surfaceBright': colorScheme.surfaceBright,
      'surfaceDim': colorScheme.surfaceDim,
    };

    for (var entry in colorSchemeMap.entries) {
      String name = entry.key;
      Color schemeColor = entry.value;

      if (color.value == schemeColor.value) {
        matches.add(name);
      }
    }

    if (matches.isEmpty) {
      return '';
    } else if (matches.length == 1) {
      return 'colorScheme.${matches.first}';
    } else {
      return matches.map((m) => 'colorScheme.$m').join(', ');
    }
  }
}
