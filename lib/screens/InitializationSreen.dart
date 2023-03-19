import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RelaySelect.dart';
import 'package:nostr/nostr.dart';
import 'package:openpgp/openpgp.dart';

final storage = const FlutterSecureStorage();

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({Key? key}) : super(key: key);

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  List<String> _relays = [];
  bool _isCreatingKeys = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void createKeys() async {
    setState(() {
      _isCreatingKeys = true;
    });

    try {
      var keyOptions = KeyOptions()..rsaBits = 2048;
      var keyPair =
          await OpenPGP.generate(options: Options()..keyOptions = keyOptions);
      var nostrKeyPair = Keychain.generate();

      await storage.write(key: "PGP_PRIVATE_KEY", value: keyPair.privateKey);
      await storage.write(key: "PGP_PUBLIC_KEY", value: keyPair.publicKey);
      await storage.write(
          key: "NOSTR_PRIVATE_KEY", value: nostrKeyPair.private);
      await storage.write(key: "NOSTR_PUBLIC_KEY", value: nostrKeyPair.public);
      await storage.write(key: "RELAYS", value: _relays.join(","));

      return;

      Navigator.of(context).pushReplacementNamed("/home");
    } catch (error) {
      setState(() {
        _isCreatingKeys = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                l10n.initialization_title,
                style: getTitleTextStyle(context),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.initialization_description,
                style: getBodyTextTextStyle(context),
              ),
              const SizedBox(height: LARGE_SPACE),
              Expanded(
                child: RelaySelect(
                  multiple: true,
                  value: _relays,
                  onChanged: (value) {
                    setState(() {
                      _relays = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: LARGE_SPACE),
              PlatformElevatedButton(
                onPressed: _isCreatingKeys ? null : createKeys,
                child: Text(l10n.initialization_continue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
