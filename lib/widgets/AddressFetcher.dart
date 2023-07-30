import 'package:flutter/widgets.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/services/settings_service.dart';
import 'package:provider/provider.dart';

class AddressFetcher extends StatefulWidget {
  final double latitude;
  final double longitude;

  final Widget Function(String address) builder;
  final Widget Function(bool isLoading) rawLocationBuilder;

  const AddressFetcher({
    required this.latitude,
    required this.longitude,
    required this.builder,
    required this.rawLocationBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<AddressFetcher> createState() => _AddressFetcherState();
}

class _AddressFetcherState extends State<AddressFetcher> {
  bool isLoading = false;
  String? address;

  @override
  initState() {
    super.initState();

    final settings = context.read<SettingsService>();

    if (settings.automaticallyLookupAddresses) {
      loadAddress();
    }
  }

  Future<void> loadAddress() async {
    final settings = context.read<SettingsService>();

    setState(() {
      isLoading = true;
    });

    try {
      FlutterLogs.logInfo(
        LOG_TAG,
        "AddressFetcher",
        "Loading address",
      );
      final address = await settings.getAddress(
        widget.latitude,
        widget.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        this.address = address;
      });
    } catch (error) {
      FlutterLogs.logError(
        LOG_TAG,
        "AddressFetcher",
        "Failed to load address: $error",
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    if (address != null) {
      return widget.builder(address!);
    }

    if (!settings.automaticallyLookupAddresses) {
      return GestureDetector(
        onTap: () {
          loadAddress();
        },
        child: widget.rawLocationBuilder(isLoading),
      );
    }

    return widget.rawLocationBuilder(isLoading);
  }
}
