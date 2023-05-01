import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:locus/api/get-locations.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/widgets/FillUpPaint.dart';
import 'package:locus/widgets/LocationsMap.dart';

import '../constants/spacing.dart';
import '../services/location_point_service.dart';
import '../utils/theme.dart';
import '../widgets/LocationsLoadingScreen.dart';

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

  addListener() async {
    _unsubscribeGetLocations = await getLocations(
      viewPrivateKey: widget.view.viewPrivateKey,
      signPublicKey: widget.view.signPublicKey,
      nostrPublicKey: widget.view.nostrPublicKey,
      relays: widget.view.relays,
      from: DateTime.now().subtract(1.days),
      onLocationFetched: (final LocationPointService location) {
        if (!mounted) {
          return;
        }

        _controller.add(location);
        setState(() {});
      },
      onEnd: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('View Detail'),
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor:
              CupertinoTheme.of(context).barBackgroundColor.withOpacity(.5),
        ),
      ),
      body: _isError
          ? Center(
              child: Text(
                "There was an error fetching the locations. Please try again later.",
                style: getBodyTextTextStyle(context).copyWith(
                  color: Colors.red,
                ),
              ),
            )
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

                          return PlatformInkWell(
                            onTap: () {
                              _controller.clear();

                              final locations =
                                  locationsPerHour[normalizedDate] ?? [];

                              if (locations.isNotEmpty) {
                                _controller.addAll(locations);
                                _controller.goTo(locations.last);
                              }
                            },
                            child: FillUpPaint(
                              color: shades[0]!,
                              fillPercentage:
                                  (locationsPerHour[normalizedDate]?.length ??
                                              0)
                                          .toDouble() /
                                      maxLocations,
                              size: Size(
                                MediaQuery.of(context).size.width / 24,
                                MediaQuery.of(context).size.height * (1 / 12),
                              ),
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
