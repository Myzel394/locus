import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:locus/constants/spacing.dart';

dynamic defaultExtractor(dynamic element) => element;

class BottomSheetFilterBuilder<T> extends StatefulWidget {
  final List<T> elements;
  final Widget Function(BuildContext, List<T>) builder;
  final String Function(T) extractValue;

  final TextEditingController? searchController;
  final bool sortingFilters;
  final int maxLevenshteinDistance;

  final ValueChanged<bool>? onSearchFocusChanged;

  const BottomSheetFilterBuilder({
    required this.elements,
    required this.builder,
    required this.extractValue,
    this.onSearchFocusChanged,
    this.searchController,
    this.sortingFilters = true,
    this.maxLevenshteinDistance = 4,
    Key? key,
  }) : super(key: key);

  @override
  State<BottomSheetFilterBuilder> createState() => _BottomSheetFilterBuilderState<T>();
}

class _BottomSheetFilterBuilderState<T> extends State<BottomSheetFilterBuilder> {
  List<T> _elements = [];

  @override
  void initState() {
    super.initState();

    _elements = widget.elements as List<T>;
  }

  void updateElements() {
    setState(() {
      _elements = _getFilteredElements();
    });
  }

  List<T> _getFilteredElements() {
    if (widget.searchController == null) {
      return widget.elements as List<T>;
    }

    final searchValue = widget.searchController!.text.toLowerCase();

    final result = List<T>.empty(growable: true);

    for (final element in widget.elements) {
      final value = widget.extractValue(element).toLowerCase();

      if (value.contains(searchValue)) {
        result.add(element);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: <Widget>[
        Focus(
          onFocusChange: widget.onSearchFocusChanged,
          child: PlatformWidget(
            material: (_, __) => TextField(
              controller: widget.searchController,
              onChanged: (value) {
                updateElements();
              },
              decoration: InputDecoration(
                hintText: l10n.searchLabel,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.searchController!.clear();
                    updateElements();
                  },
                ),
              ),
            ),
            cupertino: (_, __) => CupertinoSearchTextField(
              controller: widget.searchController,
              onChanged: (value) {
                updateElements();
              },
              placeholder: l10n.searchLabel,
            ),
          ),
        ),
        const SizedBox(height: SMALL_SPACE),
        Expanded(
          child: widget.builder(
            context,
            _elements,
          ),
        ),
      ],
    );
  }
}
