import 'package:flutter/material.dart';
import 'package:locus/services/settings_service/index.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UpdateLocaleToSettings extends StatefulWidget {
  const UpdateLocaleToSettings({super.key});

  @override
  State<UpdateLocaleToSettings> createState() => _UpdateLocaleToSettingsState();
}

class _UpdateLocaleToSettingsState extends State<UpdateLocaleToSettings> {
  late final SettingsService _settings;

  @override
  void initState() {
    super.initState();

    _settings = context.read<SettingsService>();
    _settings.addListener(_updateLocale);
  }

  @override
  void dispose() {
    _settings.removeListener(_updateLocale);
    super.dispose();
  }

  void _updateLocale() async {
    _settings.localeName = AppLocalizations
        .of(context)
        .localeName;

    await _settings.save();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
