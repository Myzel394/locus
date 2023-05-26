import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/LogDetailScreen.dart';
import 'package:locus/screens/log_detail_screen_widgets/LogCreatedAtInfo.dart';
import 'package:provider/provider.dart';

import '../models/log.dart';
import '../services/log_service.dart';
import '../widgets/Paper.dart';
import 'log_detail_screen_widgets/LogIcon.dart';

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
          itemBuilder: (context, final int index) {
            // Reverse
            final Log log = logService.logs[logService.logs.length - index - 1];
            return Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Hero(
                    tag: "${log.id}:paper",
                    child: Material(
                      color: Colors.transparent,
                      child: Paper(
                        roundness: 0,
                        child: Container(),
                      ),
                    ),
                  ),
                ),
                PlatformListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => LogDetailScreen(log: log),
                        fullscreenDialog: true,
                        maintainState: true,
                        allowSnapshotting: true,
                        barrierDismissible: true,
                        barrierColor: Colors.black.withOpacity(.3),
                        opaque: false,
                      ),
                    );
                  },
                  leading: Hero(
                    tag: "${log.id}:icon",
                    child: LogIcon(log: log),
                  ),
                  title: Hero(
                    tag: "${log.id}:title",
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        log.getTitle(context),
                      ),
                    ),
                  ),
                  subtitle: Hero(
                    tag: "${log.id}:info",
                    child: Material(
                      color: Colors.transparent,
                      child: LogCreatedInfo(log: log),
                    ),
                  ),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
