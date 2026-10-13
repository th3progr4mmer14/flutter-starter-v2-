import 'package:flutter/widgets.dart';

import '../../l10n/l10n_x.dart';

/// Validadores con mensajes localizados. Uso:
///   validator: Validators.email(context)
class Validators {
  Validators._();

  static FormFieldValidator<String> required(BuildContext context) {
    final l = context.l10n;
    return (v) => (v == null || v.trim().isEmpty) ? l.fieldRequired : null;
  }

  static FormFieldValidator<String> email(BuildContext context) {
    final l = context.l10n;
    return (v) {
      if (v == null || v.trim().isEmpty) return l.fieldRequired;
      final regex = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
      return regex.hasMatch(v.trim()) ? null : l.invalidEmail;
    };
  }

  static FormFieldValidator<String> password(BuildContext context) {
    final l = context.l10n;
    return (v) {
      if (v == null || v.isEmpty) return l.fieldRequired;
      return v.length < 6 ? l.passwordMin : null;
    };
  }

  static FormFieldValidator<String> positiveNumber(BuildContext context) {
    final l = context.l10n;
    return (v) {
      if (v == null || v.trim().isEmpty) return l.fieldRequired;
      final n = double.tryParse(v.trim().replaceAll(',', '.'));
      return (n == null || n <= 0) ? l.invalidNumber : null;
    };
  }

  /// Coordenada opcional: vacío es válido; si hay valor debe estar en [-max, max].
  /// Latitud: max = 90, longitud: max = 180.
  static FormFieldValidator<String> coordinate(BuildContext context,
      {required double max}) {
    final l = context.l10n;
    return (v) {
      if (v == null || v.trim().isEmpty) return null;
      final n = double.tryParse(v.trim().replaceAll(',', '.'));
      if (n == null || n < -max || n > max) return l.invalidCoordinate;
      return null;
    };
  }

  static FormFieldValidator<String> number(BuildContext context) {
    final l = context.l10n;
    return (v) {
      if (v == null || v.trim().isEmpty) return l.fieldRequired;
      return double.tryParse(v.trim().replaceAll(',', '.')) == null
          ? l.invalidNumber
          : null;
    };
  }
}
