import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/PlatformListTile.dart';

class MentionTile extends StatelessWidget {
  final String iconName;
  final String title;
  final String description;
  final String url;

  const MentionTile({
    required this.iconName,
    required this.title,
    required this.description,
    required this.url,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(999999),
        child: Image.asset(
          "assets/honorable-mentions/$iconName",
          width: 40,
          height: 40,
        ),
      ),
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      },
    );
  }
}
