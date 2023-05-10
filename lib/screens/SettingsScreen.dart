import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/widgets/SettingsColorPicker.dart';
import 'package:locus/widgets/SettingsDropdownTile.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../services/settings_service.dart';
import '../utils/platform.dart';

class SettingsScreen extends StatelessWidget {
  final BuildContext themeContext;

  const SettingsScreen({
    required this.themeContext,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.settingsScreen_title),
      ),
      body: SafeArea(
        child: SettingsList(
          sections: [
            SettingsSection(
              title: Text(l10n.settingsScreen_section_design),
              tiles: [
                SettingsColorPicker(
                  title: Text(l10n.settingsScreen_setting_primaryColor_label),
                  value: settings.primaryColor,
                  onUpdate: (value) {
                    settings.setPrimaryColor(value);
                    settings.save();
                  },
                )
              ],
            ),
            SettingsSection(
              title: Text(l10n.settingsScreen_section_privacy),
              tiles: [
                SettingsTile.switchTile(
                  initialValue: settings.automaticallyLookupAddresses,
                  onToggle: (newValue) {
                    settings.setAutomaticallyLookupAddresses(newValue);
                    settings.save();
                  },
                  title: Text(l10n.settingsScreen_setting_lookupAddresses_label),
                  description: Text(l10n.settingsScreen_setting_lookupAddresses_description),
                ),
                isPlatformApple()
                    ? SettingsDropdownTile(
                        title: Text(
                          l10n.settingsScreen_settings_mapProvider_label,
                        ),
                        values: MapProvider.values,
                        textMapping: {
                          MapProvider.apple: l10n.settingsScreen_settings_mapProvider_apple,
                          MapProvider.openStreetMap: l10n.settingsScreen_settings_mapProvider_openStreetMap,
                        },
                        value: settings.mapProvider,
                        onUpdate: (newValue) {
                          settings.setMapProvider(newValue);
                          settings.save();
                        },
                      )
                    : null,
              ].where((element) => element != null).cast<AbstractSettingsTile>().toList(),
            ),
          ],
        ),
      ),
    );
  }
}
