import 'package:enough_platform_widgets/enough_platform_widgets.dart'
    hide PlatformPopupMenuItem;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/PlatformPopup.dart';
import 'package:provider/provider.dart';

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
      title: view.name == null
          ? Text(
              l10n.unnamedView,
              style: TextStyle(fontFamily: "Cursive"),
            )
          : Text(view.name!),
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
                    title:
                        Text(l10n.viewAction_delete_confirm_title(view.name!)),
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
                }
              }),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ViewDetailScreen(
              view: view,
            ),
          ),
        );
      },
    );
  }
}
