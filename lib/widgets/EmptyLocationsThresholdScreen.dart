import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../utils/theme.dart';

// Congratulations, you found the 3ast3r 3gg! 🎉
class EmptyLocationsThresholdScreen extends StatefulWidget {
  const EmptyLocationsThresholdScreen({super.key});

  @override
  State<EmptyLocationsThresholdScreen> createState() =>
      _EmptyLocationsThresholdScreenState();
}

class _EmptyLocationsThresholdScreenState
    extends State<EmptyLocationsThresholdScreen> with TickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final AudioPlayer player;

  @override
  void initState() {
    super.initState();

    player = AudioPlayer();

    player.play(AssetSource("bunny.mp3")).then((_) => controller.repeat());
  }

  @override
  void dispose() {
    player.dispose();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedBuilder(
                animation: controller,
                builder: (_, child) => Transform.rotate(
                  angle: controller.value * 2 * math.pi,
                  child: child,
                ),
                child: Icon(
                  context.platformIcons.help,
                  size: 120,
                ),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.volume_up_rounded,
                    size: getCaptionTextStyle(context).fontSize,
                    color: getCaptionTextStyle(context).color,
                  ),
                  const SizedBox(width: TINY_SPACE),
                  Text(
                    l10n.increaseVolume,
                    style: getCaptionTextStyle(context),
                  ),
                ],
              ),
              const SizedBox(height: LARGE_SPACE),
              Text(
                l10n.locationFetchEmptyError,
                style: getBodyTextTextStyle(context),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.bunny_unavailable,
                style: getBodyTextTextStyle(context),
              ),
              const SizedBox(height: LARGE_SPACE),
              PlatformTextButton(
                child: Text(l10n.bunny_unavailable_action),
                onPressed: () => launchUrlString(
                  const Utf8Decoder().convert(
                    const Base64Decoder().convert(
                      "aHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj16UEdmNGxpTy1LUQ==",
                    ),
                  ),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
