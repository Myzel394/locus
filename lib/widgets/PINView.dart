import 'package:flutter/cupertino.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/Paper.dart';

class PINView extends StatelessWidget {
  final int pin;

  const PINView({
    required this.pin,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      spacing: SMALL_SPACE,
      children: pin
          .toString()
          .split("")
          .map(
            (digit) => Paper(
              width: null,
              child: Text(
                digit,
                style: getTitle2TextStyle(context),
              ),
            ),
          )
          .toList(),
    );
  }
}
