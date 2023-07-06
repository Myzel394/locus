import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import '../../widgets/ModalSheet.dart';

const MIN_SIZE = 0.15;

class ActiveSharesSheet extends StatefulWidget {
  final double triggerThreshold;
  final VoidCallback onThresholdReached;
  final VoidCallback onThresholdPassed;
  final bool visible;

  const ActiveSharesSheet({
    required this.visible,
    required this.triggerThreshold,
    required this.onThresholdReached,
    required this.onThresholdPassed,
    super.key,
  });

  @override
  State<ActiveSharesSheet> createState() => _ActiveSharesSheetState();
}

class _ActiveSharesSheetState extends State<ActiveSharesSheet>
    with TickerProviderStateMixin {
  final wrapperKey = GlobalKey();
  final textKey = GlobalKey();
  final sheetController = DraggableScrollableController();
  late final AnimationController offsetController;
  late Animation<Offset> offsetProgress;

  bool isInitializing = true;

  bool _hasCalledThreshold = false;
  bool _hasCalledPassed = false;

  @override
  void initState() {
    super.initState();

    offsetController =
        AnimationController(vsync: this, duration: Duration.zero);
    // Dummy animation so first render can occur without any problems
    offsetProgress =
        Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 0))
            .animate(offsetController);

    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final wrapperWidth = wrapperKey.currentContext!.size!.width;
      final textWidth = textKey.currentContext!.size!.width;
      final xOffset = (wrapperWidth - textWidth) / 2;

      offsetProgress = Tween<Offset>(
        begin: Offset(-xOffset, 0),
        end: const Offset(0, 0),
      ).animate(offsetController);

      isInitializing = false;
    });

    sheetController.addListener(() {
      final progress = (sheetController.size - MIN_SIZE) / (1 - MIN_SIZE);

      offsetController.animateTo(
        progress,
        duration: Duration.zero,
      );

      final isThresholdReached = progress >= widget.triggerThreshold;

      if (isThresholdReached && !_hasCalledThreshold) {
        _hasCalledThreshold = true;
        widget.onThresholdReached();
      } else if (!isThresholdReached) {
        _hasCalledThreshold = false;
      }

      if (!isThresholdReached && !_hasCalledPassed) {
        _hasCalledPassed = true;
        widget.onThresholdPassed();
      } else if (isThresholdReached) {
        _hasCalledPassed = false;
      }
    });
  }

  @override
  void dispose() {
    sheetController.dispose();
    offsetController.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ActiveSharesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        sheetController.animateTo(
          MIN_SIZE,
          duration: const Duration(milliseconds: 500),
          curve: Curves.linearToEaseOut,
        );
      } else {
        sheetController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isInitializing ? 0 : 1,
      child: AnimatedBuilder(
        animation: offsetProgress,
        builder: (context, child) => Transform.translate(
          offset: offsetProgress.value,
          child: child,
        ),
        child: DraggableScrollableSheet(
          snap: true,
          snapSizes: const [0.15, 1],
          minChildSize: 0.0,
          initialChildSize: 0.15,
          controller: sheetController,
          builder: (context, controller) => ModalSheet(
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                key: wrapperKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "5 Shares active",
                    key: textKey,
                    style: getTitle2TextStyle(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
