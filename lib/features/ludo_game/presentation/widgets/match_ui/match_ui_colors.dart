import 'package:flutter/material.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';

/// Saturated palette tuned to the board reference image.
/// Presentation palette only. It never affects game logic or path assignments.
Color matchUiColorFor(LudoPlayerColor color) {
  switch (color) {
    case LudoPlayerColor.green:
      return const Color(0xFF10C94D);
    case LudoPlayerColor.yellow:
      return const Color(0xFFF7BE00);
    case LudoPlayerColor.red:
      return const Color(0xFFF0443C);
    case LudoPlayerColor.blue:
      return const Color(0xFF168DF4);
  }
}
