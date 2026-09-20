import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/expense.dart';
import 'package:wg_shopsync/src/features/expense/application/expense_service.dart';

void main() {
  group('UC-11: ExpenseService.createExpense input validation', () {
    final service = ExpenseService();

    test('rejects empty wgId', () {
      expect(
        () => service.createExpense(
          wgId: '',
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty paidBy', () {
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: 'Einkauf',
          paidBy: '',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects amount <= 0', () {
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 0,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: -5,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects amount with more than two decimal places', () {
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10.999,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty or whitespace-only description', () {
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: '',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: '   ',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects when no participants are selected', () {
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects duplicate participants', () {
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1', 'user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects blank participant IDs', () {
      expect(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1', '   '],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('trims description before persisting', () async {
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => true,
        persistence: ({
          required wgId,
          required expense,
          required shares,
          required participantUserIds,
        }) async =>
            Expense(
          id: expense.id,
          wgId: expense.wgId,
          amount: expense.amount,
          description: expense.description,
          paidBy: expense.paidBy,
          shoppingItemId: expense.shoppingItemId,
          receiptUrl: expense.receiptUrl,
          createdAt: expense.createdAt,
        ),
      );

      final created = await service.createExpense(
        wgId: 'wg-1',
        amount: 10,
        description: '  Einkauf  ',
        paidBy: 'user-1',
        participantUserIds: ['user-1'],
      );

      expect(created.description, 'Einkauf');
    });

    test('keeps the pre-generated expense identifier through persistence',
        () async {
      String? idSeenByPersistence;
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => true,
        persistence: ({
          required wgId,
          required expense,
          required shares,
          required participantUserIds,
        }) async {
          idSeenByPersistence = expense.id;
          return expense;
        },
      );

      final created = await service.createExpense(
        wgId: 'wg-1',
        amount: 10,
        description: 'Einkauf',
        paidBy: 'user-1',
        participantUserIds: ['user-1'],
      );

      expect(created.id, isNotEmpty);
      expect(idSeenByPersistence, created.id);
    });
  });

  group('UC-11: ExpenseService.createExpense membership validation', () {
    test('throws ExpensePayerNotMemberException when payer is not a member',
        () async {
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => userId != 'outsider',
      );

      await expectLater(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: 'Einkauf',
          paidBy: 'outsider',
          participantUserIds: ['outsider'],
        ),
        throwsA(isA<ExpensePayerNotMemberException>()),
      );
    });

    test(
        'throws ExpenseParticipantNotMemberException when a participant is not a member',
        () async {
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => userId != 'outsider',
      );

      await expectLater(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1', 'outsider'],
        ),
        throwsA(isA<ExpenseParticipantNotMemberException>()),
      );
    });

    test('accepts a valid expense when all members are valid', () async {
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async =>
            ['user-1', 'user-2'].contains(userId),
        persistence: ({
          required wgId,
          required expense,
          required shares,
          required participantUserIds,
        }) async =>
            expense,
      );

      await expectLater(
        () => service.createExpense(
          wgId: 'wg-1',
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1', 'user-2'],
        ),
        returnsNormally,
      );
    });
  });
  group('UC-12: ExpenseService.updateExpense input validation', () {
    final service = ExpenseService();

    final baseExpense = Expense(
      id: 'expense-1',
      wgId: 'wg-1',
      amount: 10,
      description: 'Einkauf',
      paidBy: 'user-1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('rejects empty wgId', () {
      final expense = Expense(
        id: 'expense-1',
        wgId: '',
        amount: 10,
        description: 'Einkauf',
        paidBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        () => service.updateExpense(
          originalExpense: expense,
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty expenseId', () {
      final expense = Expense(
        id: '',
        wgId: 'wg-1',
        amount: 10,
        description: 'Einkauf',
        paidBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        () => service.updateExpense(
          originalExpense: expense,
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty paidBy', () {
      expect(
        () => service.updateExpense(
          originalExpense: baseExpense,
          amount: 10,
          description: 'Einkauf',
          paidBy: '',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects amount <= 0', () {
      expect(
        () => service.updateExpense(
          originalExpense: baseExpense,
          amount: 0,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects amount with more than two decimal places', () {
      expect(
        () => service.updateExpense(
          originalExpense: baseExpense,
          amount: 10.999,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty description', () {
      expect(
        () => service.updateExpense(
          originalExpense: baseExpense,
          amount: 10,
          description: '   ',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects no participants', () {
      expect(
        () => service.updateExpense(
          originalExpense: baseExpense,
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: const [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty participant id', () {
      expect(
        () => service.updateExpense(
          originalExpense: baseExpense,
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1', ''],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects duplicate participants', () {
      expect(
        () => service.updateExpense(
          originalExpense: baseExpense,
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1', 'user-1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('trims description before persisting', () async {
      String? trimmedSeen;
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => true,
        updatePersistence: ({
          required originalExpense,
          required amount,
          required description,
          required paidBy,
          required participantUserIds,
          required shares,
        }) async {
          trimmedSeen = description;
          return originalExpense.copyWith(
            amount: amount,
            description: description,
            paidBy: paidBy,
          );
        },
      );

      await service.updateExpense(
        originalExpense: baseExpense,
        amount: 10,
        description: '  Einkauf  ',
        paidBy: 'user-1',
        participantUserIds: ['user-1'],
      );

      expect(trimmedSeen, 'Einkauf');
    });
  });

  group('UC-12: ExpenseService.updateExpense membership checks', () {
    test('rejects payer who is not a WG member', () async {
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => userId != 'user-x',
      );

      final expense = Expense(
        id: 'expense-1',
        wgId: 'wg-1',
        amount: 10,
        description: 'Einkauf',
        paidBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await expectLater(
        () => service.updateExpense(
          originalExpense: expense,
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-x',
          participantUserIds: ['user-x'],
        ),
        throwsA(isA<ExpensePayerNotMemberException>()),
      );
    });

    test('rejects participant who is not a WG member', () async {
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => userId != 'user-y',
      );

      final expense = Expense(
        id: 'expense-1',
        wgId: 'wg-1',
        amount: 10,
        description: 'Einkauf',
        paidBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await expectLater(
        () => service.updateExpense(
          originalExpense: expense,
          amount: 10,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1', 'user-y'],
        ),
        throwsA(isA<ExpenseParticipantNotMemberException>()),
      );
    });
  });

  group('UC-12: ExpenseService.updateExpense offline handling', () {
    test('rejects the update while offline', () async {
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => true,
        isOfflineChecker: () => true,
      );

      final expense = Expense(
        id: 'expense-1',
        wgId: 'wg-1',
        amount: 10,
        description: 'Einkauf',
        paidBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await expectLater(
        () => service.updateExpense(
          originalExpense: expense,
          amount: 12,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        ),
        throwsA(isA<ExpenseRequiresConnectionException>()),
      );
    });
  });

  group('UC-12: ExpenseService.updateExpense AF-01 and persistence', () {
    test('splits 10.00 across three participants and keeps identity fields',
        () async {
      Map<String, double>? sharesSeen;
      List<String>? participantsSeen;
      Expense? persistedOriginal;

      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => true,
        updatePersistence: ({
          required originalExpense,
          required amount,
          required description,
          required paidBy,
          required participantUserIds,
          required shares,
        }) async {
          sharesSeen = shares;
          participantsSeen = participantUserIds;
          persistedOriginal = originalExpense;
          return originalExpense.copyWith(
            amount: amount,
            description: description,
            paidBy: paidBy,
          );
        },
      );

      final expense = Expense(
        id: 'expense-1',
        wgId: 'wg-1',
        amount: 5,
        description: 'Alt',
        paidBy: 'user-1',
        shoppingItemId: 'item-1',
        receiptUrl: 'https://example.com/receipt.png',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final result = await service.updateExpense(
        originalExpense: expense,
        amount: 10,
        description: 'Neu',
        paidBy: 'user-1',
        participantUserIds: ['user-1', 'user-2', 'user-3'],
      );

      final sum = sharesSeen!.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(10, 0.001));
      expect(participantsSeen, ['user-1', 'user-2', 'user-3']);

      // Unveraenderliche Felder bleiben erhalten.
      expect(result.id, 'expense-1');
      expect(result.wgId, 'wg-1');
      expect(result.createdAt, DateTime(2026, 1, 1));
      expect(persistedOriginal!.shoppingItemId, 'item-1');
      expect(persistedOriginal!.receiptUrl, 'https://example.com/receipt.png');

      // Geaenderte Felder wurden uebernommen.
      expect(result.amount, 10);
      expect(result.description, 'Neu');
    });
  });

  group('UC-12: ExpenseService.updateExpense conflict outcome', () {
    test('conflict result carries the server expense', () async {
      final serverExpense = Expense(
        id: 'expense-1',
        wgId: 'wg-1',
        amount: 99,
        description: 'Von anderem Mitglied geaendert',
        paidBy: 'user-2',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 5),
      );

      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => true,
        updatePersistence: ({
          required originalExpense,
          required amount,
          required description,
          required paidBy,
          required participantUserIds,
          required shares,
        }) async {
          throw ExpenseConflictException(serverExpense: serverExpense);
        },
      );

      final staleExpense = Expense(
        id: 'expense-1',
        wgId: 'wg-1',
        amount: 10,
        description: 'Einkauf',
        paidBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      try {
        await service.updateExpense(
          originalExpense: staleExpense,
          amount: 12,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1'],
        );
        fail('expected ExpenseConflictException');
      } on ExpenseConflictException catch (e) {
        expect(e.serverExpense.amount, 99);
        expect(e.serverExpense.paidBy, 'user-2');
      }
    });
  });

  group('UC-13: ExpenseService.updateExpense settled expense protection', () {
    test('gibt ExpenseAlreadySettledException korrekt weiter', () async {
      final service = ExpenseService(
        membershipChecker: (wgId, userId) async => true,
        updatePersistence: ({
          required originalExpense,
          required amount,
          required description,
          required paidBy,
          required participantUserIds,
          required shares,
        }) async {
          throw const ExpenseAlreadySettledException();
        },
      );

      final expense = Expense(
        id: 'expense-1',
        wgId: 'wg-1',
        amount: 10,
        description: 'Einkauf',
        paidBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await expectLater(
        () => service.updateExpense(
          originalExpense: expense,
          amount: 12,
          description: 'Einkauf',
          paidBy: 'user-1',
          participantUserIds: ['user-1', 'user-2'],
        ),
        throwsA(isA<ExpenseAlreadySettledException>()),
      );
    });
  });
}
