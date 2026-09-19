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
        }) async => Expense(
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
        }) async => expense,
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
}
