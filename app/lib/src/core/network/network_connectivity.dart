import 'network_connectivity_stub.dart'
    if (dart.library.html) 'network_connectivity_web.dart' as impl;

/// Returns true if the client/browser is known to be offline.
///
/// On Flutter Web, evaluates `window.navigator.onLine == false` to prevent
/// initiating transactions that would inevitably fail with uncatchable native errors.
/// On native platforms, returns false so standard Firestore offline handling applies.
bool isDeviceOffline() => impl.isDeviceOffline();
