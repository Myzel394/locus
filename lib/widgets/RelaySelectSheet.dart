import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/api/get-relays-meta.dart';
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
  final List<String> availableRelays = [];
  final Map<String, RelayMeta> relayMeta = {};
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
    _fetchAvailableRelays();
    _fetchRelaysMeta();

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

  // Filters all relays whether they are suitable
  void _filterRelaysFromMeta() {
    if (relayMeta.isEmpty || availableRelays.isEmpty) {
      return;
    }

    final suitableRelays = relayMeta.values
        .where((meta) => meta.isSuitable)
        .map((meta) => meta.relay)
        .toSet();

    setState(() {
      availableRelays.retainWhere(suitableRelays.contains);
      availableRelays.sort(
        (a, b) => relayMeta[a]!.score > relayMeta[b]!.score ? 1 : -1,
      );
      loadStatus = LoadStatus.success;
    });
  }

  Future<void> _fetchRelaysMeta() async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Relay Select Sheet",
      "Fetching relays meta...",
    );

    try {
      final relaysMetaDataRaw =
          await withCache(fetchRelaysMeta, "relays-meta")();
      final relaysMetaData = relaysMetaDataRaw["meta"] as List<RelayMeta>;
      final newRelays = Map.fromEntries(
        relaysMetaData.map((meta) => MapEntry(meta.relay, meta)),
      );

      relayMeta.clear();
      relayMeta.addAll(newRelays);
      _filterRelaysFromMeta();

      setState(() {});
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "Relay Select Sheet",
        "Failed to fetch available relays: $error",
      );
    }
  }

  Future<void> _fetchAvailableRelays() async {
    FlutterLogs.logInfo(
      LOG_TAG,
      "Relay Select Sheet",
      "Fetching available relays...",
    );

    try {
      final relaysData = await withCache(getNostrRelays, "relays")();
      final relays = List<String>.from(relaysData["relays"] as List<dynamic>);

      relays.shuffle();

      availableRelays
        ..clear()
        ..addAll(relays);
      _filterRelaysFromMeta();

      setState(() {});
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

        return ListView.builder(
          controller: draggableController,
          // Add 2 so we can show <add new value> and <hint> widgets
          itemCount: allRelays.length + 2,
          itemBuilder: (context, rawIndex) {
            if (rawIndex == 0) {
              if (isValueNew) {
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
              return Container();
            }

            if (rawIndex == 1) {
              return loadStatus == LoadStatus.loading
                  ? Padding(
                      padding: const EdgeInsets.all(MEDIUM_SPACE),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox.square(
                            dimension: 20,
                            child: PlatformCircularProgressIndicator(),
                          ),
                          const SizedBox(width: MEDIUM_SPACE),
                          Text(l10n.relaySelectSheet_loadingRelaysMeta),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(MEDIUM_SPACE),
                      child: Row(
                        children: [
                          Icon(
                            context.platformIcons.info,
                            color: getCaptionTextStyle(context).color,
                          ),
                          const SizedBox(width: MEDIUM_SPACE),
                          Flexible(
                            child: Text(
                              l10n.relaySelectSheet_hint,
                              style: getCaptionTextStyle(context),
                            ),
                          ),
                        ],
                      ),
                    );
            }

            final index = rawIndex - 1;
            final relay = allRelays[index];
            final meta = relayMeta[relay];

            return PlatformWidget(
              material: (context, _) => CheckboxListTile(
                title: Text(
                  relay.length >= 6 ? relay.substring(6) : relay,
                ),
                subtitle: meta == null ? null : Text(meta.description),
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
                subtitle: meta == null ? null : Text(meta.description),
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
            if (loadStatus == LoadStatus.loading && availableRelays.isEmpty)
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
