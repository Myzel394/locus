import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/screens/view_alarm_screen_widgets/ViewAlarmScreen.dart';
import 'package:locus/screens/view_details_screen_widgets/ViewLocationPointsScreen.dart';
import 'package:locus/services/location_alarm_service.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:locus/utils/bunny.dart';
import 'package:locus/widgets/EmptyLocationsThresholdScreen.dart';
import 'package:locus/widgets/FillUpPaint.dart';
import 'package:locus/widgets/LocationFetchEmpty.dart';
import 'package:locus/widgets/LocationsMap.dart';
import 'package:locus/widgets/OpenInMaps.dart';
import 'package:locus/widgets/PlatformFlavorWidget.dart';
import 'package:locus/widgets/PlatformPopup.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../constants/spacing.dart';
import '../services/location_fetch_controller.dart';
import '../services/location_point_service.dart';
import '../utils/theme.dart';
import '../widgets/LocationFetchError.dart';
import '../widgets/LocationStillFetchingBanner.dart';
import '../widgets/LocationsLoadingScreen.dart';
import '../widgets/PlatformListTile.dart';

const DEBOUNCE_DURATION = Duration(seconds: 2);

class LineSliderTickMarkShape extends SliderTickMarkShape {
  final double tickWidth;

  const LineSliderTickMarkShape({
    this.tickWidth = 1.0,
  }) : super();

  @override
  Size getPreferredSize(
      {required SliderThemeData sliderTheme, required bool isEnabled}) {
    // We don't need this
    return Size.zero;
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required bool isEnabled,
    required TextDirection textDirection,
  }) {
    // This block is just copied from `slider_theme`
    final bool isTickMarkRightOfThumb = center.dx > thumbCenter.dx;
    final begin = isTickMarkRightOfThumb
        ? sliderTheme.disabledInactiveTickMarkColor
        : sliderTheme.disabledActiveTickMarkColor;
    final end = isTickMarkRightOfThumb
        ? sliderTheme.inactiveTickMarkColor
        : sliderTheme.activeTickMarkColor;
    final Paint paint = Paint()
      ..color = ColorTween(begin: begin, end: end).evaluate(enableAnimation)!;

    final trackHeight = sliderTheme.trackHeight!;

    final rect = Rect.fromCenter(
      center: center,
      width: tickWidth,
      height: trackHeight,
    );

    context.canvas.drawRect(rect, paint);
  }
}

class ViewDetailScreen extends StatefulWidget {
  final TaskView view;

  const ViewDetailScreen({
    required this.view,
    Key? key,
  }) : super(key: key);

  @override
  State<ViewDetailScreen> createState() => _ViewDetailScreenState();
}

class _ViewDetailScreenState extends State<ViewDetailScreen> {
  // `_controller` is used to control the actively shown locations on the map
  final LocationsMapController _controller = LocationsMapController();

  // `_locationFetcher.controller` is used to control ALL locations
  late final LocationFetcher _locationFetcher;

  bool _isError = false;

  bool showAlarms = true;

  @override
  void initState() {
    super.initState();

    emptyLocationsCount++;

    _locationFetcher = widget.view.createLocationFetcher(
      onLocationFetched: (final location) {
        emptyLocationsCount = 0;

        _controller.add(location);
        // Only update partially to avoid lag
        EasyThrottle.throttle(
          "${widget.view.id}:location-fetch",
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
  }

  @override
  void dispose() {
    _locationFetcher.dispose();
    _controller.dispose();

    super.dispose();
  }

  VoidCallback handleTapOnDate(final Iterable<LocationPointService> locations) {
    return () {
      _controller.clear();

      if (locations.isNotEmpty) {
        _controller.addAll(locations);
        _controller.goTo(locations.last);
      }

      setState(() {});
    };
  }

  Widget buildDateSelectButton(
    final List<LocationPointService> locations,
    final int hour,
    final int maxLocations,
  ) {
    final shades = getPrimaryColorShades(context);

    return FillUpPaint(
      color: shades[0]!,
      fillPercentage:
          maxLocations == 0 ? 0 : (locations.length.toDouble() / maxLocations),
      size: Size(
        MediaQuery.of(context).size.width / 24,
        MediaQuery.of(context).size.height * (1 / 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locationsPerHour = _locationFetcher.controller.getLocationsPerHour();
    final maxLocations = locationsPerHour.values.isEmpty
        ? 0
        : locationsPerHour.values.fold(
            0,
            (value, element) =>
                value > element.length ? value : element.length);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.viewDetails_title),
        trailingActions: <Widget>[
          if (widget.view.alarms.isNotEmpty)
            PlatformTextButton(
              cupertino: (_, __) => CupertinoTextButtonData(
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                setState(() {
                  showAlarms = !showAlarms;
                });
              },
              child: PlatformFlavorWidget(
                material: (_, __) => showAlarms
                    ? const Icon(Icons.alarm_rounded)
                    : const Icon(Icons.alarm_off_rounded),
                cupertino: (_, __) => showAlarms
                    ? const Icon(CupertinoIcons.alarm)
                    : const Icon(Icons.alarm_off_rounded),
              ),
            ),
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
                            builder: (_) => ViewAlarmScreen(view: widget.view),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          NativePageRoute(
                            context: context,
                            builder: (_) => ViewAlarmScreen(view: widget.view),
                          ),
                        );
                      }
                    }),
                if (_locationFetcher.controller.locations.isNotEmpty)
                  PlatformPopupMenuItem(
                    label: PlatformListTile(
                      leading: Icon(context.platformIcons.location),
                      trailing: const SizedBox.shrink(),
                      title: Text(l10n.viewDetails_actions_openLatestLocation),
                    ),
                    onPressed: () => showPlatformModalSheet(
                      context: context,
                      material: MaterialModalSheetData(),
                      builder: (context) => OpenInMaps(
                        destination: Coords(
                          _locationFetcher.controller.locations.last.latitude,
                          _locationFetcher.controller.locations.last.longitude,
                        ),
                      ),
                    ),
                  ),
                if (_locationFetcher.controller.locations.isNotEmpty)
                  PlatformPopupMenuItem(
                    label: PlatformListTile(
                      leading: PlatformFlavorWidget(
                        material: (_, __) => const Icon(Icons.list_rounded),
                        cupertino: (_, __) =>
                            const Icon(CupertinoIcons.list_bullet),
                      ),
                      trailing: const SizedBox.shrink(),
                      title: Text(l10n.viewDetails_actions_showLocationList),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        NativePageRoute(
                          context: context,
                          builder: (context) => ViewLocationPointsScreen(
                            locationFetcher: _locationFetcher,
                          ),
                        ),
                      );
                    },
                  ),
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
      body: (() {
        if (_isError) {
          return const LocationFetchError();
        }

        if (_locationFetcher.controller.locations.isNotEmpty) {
          return PageView(
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    flex: 11,
                    child: Stack(
                      children: <Widget>[
                        LocationsMap(
                            controller: _controller,
                            showCircles: showAlarms,
                            circles: List<LocationsMapCircle>.from(
                              List<RadiusBasedRegionLocationAlarm>.from(
                                      widget.view.alarms)
                                  .map(
                                (final alarm) => LocationsMapCircle(
                                  id: alarm.id,
                                  center: alarm.center,
                                  radius: alarm.radius,
                                  color: Colors.red.withOpacity(.3),
                                  strokeColor: Colors.red,
                                ),
                              ),
                            )),
                        if (_locationFetcher.isLoading)
                          const LocationStillFetchingBanner(),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          List.generate(24, (index) => 23 - index).map((hour) {
                        final date =
                            DateTime.now().subtract(Duration(hours: hour));
                        final normalizedDate =
                            LocationsMapController.normalizeDateTime(date);
                        final locations =
                            locationsPerHour[normalizedDate] ?? [];
                        final child = buildDateSelectButton(
                          locations,
                          hour,
                          maxLocations,
                        );

                        return PlatformWidget(
                          material: (_, __) => InkWell(
                            onTap: handleTapOnDate(locations),
                            child: child,
                          ),
                          cupertino: (_, __) => GestureDetector(
                            onTap: handleTapOnDate(locations),
                            child: child,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        if (_locationFetcher.isLoading) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(MEDIUM_SPACE),
              child: LocationsLoadingScreen(
                locations: _locationFetcher.controller.locations,
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
    );
  }
}
