import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:openpgp/openpgp.dart';

import 'ExchangeScreen.dart';

final storage = FlutterSecureStorage();

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({Key? key}) : super(key: key);

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isCreatingKeys = false;

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void createKeys() async {
    setState(() {
      _isCreatingKeys = true;
    });

    try {
      var keyOptions = KeyOptions()..rsaBits = 2048;
      var keyPair =
          await OpenPGP.generate(options: Options()..keyOptions = keyOptions);

      await storage.write(key: "PGP_PRIVATE_KEY", value: keyPair.privateKey);
      await storage.write(key: "NAME", value: _controller.text);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExchangeScreen(
            privateKey: keyPair.privateKey,
            publicKey: keyPair.publicKey,
            name: _controller.text,
          ),
        ),
      );
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
              PlatformTextField(
                controller: _controller,
                keyboardType: TextInputType.name,
                material: (_, __) => MaterialTextFieldData(
                  decoration: InputDecoration(
                    labelText: l10n.initialization_form_field_name_label,
                  ),
                ),
                cupertino: (_, __) => CupertinoTextFieldData(
                  placeholder: l10n.initialization_form_field_name_label,
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
