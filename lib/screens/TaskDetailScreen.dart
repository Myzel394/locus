import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/screens/task_detail_screen_widgets/Details.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/widgets/LocationFetchError.dart';
import 'package:locus/widgets/LocationsLoadingScreen.dart';
import 'package:locus/widgets/LocationsMap.dart';

import '../api/get-locations.dart';
import '../constants/spacing.dart';
import '../widgets/LocationFetchEmpty.dart';

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
  final LocationsMapController _controller = LocationsMapController();
  void Function()? _unsubscribeGetLocations;
  bool _isLoading = true;
  bool _isError = false;
  bool _isShowingDetails = false;

  @override
  void initState() {
    super.initState();

    addListener();

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
  }

  @override
  void dispose() {
    _pageController.dispose();

    _unsubscribeGetLocations?.call();

    super.dispose();
  }

  void addListener() async {
    _unsubscribeGetLocations = await getLocations(
      viewPrivateKey: widget.task.viewPGPPrivateKey,
      signPublicKey: widget.task.signPGPPublicKey,
      nostrPublicKey: widget.task.nostrPublicKey,
      relays: widget.task.relays,
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

        // Sort locations
        final locations = _controller.locations.toList();
        locations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _controller.addAll(locations);

        setState(() {
          _isLoading = false;
        });
      },
    );
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
          backgroundColor:
              CupertinoTheme.of(context).barBackgroundColor.withOpacity(.5),
        ),
      ),
      body: _isError
          ? const LocationFetchError()
          : PageView(
              physics: _isShowingDetails
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              controller: _pageController,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: 9,
                      child: _isLoading
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
                          : _controller.locations.isEmpty
                              ? const LocationFetchEmpty()
                              : LocationsMap(
                                  controller: _controller,
                                ),
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
                Expanded(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Details(
                        locations: _controller.locations,
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
                ),
              ],
            ),
    );
  }
}
