import 'package:flutter/cupertino.dart';

VoidCallback Function(BuildContext context) withPopNavigation(
    VoidCallback callback) {
  return (BuildContext context) {
    return () {
      Navigator.of(context).pop();
      callback();
    };
  };
}
