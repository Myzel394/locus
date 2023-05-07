import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:lottie/lottie.dart';

class LocationFetchEmpty extends StatelessWidget {
  const LocationFetchEmpty({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Lottie.asset(
              "assets/lotties/empty-list.json",
              frameRate: FrameRate.max,
              repeat: false,
              delegates: LottieDelegates(
                values: [
                  // "X" in lens center
                  ValueDelegate.color(
                    const ["LUPA rotacion 3D", "Group 1", "Fill 1"],
                    value: shades[0],
                  ),
                  // lens background color
                  ValueDelegate.color(
                    const ["LUPA rotacion 3D", "Group 2", "Fill 1"],
                    value: shades[100],
                  ),
                  // Lens border color
                  ValueDelegate.strokeColor(
                    const ["LUPA rotacion 3D", "Group 2", "Stroke 1"],
                    value: shades[0],
                  ),
                  // Lens stem
                  ValueDelegate.color(
                    const ["LUPA rotacion 3D", "Group 3", "Fill 1"],
                    value: shades[0],
                  ),
                  // Text on paper
                  ValueDelegate.strokeColor(
                    const ["line 1 Outlines", "Group 1", "Stroke 1"],
                    value: shades[0],
                  ),
                  ValueDelegate.strokeColor(
                    const ["line 2 Outlines", "Group 1", "Stroke 1"],
                    value: shades[0],
                  ),
                  ValueDelegate.strokeColor(
                    const ["line 3 Outlines", "Group 1", "Stroke 1"],
                    value: shades[0],
                  ),
                  ValueDelegate.strokeColor(
                    const ["line 4 Outlines", "Group 1", "Stroke 1"],
                    value: shades[0],
                  ),
                  // Paper very front
                  ValueDelegate.color(
                    const ["papel bot Outlines", "Group 1", "Fill 1"],
                    value: shades[300],
                  ),
                  // Paper left line
                  ValueDelegate.strokeColor(
                    const ["Papel front Outlines", "Group 2", "Stroke 1"],
                    value: shades[300],
                  ),
                  // Paper front shadow
                  ValueDelegate.color(
                    const ["Papel front Outlines", "Group 3", "Fill 1"],
                    value: shades[100],
                  ),
                  // Paper front
                  ValueDelegate.color(
                    const ["Papel front Outlines", "Group 4", "Fill 1"],
                    value: shades[100],
                  ),
                  // Paper right line
                  ValueDelegate.color(
                    const ["Papel front Outlines", "Group 1", "Fill 1"],
                    value: shades[300],
                  ),
                  // Paper top line
                  ValueDelegate.color(
                    const ["Papel top Outlines", "Group 1", "Fill 1"],
                    value: shades[300],
                  ),
                  ValueDelegate.color(
                    const ["Papel top Outlines", "Group 2", "Fill 1"],
                    value: shades[600],
                  ),
                  // Sparkle circle
                  ValueDelegate.color(
                    const ["circulito Outlines", "Group 1", "Fill 1"],
                    value: shades[0],
                  ),
                  // X circle
                  ValueDelegate.color(
                    const ["x 2 Outlines", "Group 1", "Fill 1"],
                    value: shades[0],
                  ),
                  // Background blob
                  ValueDelegate.color(
                    const ["bg Outlines", "Group 1", "Fill 1"],
                    value: isDarkMode ? shades[900] : shades[200],
                  ),
                ],
              ),
            ),
            Text(
              l10n.locationFetchEmptyError,
              style: getBodyTextTextStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}
