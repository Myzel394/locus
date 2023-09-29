import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import 'view.dart';
import 'constants.dart';

class ViewServiceLinkParameters {
  final SecretKey password;
  final String nostrPublicKey;
  final String nostrMessageID;
  final List<String> relays;

  const ViewServiceLinkParameters({
    required this.password,
    required this.nostrPublicKey,
    required this.nostrMessageID,
    required this.relays,
  });
}

class ViewService extends ChangeNotifier {
  final List<TaskView> _views;

  ViewService({
    required List<TaskView> views,
  }) : _views = views;

  UnmodifiableListView<TaskView> get views => UnmodifiableListView(_views);

  UnmodifiableListView<TaskView> get viewsWithAlarms =>
      UnmodifiableListView(_views.where((view) => view.alarms.isNotEmpty));

  TaskView getViewById(final String id) =>
      _views.firstWhere((view) => view.id == id);

  static Future<ViewService> restore() async {
    final rawViews = await storage.read(key: KEY);

    if (rawViews == null) {
      return ViewService(
        views: [],
      );
    }

    return ViewService(
      views: List<TaskView>.from(
        List<Map<String, dynamic>>.from(
          jsonDecode(rawViews),
        ).map(
          TaskView.fromJSON,
        ),
      ).toList(),
    );
  }

  Future<void> save() async {
    final data = jsonEncode(
      List<Map<String, dynamic>>.from(
        await Future.wait(
          _views.map(
            (view) => view.toJSON(),
          ),
        ),
      ),
    );

    await storage.write(key: KEY, value: data);
  }

  void add(final TaskView view) {
    _views.add(view);

    notifyListeners();
  }

  void remove(final TaskView view) {
    _views.remove(view);

    notifyListeners();
  }

  Future<void> update(final TaskView view) async {
    final index = _views.indexWhere((element) => element.id == view.id);

    _views[index] = view;

    notifyListeners();
    await save();
  }
}
