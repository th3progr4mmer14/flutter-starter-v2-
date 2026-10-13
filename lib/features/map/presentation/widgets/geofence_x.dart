import '../../../../l10n/l10n_x.dart';
import '../../domain/geofence.dart';

extension GeofenceTriggerX on GeofenceTrigger {
  String label(AppLocalizations l) => switch (this) {
        GeofenceTrigger.exit => l.triggerExit,
        GeofenceTrigger.enter => l.triggerEnter,
      };
}
