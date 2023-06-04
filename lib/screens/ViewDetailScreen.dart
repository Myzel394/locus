import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/services/view_service.dart';
import 'package:locus/widgets/FillUpPaint.dart';
import 'package:locus/widgets/LocationFetchError.dart';
import 'package:locus/widgets/LocationsMap.dart';
import 'package:locus/widgets/OpenInMaps.dart';
import 'package:locus/widgets/PlatformPopup.dart';
import 'package:map_launcher/map_launcher.dart';

import '../constants/spacing.dart';
import '../services/location_point_service.dart';
import '../utils/theme.dart';
import '../widgets/LocationsLoadingScreen.dart';
import '../widgets/PlatformListTile.dart';

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
  void Function()? _unsubscribeGetLocations;
  final LocationsMapController _controller = LocationsMapController();
  bool _isLoading = true;
  bool _isError = false;

  double timeOffset = 0;

  @override
  void initState() {
    super.initState();

    addListener();
  }

  @override
  void dispose() {
    _unsubscribeGetLocations?.call();
    _controller.dispose();

    super.dispose();
  }

  addListener() {
    _unsubscribeGetLocations = widget.view.getLocations(
      from: DateTime.now().subtract(1.days),
      onLocationFetched: (final LocationPointService location) {
        if (!mounted) {
          return;
        }

        _controller.add(location);
        setState(() {});
      },
      onEnd: () {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locationsPerHour = _controller.getLocationsPerHour();
    final maxLocations = locationsPerHour.values.isEmpty
        ? 0
        : locationsPerHour.values.fold(
            0,
            (value, element) =>
                value > element.length ? value : element.length);
    final shades = getPrimaryColorShades(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.viewDetails_title),
        trailingActions: _controller.locations.isNotEmpty
            ? <Widget>[
                PlatformPopup<String>(
                  type: PlatformPopupType.tap,
                  items: [
                    PlatformPopupMenuItem(
                      label: PlatformListTile(
                        leading: Icon(context.platformIcons.location),
                        trailing: const SizedBox.shrink(),
                        title:
                            Text(l10n.viewDetails_actions_openLatestLocation),
                      ),
                      onPressed: () async {
                        await showPlatformModalSheet(
                          context: context,
                          material: MaterialModalSheetData(),
                          builder: (context) => OpenInMaps(
                            destination: Coords(
                                _controller.locations.last.latitude,
                                _controller.locations.last.longitude),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ]
            : [],
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor:
              CupertinoTheme.of(context).barBackgroundColor.withOpacity(.5),
        ),
      ),
      body: _isError
          ? const LocationFetchError()
          : _isLoading
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(MEDIUM_SPACE),
                    child: LocationsLoadingScreen(
                      locations: _controller.locations,
                      onTimeout: () {
                        setState(() {
                          _isError = true;
                        });
                      },
                    ),
                  ),
                )
              : Column(
                  children: <Widget>[
                    Expanded(
                      flex: 11,
                      child: LocationsMap(
                        controller: _controller,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(24, (index) => 23 - index)
                            .map((hour) {
                          final date =
                              DateTime.now().subtract(Duration(hours: hour));
                          final normalizedDate =
                              LocationsMapController.normalizeDateTime(date);

                          final onTap = () {
                            _controller.clear();

                            final locations =
                                locationsPerHour[normalizedDate] ?? [];

                            if (locations.isNotEmpty) {
                              _controller.addAll(locations);
                              _controller.goTo(locations.last);
                            }
                          };
                          final child = FillUpPaint(
                            color: shades[0]!,
                            fillPercentage:
                                (locationsPerHour[normalizedDate]?.length ?? 0)
                                        .toDouble() /
                                    maxLocations,
                            size: Size(
                              MediaQuery.of(context).size.width / 24,
                              MediaQuery.of(context).size.height * (1 / 12),
                            ),
                          );

                          return PlatformWidget(
                            material: (_, __) => InkWell(
                              onTap: onTap,
                              child: child,
                            ),
                            cupertino: (_, __) => GestureDetector(
                              onTap: onTap,
                              child: child,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }
}
