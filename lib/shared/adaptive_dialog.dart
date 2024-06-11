import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget adaptiveAction(
    {required BuildContext context,
    required VoidCallback onPressed,
    required Widget child}) {
  final ThemeData theme = Theme.of(context);
  switch (theme.platform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return TextButton(onPressed: onPressed, child: child);
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CupertinoDialogAction(onPressed: onPressed, child: child);
  }
}

showCustomAdaptiveDialog<T>(
  context, {
  required String title,
  required String description,
  Widget? child,
  Function()? onConfirm,
}) async =>
    await showAdaptiveDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog.adaptive(
        title: Text(title),
        content: child ?? Text(description),
        actions: <Widget>[
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          adaptiveAction(
            context: context,
            onPressed: onConfirm ?? () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
