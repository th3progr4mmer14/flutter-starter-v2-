import '../../l10n/l10n_x.dart';
import 'failures.dart';

extension FailureX on Failure {
  /// Mensaje listo para mostrar: el del servidor si lo hay; si no, uno
  /// traducido según el tipo de error.
  String localized(AppLocalizations l) {
    if (fromServer && message.isNotEmpty) return message;
    return switch (type) {
      FailureType.network => l.errNetwork,
      FailureType.timeout => l.errTimeout,
      FailureType.unauthorized => l.errUnauthorized,
      FailureType.forbidden => l.errForbidden,
      FailureType.notFound => l.errNotFound,
      FailureType.validation => l.errValidation,
      FailureType.server => l.errServer,
      FailureType.cancelled => l.errUnknown,
      FailureType.unknown => l.errUnknown,
    };
  }
}
