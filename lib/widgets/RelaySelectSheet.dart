import 'dart:collection';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/load_status.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/BottomSheetFilterBuilder.dart';
import 'package:locus/widgets/ModalSheet.dart';

import '../api/nostr-relays.dart';

class RelayController extends ChangeNotifier {
  late final List<String> _relays;

  RelayController({
    List<String>? relays,
  }) : _relays = relays ?? [];

  UnmodifiableListView<String> get relays => UnmodifiableListView(_relays);

  void add(final String relay) {
    _relays.add(relay);
    notifyListeners();
  }

  void remove(final String relay) {
    _relays.remove(relay);
    notifyListeners();
  }

  void removeAt(final int index) {
    _relays.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _relays.clear();
    notifyListeners();
  }

  void addAll(final List<String> relays) {
    _relays.addAll(relays);
    notifyListeners();
  }
}

class RelaySelectSheet extends StatefulWidget {
  final RelayController controller;

  const RelaySelectSheet({
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  State<RelaySelectSheet> createState() => _RelaySelectSheetState();
}

class _RelaySelectSheetState extends State<RelaySelectSheet> {
  List<String> availableRelays = [];
  LoadStatus loadStatus = LoadStatus.loading;
  final _searchController = TextEditingController();
  late final DraggableScrollableController _sheetController;

  Set<String> get checkedRelaysSet => Set.from(widget.controller.relays);

  @override
  void initState() {
    super.initState();
    fetchAvailableRelays();

    widget.controller.addListener(rebuild);
    _sheetController = DraggableScrollableController();
  }

  @override
  dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    widget.controller.removeListener(rebuild);

    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  Future<void> fetchAvailableRelays() async {
    try {
      final relays = await getNostrRelays();

      relays.shuffle();

      setState(() {
        availableRelays = relays;
        loadStatus = LoadStatus.success;
      });
    } catch (_) {
      setState(() {
        loadStatus = LoadStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      expand: false,
      controller: _sheetController,
      builder: (context, controller) => ModalSheet(
        child: Column(
          children: <Widget>[
            if (loadStatus == LoadStatus.loading)
              Expanded(
                child: Center(
                  child: PlatformCircularProgressIndicator(),
                ),
              )
            else if (loadStatus == LoadStatus.error)
              Text(
                l10n.unknownError,
                style: TextStyle(
                  color: getErrorColor(context),
                ),
              )
            else if (availableRelays.isNotEmpty)
              Expanded(
                child: BottomSheetFilterBuilder(
                  elements: availableRelays,
                  searchController: _searchController,
                  onSearchFocusChanged: (hasFocus) async {
                    if (hasFocus) {
                      _sheetController.animateTo(
                        1,
                        duration: 500.ms,
                        curve: Curves.linearToEaseOut,
                      );
                    }
                  },
                  extractValue: (dynamic element) => element as String,
                  builder: (_, List<dynamic> foundRelays) {
                    final uncheckedFoundRelays = foundRelays
                        .where((element) => !checkedRelaysSet.contains(element))
                        .toList();
                    final allRelays = List<String>.from(
                        [...widget.controller.relays, ...uncheckedFoundRelays]);

                    return PlatformWidget(
                      material: (context, _) => ListView.builder(
                        controller: controller,
                        itemCount: allRelays.length,
                        itemBuilder: (context, index) {
                          final relay = allRelays[index];

                          return CheckboxListTile(
                            title: Text(
                              relay.substring(6),
                            ),
                            value: widget.controller.relays.contains(relay),
                            onChanged: (newValue) {
                              if (newValue == null) {
                                return;
                              }

                              if (newValue) {
                                widget.controller.add(relay);
                              } else {
                                widget.controller.remove(relay);
                              }
                            },
                          );
                        },
                      ),
                      cupertino: (context, _) => ImplicitlyAnimatedList<String>(
                        items: allRelays,
                        controller: controller,
                        areItemsTheSame: (a, b) => a == b,
                        itemBuilder: (context, animation, relay, index) {
                          return SizeFadeTransition(
                            animation: animation,
                            sizeFraction: 0.7,
                            curve: Curves.easeInOut,
                            child: CupertinoListTile(
                              title: Text(
                                relay.substring(6),
                              ),
                              leading: CupertinoSwitch(
                                value: widget.controller.relays.contains(relay),
                                onChanged: (newValue) {
                                  if (newValue) {
                                    widget.controller.add(relay);
                                  } else {
                                    widget.controller.remove(relay);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: MEDIUM_SPACE),
            PlatformTextButton(
              material: (_, __) => MaterialTextButtonData(
                icon: const Icon(Icons.shuffle),
              ),
              onPressed: loadStatus == LoadStatus.success
                  ? () {
                      final relays = availableRelays.toList();
                      relays.shuffle();

                      widget.controller.clear();
                      widget.controller.addAll(relays.take(5).toList());
                    }
                  : null,
              child: Text(l10n.relaySelectSheet_selectRandomRelays(5)),
            ),
            const SizedBox(height: SMALL_SPACE),
            PlatformElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              material: (_, __) => MaterialElevatedButtonData(
                icon: const Icon(Icons.done),
              ),
              child: Text(l10n.closePositiveSheetAction),
            ),
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom,
            )
          ],
        ),
      ),
    );
  }
}
