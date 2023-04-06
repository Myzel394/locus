import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/load_status.dart';
import 'package:locus/widgets/BottomSheetFilterBuilder.dart';
import 'package:locus/widgets/ModalSheet.dart';

import '../api/nostr-relays.dart';

class RelaySelectSheet extends StatefulWidget {
  List<String> selectedRelays;

  RelaySelectSheet({this.selectedRelays = const [], Key? key}) : super(key: key);

  @override
  State<RelaySelectSheet> createState() => _RelaySelectSheetState();
}

class _RelaySelectSheetState extends State<RelaySelectSheet> {
  List<String> availableRelays = [];
  LoadStatus loadStatus = LoadStatus.loading;
  List<String> _relays = [];
  final _searchController = TextEditingController();
  final _sheetController = DraggableScrollableController();
  final _searchFocusNode = FocusNode();

  Set<String> get checkedRelaysSet => Set.from(widget.selectedRelays);

  @override
  void initState() {
    super.initState();
    fetchAvailableRelays();

    _relays = [...widget.selectedRelays];

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _sheetController.animateTo(1, duration: const Duration(milliseconds: 100), curve: Curves.linearToEaseOut);
      }
    });
  }

  @override
  dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
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
    return DraggableScrollableSheet(
      expand: false,
      controller: _sheetController,
      builder: (context, controller) =>
          ModalSheet(
            child: Column(
              children: <Widget>[
                if (loadStatus == LoadStatus.loading)
                  Expanded(
                    child: Center(
                      child: PlatformCircularProgressIndicator(),
                    ),
                  )
                else
                  if (loadStatus == LoadStatus.error)
                    const Text(
                      'Error loading relays',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    if (availableRelays.isNotEmpty)
                      Expanded(
                        child: BottomSheetFilterBuilder(
                            elements: availableRelays,
                            searchController: _searchController,
                            searchFocusNode: _searchFocusNode,
                            extractValue: (dynamic element) => element as String,
                            builder: (_, List<dynamic> foundRelays) {
                              final uncheckedFoundRelays =
                              foundRelays.where((element) => !checkedRelaysSet.contains(element)).toList();
                              final allRelays = [...widget.selectedRelays, ...uncheckedFoundRelays];

                              return ListView.builder(
                                controller: controller,
                                itemCount: allRelays.length,
                                itemBuilder: (context, index) {
                                  final relay = allRelays[index];

                                  return PlatformCheckboxListTile(
                                    title: Text(
                                      relay.substring(6),
                                    ),
                                    value: _relays.contains(relay),
                                    onChanged: (newValue) {
                                      if (newValue == null) {
                                        return;
                                      }

                                      if (newValue) {
                                        setState(() {
                                          _relays.add(relay);
                                        });
                                      } else {
                                        setState(() {
                                          _relays.remove(relay);
                                        });
                                      }
                                    },
                                  );
                                },
                              );
                            }),
                      ),
                const SizedBox(height: SMALL_SPACE),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_relays);
                  },
                  child: Text('Done'),
                ),
              ],
            ),
          ),
    );
  }
}
