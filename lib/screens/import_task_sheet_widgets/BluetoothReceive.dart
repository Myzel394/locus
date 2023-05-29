import 'package:english_words/english_words.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/bluetooth.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/BluetoothPermissionRequiredScreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:lottie/lottie.dart';

class BluetoothReceive extends StatefulWidget {
  const BluetoothReceive({Key? key}) : super(key: key);

  @override
  State<BluetoothReceive> createState() => _BluetoothReceiveState();
}

class _BluetoothReceiveState extends State<BluetoothReceive> with BluetoothPermissionMixin {
  final String id = createIdentifier();
  String? connectionID;

  static String createIdentifier() {
    final wordPair = generateWordPairs().first;

    return "${wordPair.first} ${wordPair.second}";
  }

  @override
  void initState() {
    super.initState();

    checkBluetoothPermission();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: (() {
              if (!hasGrantedBluetoothPermission) {
                return BluetoothPermissionRequiredScreen(onRequest: checkBluetoothPermission);
              }

              if (connectionID == null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Lottie.asset(
                      "assets/lottie/bluetooth.json",
                      frameRate: FrameRate.max,
                      repeat: true,
                    ),
                    Text(
                      l10n.bluetoothReceive_title,
                      style: getTitle2TextStyle(context),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(l10n.bluetoothReceive_description),
                    const SizedBox(height: LARGE_SPACE),
                    Text(
                      l10n.bluetoothReceive_name_description,
                      style: getCaptionTextStyle(context),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                    Paper(
                      child: Padding(
                        padding: const EdgeInsets.all(MEDIUM_SPACE),
                        child: Text(id),
                      ),
                    ),
                  ],
                );
              }
            })(),
          ),
        ),
      ),
    );
  }
}
