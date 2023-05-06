import 'package:basic_utils/basic_utils.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../constants/spacing.dart';
import '../../services/view_service.dart';
import '../../utils/theme.dart';

class NameForm extends StatefulWidget {
  final void Function() onSubmitted;
  final TextEditingController controller;

  const NameForm({
    required this.onSubmitted,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  State<NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<NameForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewService = context.read<ViewService>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.mainScreen_importTask_action_name_title,
            style: getBodyTextTextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          PlatformTextFormField(
            controller: widget.controller,
            validator: (name) {
              if (name == null || name.isEmpty) {
                return l10n.fields_errors_isEmpty;
              }

              final lowerCasedName = name.toLowerCase();

              if (!StringUtils.isAscii(name)) {
                return l10n.fields_errors_invalidCharacters;
              }

              if (viewService.views.any((element) => element.name?.toLowerCase() == lowerCasedName)) {
                return l10n.mainScreen_importTask_action_name_errors_sameNameAlreadyExists;
              }

              return null;
            },
            material: (_, __) => MaterialTextFormFieldData(
              decoration: InputDecoration(
                labelText: l10n.mainScreen_importTask_action_name_label,
                icon: Icon(Icons.text_fields_rounded),
              ),
            ),
            cupertino: (_, __) => CupertinoTextFormFieldData(
              placeholder: l10n.mainScreen_importTask_action_name_label,
              prefix: const Icon(CupertinoIcons.textformat),
            ),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          PlatformElevatedButton(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            onPressed: () {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              widget.onSubmitted();
            },
            material: (_, __) => MaterialElevatedButtonData(
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
  }
}
