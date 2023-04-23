import 'package:basic_utils/basic_utils.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    final viewService = context.read<ViewService>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            "Enter a name for this task",
            style: getBodyTextTextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          PlatformTextFormField(
            controller: widget.controller,
            validator: (name) {
              if (name == null || name.isEmpty) {
                return "Please enter a name.";
              }

              final lowerCasedName = name.toLowerCase();

              if (!StringUtils.isAscii(name)) {
                return "Name contains invalid characters.";
              }

              if (viewService.views.any((element) => element.name?.toLowerCase() == lowerCasedName)) {
                return "A view with this name already exists.";
              }

              return null;
            },
            material: (_, __) => MaterialTextFormFieldData(
              decoration: const InputDecoration(
                labelText: "Name",
                icon: Icon(Icons.text_fields_rounded),
              ),
            ),
            cupertino: (_, __) => CupertinoTextFormFieldData(
              placeholder: "Name",
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
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}
