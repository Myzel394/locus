import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/screens/view_alarm_screen_widgets/ViewAlarmScreen.dart';
import 'package:locus/screens/view_details_screen_widgets/LocationPointsList.dart';
import 'package:locus/services/view_service/index.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:locus/widgets/PlatformPopup.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../constants/spacing.dart';
import '../utils/theme.dart';
import '../widgets/PlatformListTile.dart';

class ViewDetailsScreen extends StatelessWidget {
  final TaskView view;

  const ViewDetailsScreen({
    super.key,
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.viewDetails_title),
        trailingActions: <Widget>[
          Padding(
            padding: isMaterial(context)
                ? const EdgeInsets.all(SMALL_SPACE)
                : EdgeInsets.zero,
            child: PlatformPopup<String>(
              cupertinoButtonPadding: EdgeInsets.zero,
              type: PlatformPopupType.tap,
              items: [
                PlatformPopupMenuItem(
                    label: PlatformListTile(
                      leading: PlatformFlavorWidget(
                        cupertino: (_, __) => const Icon(CupertinoIcons.alarm),
                        material: (_, __) => const Icon(Icons.alarm_rounded),
                      ),
                      title: Text(l10n.location_manageAlarms_title),
                      trailing: const SizedBox.shrink(),
                    ),
                    onPressed: () {
                      if (isCupertino(context)) {
                        Navigator.of(context).push(
                          MaterialWithModalsPageRoute(
                            builder: (_) => ViewAlarmScreen(view: view),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          NativePageRoute(
                            context: context,
                            builder: (_) => ViewAlarmScreen(view: view),
                          ),
                        );
                      }
                    }),
              ],
            ),
          ),
        ],
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: getCupertinoAppBarColorForMapScreen(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Column(
            children: <Widget>[
              Paper(
                child: LocationPointsList(
                  view: view,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
