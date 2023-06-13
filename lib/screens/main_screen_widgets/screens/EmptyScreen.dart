import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../CreateTask.dart';
import '../ImportTask.dart';

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final windowHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: windowHeight,
              child: const Center(
                child: CreateTask(),
              ),
            ),
            SizedBox(
              height: windowHeight,
              child: const Center(
                child: ImportTask(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
