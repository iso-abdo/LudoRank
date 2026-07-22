import 'package:flutter/material.dart';

import 'package:ludo_rank/features/tournaments/domain/entities/tournament.dart';

extension TournamentStatusExtension on TournamentStatus {

  String get title {
    switch (this) {
      case TournamentStatus.draft:
        return "مسودة";

      case TournamentStatus.ready:
        return "جاهزة";

      case TournamentStatus.running:
        return "جارية";

      case TournamentStatus.finished:
        return "منتهية";

      case TournamentStatus.cancelled:
        return "ملغاة";
    }
  }

  Color get color {
    switch (this) {
      case TournamentStatus.draft:
        return Colors.grey;

      case TournamentStatus.ready:
        return Colors.orange;

      case TournamentStatus.running:
        return Colors.green;

      case TournamentStatus.finished:
        return Colors.blue;

      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }
  IconData get icon {
    switch (this) {
      case TournamentStatus.draft:
        return Icons.edit_note;

      case TournamentStatus.ready:
        return Icons.check_circle;

      case TournamentStatus.running:
        return Icons.play_circle_fill;

      case TournamentStatus.finished:
        return Icons.workspace_premium;

      case TournamentStatus.cancelled:
        return Icons.cancel;
    }
  }

}