/// AF-01 – Kostenaufteilung berechnen
///
/// Verteilt einen Betrag cent-genau auf eine Liste von Teilnehmern.
/// Die Summe aller Anteile entspricht exakt dem Gesamtbetrag (BR-08).
/// Teilnehmer werden vor der Restverteilung deterministisch nach userId sortiert.
class ExpenseCalculator {
  const ExpenseCalculator._();

  /// Gibt die Kostenanteile als Map {userId -> Betrag in Euro} zurück.
  /// Wirft [ArgumentError] wenn:
  /// - [amountInCents] <= 0
  /// - [participantIds] leer ist
  /// - [participantIds] doppelte IDs enthält
  static Map<String, int> splitInCents({
    required int amountInCents,
    required List<String> participantIds,
  }) {
    if (amountInCents <= 0) {
      throw ArgumentError('Betrag muss größer als 0 sein.');
    }
    if (participantIds.isEmpty) {
      throw ArgumentError('Mindestens ein Teilnehmer erforderlich.');
    }

    final unique = participantIds.toSet();
    if (unique.length != participantIds.length) {
      throw ArgumentError('Teilnehmer-IDs dürfen nicht doppelt vorkommen.');
    }

    // Deterministisch sortieren damit gleiche Eingaben
    // unabhängig von UI-Reihenfolge dasselbe Ergebnis liefern.
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

  /// Konvertiert einen Euro-Betrag in Cent (gerundet auf 2 Nachkommastellen).
  /// Wirft [ArgumentError] wenn der Betrag nicht endlich ist.
  static int euroToCents(double euro) {
    if (!euro.isFinite) {
      throw ArgumentError('Betrag muss eine endliche Zahl sein.');
    }
    return (euro * 100).round();
  }

  /// Prüft ob ein Betrag maximal 2 Nachkommastellen hat.
  static bool hasValidPrecision(double euro) {
    final cents = (euro * 100).roundToDouble();
    return (cents - euro * 100).abs() < 0.0001;
  }
}
