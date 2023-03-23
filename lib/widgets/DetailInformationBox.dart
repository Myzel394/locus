import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/Paper.dart';

class DetailInformationBox extends StatelessWidget {
  final String title;
  final Widget child;

  const DetailInformationBox({
    required this.title,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: MEDIUM_SPACE,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.start,
          style: getSubTitleTextStyle(context),
        ),
        Paper(
          child: child,
        ),
      ],
    );
  }
}
