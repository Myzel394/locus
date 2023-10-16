import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/theme.dart';

class TaskChangeNameDialog extends StatefulWidget {
  final String initialName;
  final Function(String) onNameChanged;

  const TaskChangeNameDialog({
    required this.initialName,
    required this.onNameChanged,
    super.key,
  });

  @override
  State<TaskChangeNameDialog> createState() => _TaskChangeNameDialogState();
}

class _TaskChangeNameDialogState extends State<TaskChangeNameDialog> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final nameFocusNode = FocusNode();

  late bool showClearButton;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.initialName;
    nameController.addListener(() {
      setState(() {
        showClearButton = nameController.text.isNotEmpty;
      });
    });
    showClearButton = nameController.text.isNotEmpty;
  }

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformAlertDialog(
      material: (_, __) => MaterialAlertDialogData(
        icon: const Icon(Icons.edit_rounded),
      ),
      title: Text(l10n.taskAction_changeName),
      actions: createCancellableDialogActions(
        context,
        [
          PlatformDialogAction(
            child: Text(l10n.closeSaveAction),
            cupertino: (_, __) => CupertinoDialogActionData(
              isDefaultAction: true,
            ),
            material: (_, __) => MaterialDialogActionData(
              icon: const Icon(Icons.check_rounded),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                widget.onNameChanged(nameController.text);
              }
            },
          )
        ],
      ),
      content: Form(
        key: formKey,
        child: PlatformTextFormField(
          autofillHints: const [AutofillHints.name],
          controller: nameController,
          autofocus: true,
          focusNode: nameFocusNode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.fields_errors_isEmpty;
            }

            if (!StringUtils.isAscii(value)) {
              return l10n.fields_errors_invalidCharacters;
            }

            return null;
          },
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.name,
          maxLines: 1,
          material: (_, __) => MaterialTextFormFieldData(
            decoration: InputDecoration(
              filled: false,
              labelText: l10n.taskAction_changeName_field_label,
              suffixIcon: showClearButton
                  ? IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        nameController.clear();
                        nameFocusNode.requestFocus();
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
