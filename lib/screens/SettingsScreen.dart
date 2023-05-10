import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/widgets/SettingsColorPicker.dart';
import 'package:locus/widgets/SettingsDropdownTile.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/settings_service.dart';
import '../utils/platform.dart';
import '../widgets/RelaySelectSheet.dart';

class SettingsScreen extends StatefulWidget {
  final BuildContext themeContext;

  const SettingsScreen({
    required this.themeContext,
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _relayController = RelayController();

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsService>();
    _relayController.addAll(settings.getRelays());

    _relayController.addListener(() {
      settings.setRelays(_relayController.relays);
      settings.save();
    });
  }

  @override
  void dispose() {
    _relayController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.settingsScreen_title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SettingsList(
                shrinkWrap: true,
                sections: [
                  SettingsSection(
                    title: Text(l10n.settingsScreen_section_design),
                    tiles: [
                      SettingsColorPicker(
                        title: Text(
                            l10n.settingsScreen_setting_primaryColor_label),
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
                        title: Text(
                            l10n.settingsScreen_setting_lookupAddresses_label),
                        description: Text(l10n
                            .settingsScreen_setting_lookupAddresses_description),
                      ),
                      isPlatformApple()
                          ? SettingsDropdownTile(
                              title: Text(
                                l10n.settingsScreen_settings_mapProvider_label,
                              ),
                              values: MapProvider.values,
                              textMapping: {
                                MapProvider.apple: l10n
                                    .settingsScreen_settings_mapProvider_apple,
                                MapProvider.openStreetMap: l10n
                                    .settingsScreen_settings_mapProvider_openStreetMap,
                              },
                              value: settings.mapProvider,
                              onUpdate: (newValue) {
                                settings.setMapProvider(newValue);
                                settings.save();
                              },
                            )
                          : null,
                    ]
                        .where((element) => element != null)
                        .cast<AbstractSettingsTile>()
                        .toList(),
                  ),
                  SettingsSection(
                    title: Text(l10n.settingsScreen_section_defaults),
                    tiles: [
                      SettingsTile(
                        title: Text(l10n.settingsScreen_settings_relays_label),
                        trailing: PlatformTextButton(
                          child: Text(
                            l10n.settingsScreen_settings_relays_selectLabel(
                              _relayController.relays.length,
                            ),
                          ),
                          material: (_, __) => MaterialTextButtonData(
                            icon: const Icon(Icons.dns_rounded),
                          ),
                          onPressed: () async {
                            await showPlatformModalSheet(
                              context: context,
                              material: MaterialModalSheetData(
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                isDismissible: true,
                              ),
                              builder: (_) => RelaySelectSheet(
                                controller: _relayController,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
              Paper(
                child: Padding(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  child: Column(
                    children: <Widget>[
                      Text(
                        l10n.support_title,
                        style: getTitle2TextStyle(context),
                      ),
                      const SizedBox(height: LARGE_SPACE),
                      Icon(
                        context.platformIcons.heartSolid,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: LARGE_SPACE),
                      Text(
                        l10n.support_description,
                        style: getBodyTextTextStyle(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: LARGE_SPACE),
                      PlatformListTile(
                        leading: Icon(Icons.code),
                        title: Text(l10n.support_options_develop),
                        subtitle:
                            Text(l10n.support_options_develop_description),
                        onTap: () {
                          launchUrl(Uri.parse(REPOSITORY_URL));
                        },
                      ),
                      PlatformListTile(
                        leading: Icon(Icons.translate_rounded),
                        title: Text(l10n.support_options_translate),
                        subtitle:
                            Text(l10n.support_options_translate_description),
                        onTap: () {
                          launchUrl(Uri.parse(TRANSLATION_HELP_URL));
                        },
                      ),
                      PlatformListTile(
                        leading: PlatformWidget(
                          material: (_, __) =>
                              const Icon(Icons.attach_money_rounded),
                          cupertino: (_, __) =>
                              const Icon(CupertinoIcons.money_euro),
                        ),
                        title: Text(l10n.support_options_donate),
                        subtitle: Text(l10n.support_options_donate_description),
                        onTap: () {
                          launchUrl(Uri.parse(DONATION_URL));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
