import 'package:equatable/equatable.dart';
import 'package:ludo_rank/features/ludo_game/domain/entities/ludo_player.dart';



/// الحالة الحالية للعبة Ludo.
///
/// مهم:
/// هذا الكلاس مسؤول عن تخزين حالة اللعبة فقط.
/// لا يحتوي على Logic للحركة أو النرد أو الأكل أو الفوز.
///
/// كل الـ game rules سيتم تنفيذها داخل:
/// LudoGameEngine
class LudoGameState extends Equatable {
  /// جميع لاعبي اللعبة.
  final List<LudoPlayer> players;

  /// رقم اللاعب صاحب الدور الحالي.
  ///
  /// مثال:
  /// 0 = اللاعب الأول
  /// 1 = اللاعب الثاني
  /// 2 = اللاعب الثالث
  /// 3 = اللاعب الرابع
  final int currentPlayerIndex;

  /// آخر نتيجة للنرد.
  ///
  /// null معناها إن مفيش رمية نرد حاليًا.
  final int? diceValue;

  /// هل اللعبة بدأت؟
  final bool isStarted;

  /// هل اللعبة انتهت؟
  final bool isFinished;

  /// ترتيب اللاعبين الذين أنهوا اللعبة.
  ///
  /// مثال:
  /// [2, 0, 1]
  ///
  /// معناه:
  /// اللاعب رقم 2 جاء أولًا
  /// اللاعب رقم 0 جاء ثانيًا
  /// اللاعب رقم 1 جاء ثالثًا
  final List<int> finishedPlayerIndexes;

  const LudoGameState({
    required this.players,
    required this.currentPlayerIndex,
    this.diceValue,
    this.isStarted = false,
    this.isFinished = false,
    this.finishedPlayerIndexes = const [],
  });

  /// الحالة الابتدائية للعبة.
  factory LudoGameState.initial({
    required List<LudoPlayer> players,
  }) {
    return LudoGameState(
      players: List.unmodifiable(players),
      currentPlayerIndex: 0,
      diceValue: null,
      isStarted: false,
      isFinished: false,
      finishedPlayerIndexes: const [],
    );
  }

  /// إنشاء نسخة جديدة من الحالة مع تغيير بعض القيم فقط.
  LudoGameState copyWith({
    List<LudoPlayer>? players,
    int? currentPlayerIndex,
    int? diceValue,
    bool clearDiceValue = false,
    bool? isStarted,
    bool? isFinished,
    List<int>? finishedPlayerIndexes,
  }) {
    return LudoGameState(
      players: List.unmodifiable(
        players ?? this.players,
      ),
      currentPlayerIndex:
      currentPlayerIndex ?? this.currentPlayerIndex,
      diceValue: clearDiceValue
          ? null
          : diceValue ?? this.diceValue,
      isStarted:
      isStarted ?? this.isStarted,
      isFinished:
      isFinished ?? this.isFinished,
      finishedPlayerIndexes:
      List.unmodifiable(
        finishedPlayerIndexes ??
            this.finishedPlayerIndexes,
      ),
    );
  }

  /// اللاعب صاحب الدور الحالي.
  LudoPlayer get currentPlayer =>
      players[currentPlayerIndex];

  /// هل اللاعب الحالي أنهى اللعبة؟
  bool get currentPlayerFinished =>
      finishedPlayerIndexes.contains(
        currentPlayerIndex,
      );

  /// عدد اللاعبين الذين أنهوا اللعبة.
  int get finishedPlayersCount =>
      finishedPlayerIndexes.length;

  /// هل ما زال هناك لاعبون يمكنهم اللعب؟
  bool get hasRemainingPlayers =>
      finishedPlayersCount < players.length;

  @override
  List<Object?> get props => [
    players,
    currentPlayerIndex,
    diceValue,
    isStarted,
    isFinished,
    finishedPlayerIndexes,
  ];
}