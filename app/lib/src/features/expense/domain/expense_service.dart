import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_share.dart';

/// Wird geworfen wenn Betrag <= 0 oder nicht endlich oder
/// mehr als 2 Nachkommastellen hat.
class InvalidExpenseAmountException implements Exception {
  const InvalidExpenseAmountException(this.message);
  final String message;
}

/// Wird geworfen wenn Beschreibung leer ist.
class InvalidExpenseDescriptionException implements Exception {
  const InvalidExpenseDescriptionException();
}

/// Wird geworfen wenn keine Teilnehmer ausgewaehlt wurden.
class NoParticipantsException implements Exception {
  const NoParticipantsException();
}

/// Wird geworfen wenn doppelte Teilnehmer-IDs uebergeben werden.
class DuplicateParticipantsException implements Exception {
  const DuplicateParticipantsException();
}

/// Wird geworfen wenn ein Teilnehmer kein WG-Mitglied ist.
class ParticipantNotInWgException implements Exception {
  const ParticipantNotInWgException(this.userId);
  final String userId;
}

/// Ergebnis von UC-11: gespeicherte Expense + ihre ExpenseShares.
class AddExpenseResult {
  const AddExpenseResult({
    required this.expense,
    required this.shares,
  });

  final Expense expense;
  final List<ExpenseShare> shares;
}

/// Service-Interface fuer UC-11 Ausgabe erfassen.
abstract class ExpenseService {
  /// UC-11: Ausgabe erfassen.
  ///
  /// Validiert alle Eingaben, berechnet die Kostenanteile (AF-01)
  /// und speichert Expense + ExpenseShares atomar.
  ///
  /// Vorbedingung: [paidBy] und alle [participantIds] sind Mitglieder
  /// der WG [wgId].
  Future<AddExpenseResult> addExpense({
    required String wgId,
    required String paidBy,
    required double amount,
    required String description,
    required List<String> participantIds,
    required List<String> wgMemberIds,
  });
}
