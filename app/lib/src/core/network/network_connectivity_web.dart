// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Returns true if the browser reports `navigator.onLine == false`.
bool isDeviceOffline() => html.window.navigator.onLine == false;
