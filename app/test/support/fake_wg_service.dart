import 'package:wg_shopsync/src/features/wg/application/wg_service.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';

class FakeWgService extends WgService {
  FakeWgService({
    this.currentContext,
    List<CurrentWgContext?>? contextSequence,
    this.leaveWgError,
  }) : _contextSequence =
            contextSequence != null ? List.of(contextSequence) : null;

  CurrentWgContext? currentContext;
  final List<CurrentWgContext?>? _contextSequence;
  Object? leaveWgError;
  List<Membership> members = const [];
  int loadWgMembersCalls = 0;

  int loadCurrentWgCalls = 0;
  int leaveWgCalls = 0;
  String? lastLeaveWgId;
  String? lastLeaveUserId;

  @override
  Future<CurrentWgContext?> loadCurrentWg({
    required String userId,
  }) async {
    loadCurrentWgCalls++;
    if (_contextSequence != null && _contextSequence.isNotEmpty) {
      return _contextSequence.removeAt(0);
    }
    return currentContext;
  }

  @override
  Future<void> leaveWg({
    required String wgId,
    required String userId,
  }) async {
    leaveWgCalls++;
    lastLeaveWgId = wgId;
    lastLeaveUserId = userId;
    if (leaveWgError != null) {
      throw leaveWgError!;
    }
  }
  @override
  Future<List<Membership>> loadWgMembers({
    required String wgId,
  }) async {
    loadWgMembersCalls++;
    return members;
  }
}
