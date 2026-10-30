import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ludo_rank/core/dependency_injection/injection_container.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_token.dart';
import 'package:ludo_rank/features/ludo_game/domain/models/move_option.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/ludo_game_result_overlay.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/ludo_match_board.dart';
import 'package:ludo_rank/features/ludo_game/presentation/widgets/match_ui/ludo_match_player_section.dart';
import 'package:ludo_rank/features/matches/presentation/providers/match_game_provider.dart';
import 'package:ludo_rank/features/match_players/domain/entities/match_player.dart';

class MatchGamePage extends StatefulWidget {
  /// Database match ID.
  final String matchId;

  /// Key = playerId, value = name.
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

  Future<void> _onTokenTap(LudoToken token) async {
    await provider.handleTokenTap(token);
  }

  Future<void> _executeMove(MoveOption move) async {
    await provider.executeMove(move);
  }

  Future<void> _handleBack() async {
    if (provider.isGameFinished && provider.isFinished) {
      if (mounted) Navigator.pop(context, true);
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مغادرة المباراة؟'),
        content: const Text(
          'الحالة الحالية للمباراة لن يتم حفظها كحالة قابلة للاستكمال في هذه المرحلة.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('البقاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MatchGameProvider>.value(
      value: provider,
      child: Consumer<MatchGameProvider>(
        builder: (context, gameProvider, _) {
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 48,
              centerTitle: true,
              title: const Text(
                'LudoRank',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              leading: IconButton(
                onPressed: gameProvider.isLoading ? null : _handleBack,
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              actions: <Widget>[
                if (gameProvider.isGameFinished && !gameProvider.isFinished)
                  IconButton(
                    onPressed: gameProvider.isLoading
                        ? null
                        : gameProvider.retryFinishPersistence,
                    tooltip: 'إعادة حفظ النتيجة',
                    icon: const Icon(Icons.sync),
                  )
                else
                  const SizedBox(width: 48),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFF51465E),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: Stack(
                children: <Widget>[
                  _LiveMatchLayout(
                    provider: gameProvider,
                    onTokenTap: _onTokenTap,
                    onMove: _executeMove,
                  ),
                  if (gameProvider.error != null)
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
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
                          playerNames: widget.playerNames,
                          isSaved: gameProvider.isFinished,
                          isLoading: gameProvider.isLoading,
                          onRetry: gameProvider.retryFinishPersistence,
                          onClose: gameProvider.isFinished
                              ? () => Navigator.pop(context, true)
                              : null,
                          gameResult: gameProvider.result,
                          matchPlayers:
                              gameProvider.session?.matchPlayers ??
                              const <MatchPlayer>[],
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

class _LiveMatchLayout extends StatelessWidget {
  final MatchGameProvider provider;
  final ValueChanged<LudoToken> onTokenTap;
  final Future<void> Function(MoveOption) onMove;
  const _LiveMatchLayout({
    required this.provider,
    required this.onTokenTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final players = provider.players;
    final currentPlayer = provider.currentPlayer;

    if (players.isEmpty || currentPlayer == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    final playersByColor = <LudoPlayerColor, LudoPlayer>{
      for (final player in players) player.color: player,
    };

    final green = playersByColor[LudoPlayerColor.green];
    final yellow = playersByColor[LudoPlayerColor.yellow];
    final red = playersByColor[LudoPlayerColor.red];
    final blue = playersByColor[LudoPlayerColor.blue];

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortScreen = constraints.maxHeight < 630;
        final activeCardHeight = shortScreen ? 110.0 : 126.0;
        final inactiveCardHeight = shortScreen ? 34.0 : 42.0;
        final rowGap = shortScreen ? 4.0 : 6.0;
        final sidePadding = constraints.maxWidth < 360 ? 8.0 : 12.0;

        final topHasPlayers = green != null || yellow != null;
        final bottomHasPlayers = red != null || blue != null;

        final topHeight = topHasPlayers ? activeCardHeight : 0.0;
        final bottomHeight = bottomHasPlayers ? activeCardHeight : 0.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: EdgeInsets.fromLTRB(sidePadding, 5, sidePadding, 5),
              child: Column(
                children: <Widget>[
                  if (topHeight > 0) ...<Widget>[
                    SizedBox(
                      height: topHeight,
                      child: _buildHomeSideRow(
                        left: green,
                        right: yellow,
                        currentPlayer: currentPlayer,
                        activeCardHeight: activeCardHeight,
                        inactiveCardHeight: inactiveCardHeight,
                      ),
                    ),
                    SizedBox(height: rowGap),
                  ],
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, boardConstraints) {
                          final side =
                              boardConstraints.maxWidth <
                                  boardConstraints.maxHeight
                              ? boardConstraints.maxWidth
                              : boardConstraints.maxHeight;

                          return SizedBox.square(
                            dimension: side,
                            child: LudoMatchBoard(
                              players: players,
                              currentPlayerId: currentPlayer.playerId,
                              availableMoves: provider.availableMoves,
                              selectedTokenId: provider.selectedTokenId,
                              onTokenTap: onTokenTap,
                              legalMoveDestinations:
                                  provider.selectedMoveDestinations,
                              rollValueForMove: provider.rollValueForMove,
                              onMoveTap: onMove,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (bottomHeight > 0) ...<Widget>[
                    SizedBox(height: rowGap),
                    SizedBox(
                      height: bottomHeight,
                      child: _buildHomeSideRow(
                        left: red,
                        right: blue,
                        currentPlayer: currentPlayer,
                        activeCardHeight: activeCardHeight,
                        inactiveCardHeight: inactiveCardHeight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The two slots follow the physical homes and never reorder the colors.
  /// LTR slots preserve green/yellow and red/blue board-side positioning;
  /// each player's own contents stay RTL Arabic.
  Widget _buildHomeSideRow({
    required LudoPlayer? left,
    required LudoPlayer? right,
    required LudoPlayer currentPlayer,
    required double activeCardHeight,
    required double inactiveCardHeight,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildPlayerSlot(
              left,
              currentPlayer,
              activeCardHeight,
              inactiveCardHeight,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _buildPlayerSlot(
              right,
              currentPlayer,
              activeCardHeight,
              inactiveCardHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot(
    LudoPlayer? player,
    LudoPlayer currentPlayer,
    double activeCardHeight,
    double inactiveCardHeight,
  ) {
    if (player == null) return const SizedBox.shrink();

    final isCurrent = player.playerId == currentPlayer.playerId;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: double.infinity,
        height: isCurrent ? activeCardHeight : inactiveCardHeight,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LudoMatchPlayerSection(
            player: player,
            isCurrent: isCurrent,
            turnState: provider.turnState,
            availableRolls: isCurrent
                ? provider.availableRolls
                : provider.availableRolls.clear(),
            canRoll: isCurrent && provider.canRollDice,
            onRoll: provider.rollDice,
            height: isCurrent ? activeCardHeight : inactiveCardHeight,
          ),
        ),
      ),
    );
  }
}

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
          children: <Widget>[
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
