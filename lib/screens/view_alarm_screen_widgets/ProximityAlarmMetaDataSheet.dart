import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/location_alarm_service/ProximityLocationAlarm.dart';
import 'package:locus/services/location_alarm_service/enums.dart';
import 'package:locus/utils/theme.dart';

import '../../widgets/ModalSheet.dart';
import '../../widgets/PlatformListTile.dart';

class ProximityAlarmMetaDataSheet extends StatelessWidget {
  final double radius;

  const ProximityAlarmMetaDataSheet({
    required this.radius,
    super.key,
  });

  void _createAlarm(
    final BuildContext context,
    final LocationRadiusBasedTriggerType type,
  ) {
    final alarm = ProximityLocationAlarm.create(
      radius: radius,
      type: type,
    );

    Navigator.pop(
      context,
      alarm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModalSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.location_addAlarm_radiusBased_trigger_title,
            style: getSubTitleTextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          PlatformListTile(
            onTap: () {
              _createAlarm(context, LocationRadiusBasedTriggerType.whenEnter);
            },
            leading: const Icon(Icons.arrow_circle_right_rounded),
            title: Text(l10n.location_addAlarm_radiusBased_trigger_whenEnter),
          ),
          PlatformListTile(
            onTap: () {
              _createAlarm(context, LocationRadiusBasedTriggerType.whenLeave);
            },
            leading: const Icon(Icons.arrow_circle_left_rounded),
            title: Text(l10n.location_addAlarm_radiusBased_trigger_whenLeave),
          ),
        ],
      ),
    );
  }
}
