import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (isCupertino(context)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SMALL_SPACE),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999999),
              child: Image.asset(
                "assets/honorable-mentions/$iconName",
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: SMALL_SPACE),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: getBodyTextTextStyle(context),
                  ),
                  const SizedBox(height: TINY_SPACE),
                  Text(
                    description,
                    style: getCaptionTextStyle(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListTile(
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
