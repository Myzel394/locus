import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/constants/spacing.dart';
import 'package:locus/constants/values.dart';
import 'package:locus/screens/settings_screen_widgets/MentionTile.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/Paper.dart';
import 'package:locus/widgets/SettingsColorPicker.dart';
import 'package:locus/widgets/SettingsDropdownTile.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

import '../services/settings_service.dart';
import '../utils/platform.dart';
import '../widgets/PlatformListTile.dart';
import '../widgets/RelaySelectSheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _relayController = RelayController();
  bool _enableHighlight = true;

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsService>();
    _relayController.addAll(settings.getRelays());

    _relayController.addListener(() {
      settings.setRelays(_relayController.relays);
      settings.save();
    });

    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      setState(() {
        _enableHighlight = false;
      });
    });
  }

  @override
  void dispose() {
    _relayController.dispose();

    super.dispose();
  }

  SettingsThemeData? getTheme() {
    if (getIsDarkMode(context)) {
      return SettingsThemeData(
        settingsListBackground: platformThemeData(
          context,
          material: (data) => data.scaffoldBackgroundColor,
          cupertino: (data) => data.scaffoldBackgroundColor,
        ),
        settingsSectionBackground: platformThemeData(
          context,
          material: (data) => data.dialogBackgroundColor,
          cupertino: (data) => HSLColor.fromColor(data.barBackgroundColor)
              .withLightness(.2)
              .toColor(),
        ),
        titleTextColor: platformThemeData(
          context,
          material: (data) => data.textTheme.headlineLarge!.color,
          cupertino: (data) => data.textTheme.tabLabelTextStyle.color,
        ),
        settingsTileTextColor: platformThemeData(
          context,
          material: (data) => data.textTheme.bodyText2!.color,
          cupertino: (data) => data.textTheme.navTitleTextStyle.color,
        ),
      );
    }

    return null;
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
                physics: const NeverScrollableScrollPhysics(),
                lightTheme: getTheme(),
                darkTheme: getTheme(),
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
                      ),
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
                  ),
                  SettingsSection(
                    title: Text(l10n.settingsScreen_sections_misc),
                    tiles: [
                      SettingsTile.switchTile(
                        initialValue: settings.showHints,
                        onToggle: (newValue) {
                          settings.setShowHints(newValue);
                          settings.save();
                        },
                        title:
                            Text(l10n.settingsScreen_settings_showHints_label),
                        description: Text(
                            l10n.settingsScreen_settings_showHints_description),
                      ),
                    ],
                  ),
                  kDebugMode
                      ? SettingsSection(
                          title: Text("Debug"),
                          tiles: [
                            SettingsTile(
                              title: Text("Reset App"),
                              onPressed: (_) async {
                                storage.deleteAll();
                                await Workmanager().cancelAll();

                                exit(0);
                              },
                            )
                          ],
                        )
                      : null,
                ]
                    .where((element) => element != null)
                    .cast<SettingsSection>()
                    .toList(),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Padding(
                padding: const EdgeInsets.all(MEDIUM_SPACE),
                child: Paper(
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
                          leading: const Icon(Icons.code),
                          title: Text(l10n.support_options_develop),
                          subtitle:
                              Text(l10n.support_options_develop_description),
                          onTap: () {
                            launchUrl(
                              Uri.parse(REPOSITORY_URL),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                        PlatformListTile(
                          leading: const Icon(Icons.translate_rounded),
                          title: Text(l10n.support_options_translate),
                          subtitle:
                              Text(l10n.support_options_translate_description),
                          onTap: () {
                            launchUrl(
                              Uri.parse(TRANSLATION_HELP_URL),
                              mode: LaunchMode.externalApplication,
                            );
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
                          subtitle:
                              Text(l10n.support_options_donate_description),
                          onTap: () {
                            launchUrl(
                              Uri.parse(DONATION_URL),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(MEDIUM_SPACE),
                child: Paper(
                  child: Padding(
                    padding: const EdgeInsets.all(MEDIUM_SPACE),
                    child: Column(
                      children: <Widget>[
                        Text(
                          l10n.honorableMentions_title,
                          style: getTitle2TextStyle(context),
                        ),
                        const SizedBox(height: LARGE_SPACE),
                        Icon(
                          context.platformIcons.thumbUp,
                          color: Colors.green,
                          size: 60,
                        ),
                        const SizedBox(height: LARGE_SPACE),
                        Text(
                          l10n.honorableMentions_description,
                          style: getBodyTextTextStyle(context),
                        ),
                        const SizedBox(height: LARGE_SPACE),
                        MentionTile(
                          title: l10n.honorableMentions_values_findMyDevice,
                          description: l10n
                              .honorableMentions_values_findMyDevice_description,
                          iconName: "find-my-device.png",
                          url: "https://gitlab.com/Nulide/findmydevice",
                        ),
                        MentionTile(
                          title: l10n.honorableMentions_values_simpleQR,
                          description: l10n
                              .honorableMentions_values_simpleQR_description,
                          iconName: "simple-qr.png",
                          url: "https://github.com/tomfong/simple-qr",
                        ),
                        MentionTile(
                          title: l10n.honorableMentions_values_libreTube,
                          description: l10n
                              .honorableMentions_values_libreTube_description,
                          iconName: "libretube.png",
                          url: "https://libretube.net/",
                        ),
                        MentionTile(
                          title: l10n.honorableMentions_values_session,
                          description:
                              l10n.honorableMentions_values_session_description,
                          iconName: "session.png",
                          url: "https://getsession.org/",
                        ),
                        MentionTile(
                          title: l10n.honorableMentions_values_odysee,
                          description:
                              l10n.honorableMentions_values_odysee_description,
                          iconName: "odysee.png",
                          url: "https://odysee.com/",
                        ),
                        MentionTile(
                          title: l10n.honorableMentions_values_kleckRelay,
                          description: l10n
                              .honorableMentions_values_kleckRelay_description,
                          iconName: "kleckrelay.png",
                          url: "https://www.kleckrelay.com",
                        )
                      ],
                    ),
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
