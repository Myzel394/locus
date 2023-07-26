import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/PageRoute.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/PlatformPopup.dart';
import 'package:provider/provider.dart';

import '../../widgets/PlatformListTile.dart';
import '../ViewDetailScreen.dart';

class ViewTile extends StatelessWidget {
  final TaskView view;

  const ViewTile({
    required this.view,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewService = context.read<ViewService>();

    return PlatformListTile(
      title: Text(view.name!),
      trailing: PlatformPopup<String>(
        type: PlatformPopupType.tap,
        items: [
          PlatformPopupMenuItem(
            label: PlatformListTile(
              leading: Icon(context.platformIcons.delete),
              title: Text(l10n.viewAction_delete),
            ),
            onPressed: () async {
              final confirmDeletion = await showPlatformDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => PlatformAlertDialog(
                  material: (_, __) => MaterialAlertDialogData(
                    icon: Icon(context.platformIcons.delete),
                  ),
                  title: Text(l10n.viewAction_delete_confirm_title(view.name)),
                  content: Text(l10n.actionNotUndoable),
                  actions: createCancellableDialogActions(
                    context,
                    [
                      PlatformDialogAction(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        material: (_, __) => MaterialDialogActionData(
                          icon: Icon(context.platformIcons.delete),
                        ),
                        cupertino: (_, __) => CupertinoDialogActionData(
                          isDestructiveAction: true,
                        ),
                        child: Text(l10n.deleteLabel),
                      ),
                    ],
                  ),
                ),
              );

              if (confirmDeletion) {
                viewService.remove(view);
                viewService.save();
              }
            },
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          NativePageRoute(
            context: context,
            builder: (context) => ViewDetailScreen(
              view: view,
            ),
          ),
        );
      },
    );
  }
}
