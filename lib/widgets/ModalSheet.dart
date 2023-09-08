import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import '../constants/spacing.dart';
import 'package:locus/services/settings_service/index.dart';

class ModalSheet extends StatefulWidget {
  final Widget child;
  final bool miuiIsGapless;
  final EdgeInsets cupertinoPadding;
  final EdgeInsets? materialPadding;
  final DraggableScrollableController? sheetController;

  const ModalSheet({
    Key? key,
    required this.child,
    this.sheetController,
    this.miuiIsGapless = false,
    this.materialPadding,
    this.cupertinoPadding = const EdgeInsets.symmetric(
      vertical: LARGE_SPACE,
      horizontal: MEDIUM_SPACE,
    ),
  }) : super(key: key);

  @override
  State<ModalSheet> createState() => _ModalSheetState();
}

class _ModalSheetState extends State<ModalSheet> {
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();

    if (widget.sheetController != null) {
      widget.sheetController!.addListener(_scrollListener);
    }
  }

  void _scrollListener() {
    setState(() {
      isExpanded = widget.sheetController!.size == 1.0;
    });
  }

  @override
  void dispose() {
    if (widget.sheetController != null) {
      widget.sheetController!.removeListener(_scrollListener);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: PlatformWidget(
        material: (_, __) => Padding(
          padding: settings.isMIUI() && !widget.miuiIsGapless
              ? const EdgeInsets.all(MEDIUM_SPACE)
              : EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            decoration: BoxDecoration(
              color: getSheetColor(context),
              borderRadius: isExpanded
                  ? BorderRadius.zero
                  : settings.isMIUI() && !widget.miuiIsGapless
                      ? const BorderRadius.all(Radius.circular(LARGE_SPACE))
                      : const BorderRadius.only(
                          topLeft: Radius.circular(LARGE_SPACE),
                          topRight: Radius.circular(LARGE_SPACE),
                        ),
            ),
            child: Padding(
              padding: widget.materialPadding ??
                  EdgeInsets.only(
                    top: settings.isMIUI() && !widget.miuiIsGapless
                        ? MEDIUM_SPACE
                        : LARGE_SPACE,
                    left: MEDIUM_SPACE,
                    right: MEDIUM_SPACE,
                    bottom: SMALL_SPACE,
                  ),
              child: widget.child,
            ),
          ),
        ),
        cupertino: (_, __) => CupertinoPopupSurface(
          isSurfacePainted: true,
          child: Padding(
            padding: widget.cupertinoPadding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
