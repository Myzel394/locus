import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart' hide PlatformListTile;
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/utils/theme.dart';

import '../../widgets/ModalSheet.dart';
import '../../widgets/PlatformListTile.dart';

class RadiusRegionMetaDataSheet extends StatefulWidget {
  final LatLng center;
  final double radius;

  const RadiusRegionMetaDataSheet({
    required this.center,
    required this.radius,
    super.key,
  });

  @override
  State<RadiusRegionMetaDataSheet> createState() => _RadiusRegionMetaDataSheetState();
}

class _RadiusRegionMetaDataSheetState extends State<RadiusRegionMetaDataSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  RadiusBasedRegionLocationAlarmType? _type;

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ModalSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _type == null
            ? <Widget>[
                Text(
                  l10n.location_addAlarm_radiusBased_trigger_title,
                  style: getSubTitleTextStyle(context),
                ),
                const SizedBox(height: MEDIUM_SPACE),
                PlatformListTile(
                  onTap: () {
                    setState(() {
                      _type = RadiusBasedRegionLocationAlarmType.whenEnter;
                    });
                  },
                  leading: const Icon(Icons.arrow_circle_right_rounded),
                  title: Text(l10n.location_addAlarm_radiusBased_trigger_whenEnter),
                ),
                PlatformListTile(
                  onTap: () {
                    setState(() {
                      _type = RadiusBasedRegionLocationAlarmType.whenLeave;
                    });
                  },
                  leading: const Icon(Icons.arrow_circle_left_rounded),
                  title: Text(l10n.location_addAlarm_radiusBased_trigger_whenLeave),
                ),
              ]
            : [
                Text(
                  l10n.location_addAlarm_radiusBased_name_description,
                  style: getSubTitleTextStyle(context),
                ),
                const SizedBox(height: MEDIUM_SPACE),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.fields_errors_isEmpty;
                      }

                      if (!StringUtils.isAscii(value)) {
                        return l10n.fields_errors_invalidCharacters;
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(height: MEDIUM_SPACE),
                PlatformElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(
                        context,
                        RadiusBasedRegionLocationAlarm.create(
                          zoneName: _nameController.text,
                          center: widget.center,
                          radius: widget.radius,
                          type: _type!,
                        ),
                      );
                    }
                  },
                  child: Text(l10n.location_addAlarm_actionLabel),
                ),
              ],
      ),
    );
  }
}
