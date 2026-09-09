import 'package:cloud_firestore/cloud_firestore.dart';

/// Konvertiert einen Firestore-Wert (typischerweise [Timestamp]) sicher in
/// [DateTime]. Vermeidet TypeError, wenn Firestore ein Timestamp-Objekt statt
/// eines DateTime liefert.
DateTime dateTimeFromFirestore(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  throw ArgumentError('Erwartet Timestamp oder DateTime, erhalten: $value');
}

/// Wie [dateTimeFromFirestore], aber toleriert `null` für optionale Felder.
DateTime? dateTimeFromFirestoreOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  return dateTimeFromFirestore(value);
}
