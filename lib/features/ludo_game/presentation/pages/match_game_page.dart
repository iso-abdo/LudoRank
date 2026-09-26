import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/ludo_board.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/ludo_dice_panel.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/ludo_game_result_overlay.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/ludo_move_hint.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/ludo_player_bar.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/ludo_turn_indicator.dart';
import 'package:ludo_rank/features/matches/presentation/providers/match_game_provider.dart';

class MatchGamePage extends StatefulWidget {
  final String matchId;

  /// Key   = playerId
  /// Value = player name
  final Map<String, String> playerNames;

  const MatchGamePage({
    super.key,
    required this.matchId,
    required this.playerNames,
  });

  @override
  State<MatchGamePage> createState() => _MatchGamePageState();
}

class _MatchGamePageState extends State<MatchGamePage> {
  late final MatchGameProvider provider;

  @override
  void initState() {
    super.initState();

    provider = sl<MatchGameProvider>();

    provider.startMatch(
      matchId: widget.matchId,
      playerNames: widget.playerNames,
    );
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  // ============================================================
  // TOKEN TAP
  // ============================================================

  void _onTokenTap(LudoToken token) {
    provider.selectToken(token.id);
  }

  // ============================================================
  // MOVE TAP
  // ============================================================

  Future<void> _executeMove(MoveOption move) async {
    await provider.executeMove(move);
  }

  // ============================================================
  // BACK
  // ============================================================

  Future<void> _handleBack() async {
    if (provider.isGameFinished && provider.isFinished) {
      if (mounted) {
        Navigator.pop(context, true);
      }

      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('مغادرة المباراة؟'),
          content: const Text(
            'الحالة الحالية للمباراة لن يتم حفظها كحالة قابلة للاستكمال في هذه المرحلة.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('البقاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('مغادرة'),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MatchGameProvider>.value(
      value: provider,
      child: Consumer<MatchGameProvider>(
        builder: (context, gameProvider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                gameProvider.match == null
                    ? 'المباراة'
                    : 'المباراة ${gameProvider.match!.id}',
              ),
              leading: IconButton(
                onPressed: gameProvider.isLoading ? null : _handleBack,
                icon: const Icon(Icons.arrow_back),
              ),
              actions: [
                if (gameProvider.isGameFinished && !gameProvider.isFinished)
                  IconButton(
                    onPressed: gameProvider.isLoading
                        ? null
                        : gameProvider.retryFinishPersistence,
                    tooltip: 'إعادة حفظ النتيجة',
                    icon: const Icon(Icons.sync),
                  ),
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  _MatchGameContent(
                    provider: gameProvider,
                    onTokenTap: _onTokenTap,
                    onMove: _executeMove,
                  ),

                  if (gameProvider.error != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _ErrorBanner(
                        message: gameProvider.error!,
                        onClose: gameProvider.clearError,
                      ),
                    ),

                  if (gameProvider.isGameFinished)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: gameProvider.isLoading,
                        child: LudoGameResultOverlay(
                          players: gameProvider.completedPlayers,
                          isSaved: gameProvider.isFinished,
                          isLoading: gameProvider.isLoading,
                          onRetry: gameProvider.retryFinishPersistence,
                          onClose: gameProvider.isFinished
                              ? () {
                                  Navigator.pop(context, true);
                                }
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================================================================
// CONTENT
// ==================================================================

class _MatchGameContent extends StatelessWidget {
  final MatchGameProvider provider;

  final ValueChanged<LudoToken> onTokenTap;
  final ValueChanged<MoveOption> onMove;

  const _MatchGameContent({
    required this.provider,
    required this.onTokenTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return _WideLayout(
            provider: provider,
            onTokenTap: onTokenTap,
            onMove: onMove,
          );
        }

        return _CompactLayout(
          provider: provider,
          onTokenTap: onTokenTap,
          onMove: onMove,
        );
      },
    );
  }
}

// ==================================================================
// WIDE
// ==================================================================

class _WideLayout extends StatelessWidget {
  final MatchGameProvider provider;

  final ValueChanged<LudoToken> onTokenTap;
  final ValueChanged<MoveOption> onMove;

  const _WideLayout({
    required this.provider,
    required this.onTokenTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                  maxHeight: 760,
                ),
                child: LudoBoard(
                  players: provider.players,
                  availableMoves: provider.availableMoves,
                  selectedTokenId: provider.selectedTokenId,
                  onTokenTap: onTokenTap,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: _GameSidePanel(provider: provider, onMove: onMove),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// COMPACT
// ==================================================================

class _CompactLayout extends StatelessWidget {
  final MatchGameProvider provider;

  final ValueChanged<LudoToken> onTokenTap;
  final ValueChanged<MoveOption> onMove;

  const _CompactLayout({
    required this.provider,
    required this.onTokenTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          LudoTurnIndicator(
            currentPlayer: provider.currentPlayer,
            turnState: provider.turnState,
          ),

          const SizedBox(height: 10),

          LudoPlayerBar(players: provider.players, gameState: provider.state),

          const SizedBox(height: 12),

          LudoBoard(
            players: provider.players,
            availableMoves: provider.availableMoves,
            selectedTokenId: provider.selectedTokenId,
            onTokenTap: onTokenTap,
          ),

          const SizedBox(height: 12),

          LudoDicePanel(
            turnState: provider.turnState,
            availableRolls: provider.availableRolls,
            canRoll: provider.canRollDice,
            onRoll: provider.rollDice,
          ),

          const SizedBox(height: 10),

          LudoMoveHint(
            selectedTokenId: provider.selectedTokenId,
            availableMoves: provider.availableMoves,
            turnState: provider.turnState,
            onMove: onMove,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SIDE PANEL
// ==================================================================

class _GameSidePanel extends StatelessWidget {
  final MatchGameProvider provider;
  final ValueChanged<MoveOption> onMove;

  const _GameSidePanel({required this.provider, required this.onMove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LudoTurnIndicator(
          currentPlayer: provider.currentPlayer,
          turnState: provider.turnState,
        ),

        const SizedBox(height: 12),

        LudoPlayerBar(players: provider.players, gameState: provider.state),

        const SizedBox(height: 12),

        LudoDicePanel(
          turnState: provider.turnState,
          availableRolls: provider.availableRolls,
          canRoll: provider.canRollDice,
          onRoll: provider.rollDice,
        ),

        const SizedBox(height: 12),

        LudoMoveHint(
          selectedTokenId: provider.selectedTokenId,
          availableMoves: provider.availableMoves,
          turnState: provider.turnState,
          onMove: onMove,
        ),
      ],
    );
  }
}

// ==================================================================
// ERROR
// ==================================================================

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}
