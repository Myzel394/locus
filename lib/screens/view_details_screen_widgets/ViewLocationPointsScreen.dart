import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/location_fetch_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../task_detail_screen_widgets/LocationDetails.dart';

class ViewLocationPointsScreen extends StatefulWidget {
  final LocationFetcher locationFetcher;

  const ViewLocationPointsScreen({
    required this.locationFetcher,
    super.key,
  });

  @override
  State<ViewLocationPointsScreen> createState() => _ViewLocationPointsScreenState();
}

class _ViewLocationPointsScreenState extends State<ViewLocationPointsScreen> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    widget.locationFetcher.addListener(updateView);

    _controller.addListener(() {
      print(widget.locationFetcher.canFetchMore);
      if (!widget.locationFetcher.canFetchMore) {
        return;
      }

      if (_controller.position.atEdge) {
        final isTop = _controller.position.pixels == 0;

        if (!isTop) {
          widget.locationFetcher.fetchMore(onEnd: () {
            setState(() {});
          });
        }
      }
    });
  }

  updateView() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.locationFetcher.removeListener(updateView);
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.locationPointsScreen_title),
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: ListView.builder(
            shrinkWrap: true,
            controller: _controller,
            itemCount: widget.locationFetcher.controller.locations.length + (widget.locationFetcher.isLoading ? 1 : 0),
            itemBuilder: (_, index) {
              if (index == widget.locationFetcher.controller.locations.length) {
                return const Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return LocationDetails(
                location: widget.locationFetcher.controller.locations[index],
                isPreview: false,
              );
            },
          ),
        ),
      ),
    );
  }
}
