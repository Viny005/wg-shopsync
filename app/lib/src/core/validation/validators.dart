/// Fachliche Eingabevalidierung gemäß A08 8.2 und D2.8.
///
/// Gibt jeweils `null` zurück, wenn der Wert gültig ist, sonst eine
/// verständliche Fehlermeldung für die Anzeige im Formular.
class Validators {
  const Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bitte gib eine E-Mail-Adresse ein.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Bitte gib eine gueltige E-Mail-Adresse ein.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte gib dein Passwort ein.';
    }
    return null;
  }

  /// Neues Passwort bei der Registrierung: mindestens 8 Zeichen (siehe B1.3).
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte gib ein Passwort ein.';
    }
    if (value.length < 8) {
      return 'Das Passwort muss mindestens 8 Zeichen lang sein.';
    }
    return null;
  }

  /// Passwort-Bestätigung: muss mit [password] übereinstimmen.
  static String? Function(String?) passwordConfirmation(String password) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Bitte bestaetige dein Passwort.';
      }
      if (value != password) {
        return 'Die Passwoerter stimmen nicht ueberein.';
      }
      return null;
    };
  }

  /// Benutzername: 2 bis 50 Zeichen, nicht leer.
  static String? userName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Bitte gib einen Namen ein.';
    }
    if (trimmed.length < 2 || trimmed.length > 50) {
      return 'Der Name muss zwischen 2 und 50 Zeichen lang sein.';
    }
    return null;
  }

  /// Artikelname: 1 bis 100 Zeichen, nicht leer.
  static String? itemName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Bitte gib einen Artikelnamen ein.';
    }
    if (trimmed.length > 100) {
      return 'Der Artikelname darf hoechstens 100 Zeichen lang sein.';
    }
    return null;
  }

  /// Artikelbeschreibung: optional, höchstens 500 Zeichen.
  static String? itemDescription(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length > 500) {
      return 'Die Beschreibung darf hoechstens 500 Zeichen lang sein.';
    }
    return null;
  }

  /// Menge: positive Ganzzahl.
  static String? quantity(int? value) {
    if (value == null) {
      return null;
    }
    if (value <= 0) {
      return 'Die Menge muss eine positive Ganzzahl sein.';
    }
    return null;
  }

  /// Ausgabebetrag: größer als 0.
  static String? expenseAmount(double? value) {
    if (value == null || value <= 0) {
      return 'Der Betrag muss groesser als 0 sein.';
    }
    return null;
  }

  /// Einladungscode: sechs alphanumerische Zeichen.
  static String? inviteCode(String? value) {
    final trimmed = value?.trim() ?? '';
    if (!RegExp(r'^[a-zA-Z0-9]{6}$').hasMatch(trimmed)) {
      return 'Der Einladungscode muss aus 6 alphanumerischen Zeichen bestehen.';
    }
    return null;
  }
}
