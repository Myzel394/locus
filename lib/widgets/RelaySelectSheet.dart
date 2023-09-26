import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/location_point_service.dart';
import 'package:locus/utils/load_status.dart';
import 'package:locus/utils/nostr_fetcher/NostrSocket.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/BottomSheetFilterBuilder.dart';
import 'package:locus/widgets/ModalSheet.dart';
import 'package:nostr/nostr.dart';

import '../api/nostr-relays.dart';
import '../utils/cache.dart';

String removeProtocol(final String url) =>
    url.toLowerCase().replaceAll(RegExp(r'^wss://'), '');

String addProtocol(final String url) =>
    url.toLowerCase().startsWith('wss://') ? url : 'wss://$url';

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
  String _newValue = '';
  bool _isPoppingNavigation = false;

  Set<String> get checkedRelaysSet => Set.from(widget.controller.relays);

  bool get isValueNew => _newValue.isNotEmpty;

  @override
  void initState() {
    super.initState();
    fetchAvailableRelays();

    widget.controller.addListener(rebuild);
    _searchController.addListener(() {
      final value = removeProtocol(_searchController.text.toLowerCase());

      if (value.isEmpty) {
        setState(() {
          _newValue = '';
        });
        return;
      }

      final normalizedRelays = availableRelays.map(removeProtocol);

      if (normalizedRelays.contains(value)) {
        setState(() {
          _newValue = "";
        });
        return;
      }

      final normalizedSelectedRelays =
          widget.controller.relays.map(removeProtocol);

      if (normalizedSelectedRelays.contains(value)) {
        setState(() {
          _newValue = "";
        });
        return;
      }

      final newValue = addProtocol(value);

      if (Uri.tryParse(newValue) == null) {
        setState(() {
          _newValue = "";
        });
        return;
      }

      setState(() {
        _newValue = newValue;
      });
    });

    _sheetController = DraggableScrollableController();
    _sheetController.addListener(() {
      if (_sheetController.size <= 0.4) {
        _closeSheet();
      }
    });

    final socket = NostrSocket(
      relay: "wss://history.nostr.watch",
      decryptMessage: (_) async {
        return LocationPointService.dummyFromLatLng(LatLng(0, 0));
      },
    );
    socket.connect().then((_) {
      socket.addData(
        Request(
          generate64RandomHexChars(),
          [
            NostrSocket.createNostrRequestData(
              kinds: [30304],
              limit: 10,
              authors: [
                "b3b0d247f66bf40c4c9f4ce721abfe1fd3b7529fbc1ea5e64d5f0f8df3a4b6e6"
              ],
            ),
          ],
        ).serialize(),
      );
    });
  }

  _closeSheet() {
    if (_isPoppingNavigation) {
      return;
    }

    Navigator.pop(context);

    _isPoppingNavigation = true;
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
    FlutterLogs.logInfo(
      LOG_TAG,
      "Relay Select Sheet",
      "Fetching available relays...",
    );

    try {
      final relaysData = await withCache(getNostrRelays, "relays")();
      final relays = List<String>.from(relaysData["relays"] as List<dynamic>);

      relays.shuffle();

      setState(() {
        availableRelays = relays;
        loadStatus = LoadStatus.success;
      });
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Relay Select Sheet",
        "Failed to fetch available relays: $error",
      );

      setState(() {
        loadStatus = LoadStatus.error;
      });
    }
  }

  Widget buildRelaySelectSheet(final ScrollController draggableController) {
    final l10n = AppLocalizations.of(context);

    return BottomSheetFilterBuilder(
      elements: availableRelays,
      searchController: _searchController,
      onSearchFocusChanged: (hasFocus) async {
        if (hasFocus) {
          _sheetController.jumpTo(1);
        }
      },
      extractValue: (dynamic element) => element as String,
      builder: (_, List<dynamic> foundRelays) {
        final uncheckedFoundRelays = foundRelays
            .where((element) => !checkedRelaysSet.contains(element))
            .toList();
        final allRelays = List<String>.from(
            [...widget.controller.relays, ...uncheckedFoundRelays]);

        final length = allRelays.length + (isValueNew ? 1 : 0);

        return ListView.builder(
          controller: draggableController,
          itemCount: length,
          itemBuilder: (context, rawIndex) {
            if (isValueNew && rawIndex == 0) {
              return PlatformWidget(
                material: (context, _) => ListTile(
                  title: Text(
                    l10n.addNewValueLabel(_newValue),
                  ),
                  leading: const Icon(
                    Icons.add,
                  ),
                  onTap: () {
                    widget.controller.add(_searchController.value.text);
                    _searchController.clear();
                  },
                ),
                cupertino: (context, _) => CupertinoButton(
                  child: Text(
                    l10n.addNewValueLabel(_newValue),
                  ),
                  onPressed: () {
                    widget.controller.add(_searchController.value.text);
                    _searchController.clear();
                  },
                ),
              );
            }

            final index = isValueNew ? rawIndex - 1 : rawIndex;
            final relay = allRelays[index];

            return PlatformWidget(
              material: (context, _) => CheckboxListTile(
                title: Text(
                  relay.length >= 6 ? relay.substring(6) : relay,
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
              ),
              cupertino: (context, _) => CupertinoListTile(
                title: Text(
                  relay.length >= 6 ? relay.substring(6) : relay,
                ),
                trailing: CupertinoSwitch(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      expand: false,
      controller: _sheetController,
      builder: (context, controller) => ModalSheet(
        miuiIsGapless: true,
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
                child: buildRelaySelectSheet(controller),
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
