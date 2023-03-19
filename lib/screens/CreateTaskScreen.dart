import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();

  bool _isCreatingTask = false;

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();

    super.dispose();
  }

  Future<void> createTask() async {
    setState(() {
      _isCreatingTask = true;
    });

    try {
      final task = await Task.create(
        _nameController.text,
        Duration(minutes: int.parse(_frequencyController.text)),
      );

      final taskService = await TaskService.restore();

      taskService.tasks.add(task);

      await taskService.save();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
    } finally {
      setState(() {
        _isCreatingTask = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text("Create Task"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              if (!isKeyboardVisible)
                Column(
                  children: <Widget>[
                    Text(
                      "Create Task",
                      style: getTitleTextStyle(context),
                    ),
                    const SizedBox(height: SMALL_SPACE),
                    Text(
                      "Define a name and a frequency for your task",
                      style: getBodyTextTextStyle(context),
                    ),
                    const SizedBox(height: SMALL_SPACE),
                    Text(
                      "Note that a frequency of less than 15 minutes will automatically be set to 15 minutes. This is not set by us, but by the operating system.",
                      style: getCaptionTextStyle(context),
                    ),
                  ],
                ),
              const Spacer(),
              Column(
                children: <Widget>[
                  PlatformTextField(
                    controller: _nameController,
                    enabled: _isCreatingTask == false,
                    textInputAction: TextInputAction.next,
                    material: (_, __) => MaterialTextFieldData(
                      decoration: InputDecoration(
                        labelText: "Name",
                        prefixIcon: Icon(context.platformIcons.tag),
                      ),
                    ),
                    cupertino: (_, __) => CupertinoTextFieldData(
                      placeholder: "Name",
                      prefix: Icon(context.platformIcons.tag),
                    ),
                  ),
                  const SizedBox(height: MEDIUM_SPACE),
                  PlatformTextField(
                    controller: _frequencyController,
                    enabled: _isCreatingTask == false,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    material: (_, __) => MaterialTextFieldData(
                      decoration: InputDecoration(
                        prefixIcon: Icon(context.platformIcons.time),
                        labelText: "Frequency",
                        prefixText: "Every",
                        suffix: Text("Minutes"),
                      ),
                    ),
                    cupertino: (_, __) => CupertinoTextFieldData(
                      placeholder: "Frequency",
                      prefix: Text("Every"),
                      suffix: Text("Minutes"),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PlatformElevatedButton(
                child: Text("Create"),
                onPressed: _isCreatingTask == true ? null : createTask,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
