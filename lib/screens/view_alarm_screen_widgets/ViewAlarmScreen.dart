import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/view_alarm_screen_widgets/ViewAlarmSelectRadiusRegionScreen.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import '../../widgets/PlatformFlavorWidget.dart';

class ViewAlarmScreen extends StatefulWidget {
  final TaskView view;

  const ViewAlarmScreen({
    required this.view,
    super.key,
  });

  @override
  State<ViewAlarmScreen> createState() => _ViewAlarmScreenState();
}

class _ViewAlarmScreenState extends State<ViewAlarmScreen> {
  void _addNewAlarm() async {
    final viewService = context.read<ViewService>();
    final RadiusBasedRegionLocationAlarm? alarm = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ViewAlarmSelectRadiusRegionScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (alarm == null) {
      return;
    }

    widget.view.addAlarm(alarm);
    await viewService.update(widget.view);
  }

  Widget getEmptyState() {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        PlatformFlavorWidget(
          cupertino: (_, __) => const Icon(CupertinoIcons.alarm, size: 120),
          material: (_, __) => const Icon(Icons.alarm_rounded, size: 120),
        ),
        const SizedBox(height: LARGE_SPACE),
        Text(
          l10n.location_manageAlarms_empty_title,
          style: getTitle2TextStyle(context),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        Text(
          l10n.location_manageAlarms_empty_description,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MEDIUM_SPACE),
        PlatformElevatedButton(
          onPressed: _addNewAlarm,
          material: (_, __) => MaterialElevatedButtonData(
            icon: const Icon(Icons.add),
          ),
          child: Text(l10n.location_manageAlarms_addNewAlarm_actionLabel),
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    widget.view.addListener(updateView);
  }

  @override
  void dispose() {
    widget.view.removeListener(updateView);

    super.dispose();
  }

  updateView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.location_manageAlarms_title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: widget.view.alarms.isEmpty
                ? getEmptyState()
                : ListView.builder(
                    itemCount: widget.view.alarms.length,
                    itemBuilder: (context, index) {
                      final RadiusBasedRegionLocationAlarm alarm =
                          widget.view.alarms[index] as RadiusBasedRegionLocationAlarm;

                      return PlatformListTile(
                        title: Text(alarm.zoneName),
                        leading: alarm.getIcon(context),
                        trailing: PlatformIconButton(
                          icon: Icon(context.platformIcons.delete),
                          onPressed: () async {
                            final viewService = context.read<ViewService>();

                            widget.view.removeAlarm(alarm);
                            await viewService.update(widget.view);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
