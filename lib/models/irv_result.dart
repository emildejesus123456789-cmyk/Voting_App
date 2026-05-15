// lib/models/irv_result.dart

class IrvRound {
  final int round;
  final Map<String, int> tally;
  final Map<String, String> tallyWithLabels;
  final int totalVotes;
  final int exhaustedCount;
  final String? eliminated;
  final String? eliminatedLabel;
  final String? winner;
  final String? winnerLabel;
  final String? note;

  const IrvRound({
    required this.round,
    required this.tally,
    required this.tallyWithLabels,
    required this.totalVotes,
    required this.exhaustedCount,
    this.eliminated,
    this.eliminatedLabel,
    this.winner,
    this.winnerLabel,
    this.note,
  });

  factory IrvRound.fromJson(Map<String, dynamic> json) {
    final tally = <String, int>{};
    if (json['tally'] is Map) {
      (json['tally'] as Map).forEach((k, v) {
        tally[k.toString()] = (v as num).toInt();
      });
    }

    final tallyWithLabels = <String, String>{};
    if (json['tallyWithLabels'] is Map) {
      (json['tallyWithLabels'] as Map).forEach((k, v) {
        tallyWithLabels[k.toString()] = v.toString();
      });
    }

    return IrvRound(
      round: json['round'] as int,
      tally: tally,
      tallyWithLabels: tallyWithLabels,
      totalVotes: json['totalVotes'] as int? ?? 0,
      exhaustedCount: json['exhaustedCount'] as int? ?? 0,
      eliminated: json['eliminated'] as String?,
      eliminatedLabel: json['eliminatedLabel'] as String?,
      winner: json['winner'] as String?,
      winnerLabel: json['winnerLabel'] as String?,
      note: json['note'] as String?,
    );
  }
}

class IrvWinner {
  final String id;
  final String label;

  const IrvWinner({required this.id, required this.label});

  factory IrvWinner.fromJson(Map<String, dynamic> json) {
    return IrvWinner(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

class IrvResult {
  final IrvWinner? winner;
  final List<IrvRound> rounds;
  final int totalBallots;
  final int exhaustedCount;

  const IrvResult({
    this.winner,
    required this.rounds,
    required this.totalBallots,
    required this.exhaustedCount,
  });

  factory IrvResult.fromJson(Map<String, dynamic> json) {
    return IrvResult(
      winner: json['winner'] != null ? IrvWinner.fromJson(json['winner']) : null,
      rounds: (json['rounds'] as List? ?? [])
          .map((r) => IrvRound.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalBallots: json['totalBallots'] as int? ?? 0,
      exhaustedCount: json['exhaustedCount'] as int? ?? 0,
    );
  }
}