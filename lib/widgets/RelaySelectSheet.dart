import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/widgets/ModalSheet.dart';

import '../api/nostr-relays.dart';

class RelaySelectSheet extends StatefulWidget {
  const RelaySelectSheet({Key? key}) : super(key: key);

  @override
  State<RelaySelectSheet> createState() => _RelaySelectSheetState();
}

class _RelaySelectSheetState extends State<RelaySelectSheet> {
  List<String> _relays = [];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, controller) => ModalSheet(
        child: Column(
          children: <Widget>[
            FutureBuilder(
              future: getNostrRelays(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final relay = snapshot.data![index];

                        return CheckboxListTile(
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
                    ),
                  );
                }

                return PlatformCircularProgressIndicator();
              },
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
