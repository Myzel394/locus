import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/api/nostr-relays.dart';

class RelaySelect extends StatefulWidget {
  final bool multiple;
  final List<String> value;
  final void Function(List<String>) onChanged;

  const RelaySelect({
    Key? key,
    required this.value,
    required this.onChanged,
    this.multiple = false,
  }) : super(key: key);

  @override
  State<RelaySelect> createState() => _RelaySelectState();
}

class _RelaySelectState extends State<RelaySelect> {
  bool _isFetchingRelays = false;
  List<String> _relays = [];

  @override
  void initState() {
    super.initState();

    fetchRelays();
  }

  void fetchRelays() async {
    setState(() {
      _isFetchingRelays = true;
    });

    try {
      final relays = await getNostrRelays();

      setState(() {
        _relays = relays;
        _isFetchingRelays = false;
      });
    } catch (error) {
      setState(() {
        _isFetchingRelays = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingRelays) {
      return Center(
        child: PlatformCircularProgressIndicator(),
      );
    }

    print(_relays);

    return ListView.builder(
      itemCount: _relays.length,
      itemBuilder: (context, index) {
        final relay = _relays[index];

        return CheckboxListTile(
          title: Text(
            relay.substring(6),
          ),
          value: widget.value.contains(relay),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            if (widget.multiple) {
              if (value) {
                widget.onChanged([...widget.value, relay]);
              } else {
                widget
                    .onChanged(widget.value.where((r) => r != relay).toList());
              }
            } else {
              if (value) {
                widget.onChanged([relay]);
              } else {
                widget.onChanged([]);
              }
            }
          },
        );
      },
    );
  }
}
