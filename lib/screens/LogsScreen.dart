import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/LogDetailScreen.dart';
import 'package:locus/screens/log_detail_screen_widgets/LogCreatedAtInfo.dart';
import 'package:provider/provider.dart';

import '../models/log.dart';
import '../services/log_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logService = context.watch<LogService>();

    return PlatformScaffold(
      body: SafeArea(
        child: ListView.builder(
          itemCount: logService.logs.length,
          shrinkWrap: true,
          itemBuilder: (context, final int index) {
            // Reverse
            final Log log = logService.logs[logService.logs.length - index - 1];
            return PlatformListTile(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => LogDetailScreen(log: log),
                ));
              },
              title: Hero(
                tag: "title",
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    log.getTitle(context),
                  ),
                ),
              ),
              subtitle: LogCreatedInfo(log: log),
              trailing: log.initiator == LogInitiator.system
                  ? PlatformWidget(
                      material: (_, __) => const Icon(
                        Icons.laptop,
                      ),
                      cupertino: (_, __) => const Icon(
                        CupertinoIcons.bolt,
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
