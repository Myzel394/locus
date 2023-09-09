import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/task_detail_screen_widgets/Details.dart';
import 'package:locus/services/location_fetch_controller.dart';
import 'package:locus/services/task_service/index.dart';
import 'package:locus/utils/bunny.dart';
import 'package:locus/widgets/EmptyLocationsThresholdScreen.dart';
import 'package:locus/widgets/LocationFetchError.dart';
import 'package:locus/widgets/LocationStillFetchingBanner.dart';
import 'package:locus/widgets/LocationsLoadingScreen.dart';
import 'package:locus/widgets/LocationsMap.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../constants/spacing.dart';
import 'package:locus/services/settings_service/index.dart';
import '../utils/helper_sheet.dart';
import '../utils/theme.dart';
import '../widgets/LocationFetchEmpty.dart';
import '../widgets/OpenInMaps.dart';
import '../widgets/PlatformPopup.dart';

const DEBOUNCE_DURATION = Duration(seconds: 2);
const DEFAULT_LOCATION_LIMIT = 50;

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    required this.task,
    Key? key,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsService>();

      if (!settings.hasSeenHelperSheet(HelperSheet.taskShare)) {
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) {
          return;
        }

        showHelp();
      }
    });
  }

  void showHelp() {
    final l10n = AppLocalizations.of(context);

    showHelperSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(context.platformIcons.share),
              const SizedBox(width: MEDIUM_SPACE),
              Flexible(
                child: Text(l10n.taskDetails_share_help_shareDescription),
              ),
            ],
          ),
          const SizedBox(height: MEDIUM_SPACE),
          Row(
            children: <Widget>[
              const Icon(Icons.install_mobile_rounded),
              const SizedBox(width: MEDIUM_SPACE),
              Flexible(
                child: Text(l10n.taskDetails_share_help_appDescription),
              ),
            ],
          ),
          const SizedBox(height: MEDIUM_SPACE),
          Row(
            children: <Widget>[
              const Icon(MdiIcons.web),
              const SizedBox(width: MEDIUM_SPACE),
              Flexible(
                child: Text(l10n.taskDetails_share_help_webDescription),
              ),
            ],
          ),
        ],
      ),
      title: l10n.taskDetails_share_help_title,
      sheetName: HelperSheet.taskShare,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(widget.task.name),
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: getCupertinoAppBarColorForMapScreen(context),
        ),
        trailingActions: [
          PlatformIconButton(
            cupertino: (_, __) => CupertinoIconButtonData(
              padding: EdgeInsets.zero,
            ),
            icon: Icon(context.platformIcons.help),
            onPressed: showHelp,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Details(
            task: widget.task,
          ),
        ),
      ),
    );
  }
}
