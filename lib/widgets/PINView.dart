import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final middleIndex = pin.toString().length ~/ 2;

    return Wrap(
      direction: Axis.horizontal,
      spacing: SMALL_SPACE,
      children: pin
          .toString()
          .split("")
          .mapIndexed(
            (index, digit) => Paper(
              width: null,
              child: Text(
                digit,
                style: getTitle2TextStyle(context),
              ),
            )
                .animate()
                .then(delay: Duration(milliseconds: (index - middleIndex).abs() * 400))
                .moveX(
                  begin: (index - middleIndex) * 10,
                  end: 0,
                  duration: 800.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(
                  duration: 800.ms,
                ),
          )
          .toList(),
    );
  }
}
