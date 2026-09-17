/// AF-01 - Kostenaufteilung berechnen
/// 
/// Verteilt einen Betrag cent-genau auf eine Liste von Teilnehmern.
/// Die Summe aller Anteile entspricht exakt dem Gesamtbetrag (BR-08).
/// Teilnehmer werden vor der Restverteilung deterministisch nach userId sortiert.
class ExpenseCalculator {
  const ExpenseCalculator._();

  static Map<String, int> splitInCents({
    required int amountInCents,
    required List<String> participantIds,
  }) {
    if (amountInCents <= 0) {
      throw ArgumentError('Betrag muss groesser als 0 sein.');
    }
    if (participantIds.isEmpty) {
      throw ArgumentError('Mindestens ein Teilnehmer erforderlich.');
    }
    final unique = participantIds.toSet();
    if (unique.length != participantIds.length) {
      throw ArgumentError('Teilnehmer-IDs duerfen nicht doppelt vorkommen.');
    }
    final sorted = List<String>.from(participantIds)..sort();
    final n = sorted.length;
    final base = amountInCents ~/ n;
    final remainder = amountInCents - base * n;
    final result = <String, int>{};
    for (var i = 0; i < n; i++) {
      result[sorted[i]] = base + (i < remainder ? 1 : 0);
    }
    return result;
  }

  static int euroToCents(double euro) {
    if (!euro.isFinite) {
      throw ArgumentError('Betrag muss eine endliche Zahl sein.');
    }
    return (euro * 100).round();
  }

  static bool hasValidPrecision(double euro) {
    final cents = (euro * 100).roundToDouble();
    return (cents - euro * 100).abs() < 0.0001;
  }
}
