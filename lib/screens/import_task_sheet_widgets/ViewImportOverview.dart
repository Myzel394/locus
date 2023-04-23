import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locus/services/view_service.dart';
import 'package:openpgp/openpgp.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

class ViewImportOverview extends StatelessWidget {
  final TaskView view;
  final void Function() onGoToNameEdit;
  final void Function() onImport;

  const ViewImportOverview({
    required this.view,
    required this.onGoToNameEdit,
    required this.onImport,
    Key? key,
  }) : super(key: key);

  Future<String> getFingerprintFromKey(final String key) async {
    final metadata = await OpenPGP.getPublicKeyMetadata(key);

    return metadata.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          "Do you want to import this task?",
          style: getBodyTextTextStyle(context),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        ListView(
          shrinkWrap: true,
          children: <Widget>[
            ListTile(
              title: Text(view.name!),
              subtitle: const Text("Name"),
              leading: PlatformWidget(
                material: (_, __) => const Icon(Icons.text_fields_rounded),
                cupertino: (_, __) => const Icon(CupertinoIcons.textformat),
              ),
              trailing: PlatformIconButton(
                icon: Icon(context.platformIcons.edit),
                onPressed: onGoToNameEdit,
              ),
            ),
            ListTile(
              title: Text(view.relays.join(", ")),
              subtitle: const Text("Relays"),
              leading: const Icon(Icons.dns_rounded),
            ),
            ListTile(
              title: Text(view.nostrPublicKey),
              subtitle: const Text("Public Nostr Key"),
              leading: const Icon(Icons.key),
            ),
            ListTile(
              title: FutureBuilder<String>(
                  future: getFingerprintFromKey(view.signPublicKey),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!);
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  }),
              subtitle: const Text("Public Sign Key"),
              leading: const Icon(Icons.edit),
            )
          ],
        ),
        const SizedBox(height: MEDIUM_SPACE),
        PlatformElevatedButton(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          onPressed: onImport,
          material: (_, __) => MaterialElevatedButtonData(
            icon: const Icon(Icons.file_download_outlined),
          ),
          child: const Text("Import"),
        ),
      ],
    );
  }
}
