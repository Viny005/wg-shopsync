/// Returns true if the environment is known to be offline.
///
/// Default stub for non-web environments: returns false so native Firestore
/// connectivity handling applies.
bool isDeviceOffline() => false;
