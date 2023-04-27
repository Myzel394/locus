import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:locus/services/view_service.dart';

import '../ViewDetailScreen.dart';

class ViewTile extends StatelessWidget {
  final TaskView view;

  const ViewTile({
    required this.view,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformListTile(
      title: view.name == null
          ? Text(
              "Unnamed",
              style: TextStyle(fontFamily: "Cursive"),
            )
          : Text(view.name!),
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
