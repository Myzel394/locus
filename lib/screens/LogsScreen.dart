import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/LogDetailScreen.dart';
import 'package:locus/screens/log_detail_screen_widgets/LogCreatedAtInfo.dart';
import 'package:locus/screens/log_detail_screen_widgets/LogTypeInfo.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/MaybeMaterial.dart';
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

class _LogsScreenState extends State<LogsScreen> with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final l10n = AppLocalizations.of(context);
    final logService = context.watch<LogService>();

    return PlatformScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MEDIUM_SPACE,
                  vertical: LARGE_SPACE,
                ),
                child: Paper(
                  child: Padding(
                    padding: const EdgeInsets.all(MEDIUM_SPACE),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          context.platformIcons.info,
                          size: 38,
                        ),
                        const SizedBox(height: MEDIUM_SPACE),
                        Text(
                          l10n.logs_title,
                          style: getTitle2TextStyle(context),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: MEDIUM_SPACE),
                        Text(
                          l10n.logs_description,
                          style: getBodyTextTextStyle(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ListView.builder(
                itemCount: logService.logs.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, final int index) {
                  // Reverse
                  final Log log =
                  logService.logs[logService.logs.length - index - 1];
                  return Stack(
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Hero(
                          tag: "${log.id}:paper",
                          child: Paper(
                            roundness: 0,
                            child: Container(),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  LogDetailScreen(log: log),
                              fullscreenDialog: true,
                              barrierColor: Colors.black.withOpacity(.3),
                              opaque: false,
                              barrierDismissible: true,
                              reverseTransitionDuration: const Duration(
                                milliseconds: 100,
                              ),
                              transitionDuration: const Duration(
                                milliseconds: 500,
                              ),
                              maintainState: true,
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },

                        child: PlatformListTile(
                          leading: Hero(
                            tag: "${log.id}:icon",
                            child: LogIcon(log: log),
                          ),
                          title: Hero(
                            tag: "${log.id}:title",
                            child: MaybeMaterial(
                              color: Colors.transparent,
                              child: Text(
                                log.getTitle(context),
                              ),
                            ),
                          ),
                          subtitle: Row(
                            children: <Widget>[
                              Hero(
                                tag: "${log.id}:type",
                                child: MaybeMaterial(
                                  color: Colors.transparent,
                                  child: LogTypeInfo(log: log),
                                ),
                              ),
                              const SizedBox(width: SMALL_SPACE),
                              Hero(
                                tag: "${log.id}:createdAt",
                                child: MaybeMaterial(
                                  color: Colors.transparent,
                                  child: LogCreatedInfo(log: log),
                                ),
                              ),
                            ],
                          ),
                          trailing: log.initiator == LogInitiator.system
                              ? Hero(
                            tag: "${log.id}:initiator",
                            child: PlatformWidget(
                              material: (_, __) =>
                              const Icon(
                                Icons.laptop,
                              ),
                              cupertino: (_, __) =>
                              const Icon(
                                CupertinoIcons.bolt,
                              ),
                            ),
                          )
                              : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
