import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/task_detail_screen_widgets/Details.dart';
import 'package:locus/services/location_fetch_controller.dart';
import 'package:locus/services/task_service.dart';
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
  final PageController _pageController = PageController();
  late final LocationFetcher _locationFetcher;
  bool _isError = false;
  bool _isShowingDetails = false;

  @override
  void initState() {
    super.initState();

    emptyLocationsCount++;

    _locationFetcher = widget.task.createLocationFetcher(
      onLocationFetched: (final location) {
        emptyLocationsCount = 0;
        // Only update partially to avoid lag
        EasyThrottle.throttle(
          "${widget.task.id}:location-fetch",
          DEBOUNCE_DURATION,
          () {
            if (!mounted) {
              return;
            }
            setState(() {});
          },
        );
      },
    );

    _locationFetcher.fetchMore(
      onEnd: () {
        setState(() {});
      },
    );

    _pageController.addListener(() {
      if (_pageController.page == 0) {
        setState(() {
          _isShowingDetails = false;
        });
      } else {
        setState(() {
          _isShowingDetails = true;
        });
      }
    });

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
  void dispose() {
    _pageController.dispose();
    _locationFetcher.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(
          _isShowingDetails ? l10n.taskDetails_title : widget.task.name,
        ),
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: getCupertinoAppBarColorForMapScreen(context),
        ),
        trailingActions: [
          if (_locationFetcher.controller.locations.isNotEmpty &&
              !_isShowingDetails)
            PlatformIconButton(
              cupertino: (_, __) => CupertinoIconButtonData(
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.my_location_rounded),
              onPressed: () {
                // No need to check for location permission, as the user must enable it to create locations
                // in the first place
                _locationFetcher.controller.goToUserLocation();
              },
            ),
          PlatformIconButton(
            cupertino: (_, __) => CupertinoIconButtonData(
              padding: EdgeInsets.zero,
            ),
            icon: Icon(context.platformIcons.help),
            onPressed: showHelp,
          ),
          Padding(
            padding: isMaterial(context)
                ? const EdgeInsets.all(SMALL_SPACE)
                : EdgeInsets.zero,
            child: PlatformPopup<String>(
              type: PlatformPopupType.tap,
              cupertinoButtonPadding: EdgeInsets.zero,
              items: [
                PlatformPopupMenuItem(
                  label: PlatformListTile(
                    leading: Icon(context.platformIcons.location),
                    trailing: const SizedBox.shrink(),
                    title: Text(l10n.viewDetails_actions_openLatestLocation),
                  ),
                  onPressed: () async {
                    await showPlatformModalSheet(
                      context: context,
                      material: MaterialModalSheetData(
                        backgroundColor: Colors.transparent,
                      ),
                      builder: (context) => OpenInMaps(
                        destination: Coords(
                          _locationFetcher.controller.locations.last.latitude,
                          _locationFetcher.controller.locations.last.longitude,
                        ),
                      ),
                    );
                  },
                ),
                // If the fetched locations are less than the limit,
                // there are definitely no more locations to fetch
                if (_locationFetcher.canFetchMore)
                  PlatformPopupMenuItem(
                    label: PlatformListTile(
                      leading: Icon(context.platformIcons.refresh),
                      trailing: const SizedBox.shrink(),
                      title: Text(l10n.locationFetcher_actions_fetchMore),
                    ),
                    onPressed: () {
                      _locationFetcher.fetchMore(onEnd: () {
                        setState(() {});
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _isError
          ? const LocationFetchError()
          : PageView(
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              controller: _pageController,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: 9,
                      child: (() {
                        if (_locationFetcher.controller.locations.isNotEmpty) {
                          return Stack(
                            children: <Widget>[
                              LocationsMap(
                                controller: _locationFetcher.controller,
                              ),
                              if (_locationFetcher.isLoading)
                                const LocationStillFetchingBanner(),
                            ],
                          );
                        }

                        if (_locationFetcher.isLoading) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(MEDIUM_SPACE),
                              child: LocationsLoadingScreen(
                                locations:
                                    _locationFetcher.controller.locations,
                                onTimeout: () {
                                  setState(() {
                                    _isError = true;
                                  });
                                },
                              ),
                            ),
                          );
                        }

                        if (emptyLocationsCount > EMPTY_LOCATION_THRESHOLD) {
                          return const EmptyLocationsThresholdScreen();
                        }

                        return const LocationFetchEmpty();
                      })(),
                    ),
                    Expanded(
                      flex: 1,
                      child: PlatformTextButton(
                        material: (_, __) => MaterialTextButtonData(
                          style: ButtonStyle(
                            // Not rounded, but square
                            shape: MaterialStateProperty.all(
                              const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                        ),
                        child: Text(l10n.taskDetails_goToDetails),
                        onPressed: () {
                          _pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    child: Details(
                      locations: _locationFetcher.controller.locations,
                      task: widget.task,
                      onGoBack: () {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
