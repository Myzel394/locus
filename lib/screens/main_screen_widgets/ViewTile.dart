import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/services/view_service.dart';
import 'package:locus/utils/theme.dart';
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
    final viewService = context.read<ViewService>();

    return PlatformListTile(
      title: view.name == null
          ? Text(
        "Unnamed",
        style: TextStyle(fontFamily: "Cursive"),
      )
          : Text(view.name!),
      trailing: PlatformPopupMenuButton<String>(
        itemBuilder: (context) =>
        [
          PlatformPopupMenuItem<String>(
            child: PlatformListTile(
              leading: Icon(context.platformIcons.delete),
              title: Text("Delete"),
            ),
            value: "delete",
          ),
        ],
        onSelected: (value) async {
          switch (value) {
            case "delete":
              final confirmDeletion = await showPlatformDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) =>
                    PlatformAlertDialog(
                      title: Text(
                        "Are you sure you want to delete ${view.getUIName(
                            context)}?",
                      ),
                      content: Text(
                        "This action cannot be undone.",
                      ),
                      actions: createCancellableDialogActions(
                        context,
                        [
                          PlatformDialogAction(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            material: (_, __) =>
                                MaterialDialogActionData(
                                  icon: Icon(context.platformIcons.delete),
                                ),
                            cupertino: (_, __) =>
                                CupertinoDialogActionData(
                                  isDestructiveAction: true,
                                ),
                            child: Text("Delete"),
                          ),
                        ],
                      ),
                    ),
              );

              if (confirmDeletion) {
                viewService.remove(view);
              }
          }
        },
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ViewDetailScreen(
                  view: view,
                ),
          ),
        );
      },
    );
  }
}
