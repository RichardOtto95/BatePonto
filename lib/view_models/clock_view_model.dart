import 'package:bate_ponto/models/clock_model.dart';
import 'package:bate_ponto/models/environment_model.dart';
import 'package:bate_ponto/shared/adaptive_dialog.dart';
import 'package:bate_ponto/shared/clock_dialogs.dart';
import 'package:bate_ponto/shared/load_overlay.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClockViewModel extends ChangeNotifier {
  late final User user;

  final environments = ValueNotifier<List<Environment>?>(null);

  final environmentIndex = ValueNotifier<int>(0);

  ClockViewModel() : user = FirebaseAuth.instance.currentUser!;

  Future<void> getEnvironments(BuildContext context) async {
    try {
      environments.value = await Environment.getEnvironments(user.uid);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error on getEnvironments: $e")),
      );
    }
  }

  Future<void> createEnvironment(BuildContext context) async {
    String? title = await inputDialog(context);
    if (title != null) {
      try {
        final env = Environment(title);
        await env.setUp();
        environments.value = [...environments.value!, env];
      } catch (e) {
        if (context.mounted) {
          errorMessage(context, "Error on createEnvironment: $e");
        }
      }
    }
  }

  void signOut(BuildContext context) {
    showCustomAdaptiveDialog(
      context,
      title: "Sign Out",
      description: "Are you sure that wish sign out?",
      onConfirm: () async {
        FirebaseAuth.instance.signOut();
        Navigator.of(context).pop();
      },
    );
  }

  void removeClock(BuildContext context, Clock clock) async {
    final entry = getLoadOverlay(context);

    try {
      final result = await clock.delete();
      if (!context.mounted) {
        entry.remove();
        return;
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(result),
          action: result.contains("successfully")
              ? SnackBarAction(
                  label: 'Undo',
                  onPressed: clock.punch,
                )
              : null,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    entry.remove();
  }

  void manualPunchDialog(BuildContext context) async {
    // final userDocs =
    //     await FirebaseFirestore.instance.collection("users").get();
    // for (final userDoc in userDocs.docs) {
    //   final userRef = FirebaseFirestore.instance
    //       .collection("users")
    //       .doc(userDoc.id);
    //   final dots = await userRef.collection("dots").get();
    //   final environmentRef = userRef.collection("environments").doc();
    //   await environmentRef.set({
    //     "created_at": FieldValue.serverTimestamp(),
    //     "id": environmentRef.id,
    //     "time_amount": 0,
    //     "title": "Trabalho",
    //   });
    //   final clocksRef = environmentRef.collection("clocks");
    //   for (final dot in dots.docs) {
    //     await dot.reference.update({
    //       "end": null,
    //       "updated_at": FieldValue.serverTimestamp()
    //     });
    //     final dotData = dot.data();
    //     dotData["end"] = null;
    //     dotData["updated_at"] = FieldValue.serverTimestamp();
    //     final clockRef = clocksRef.doc(dot.id);
    //     clockRef.set(dotData);
    //   }
    // }

    manualPunch(
      context,
      (date) async {
        final entry = getLoadOverlay(context);
        try {
          final clock = Clock(
            user.uid,
            environments.value![environmentIndex.value].id!,
            date,
          );
          final result = await clock.punch();
          if (!context.mounted) {
            entry.remove();
            return;
          }
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
        entry.remove();
      },
    );
  }

  autoPunchDialog(BuildContext context) {
    final clock = Clock(
      user.uid,
      environments.value![environmentIndex.value].id!,
    );
    showCustomAdaptiveDialog(
      context,
      title: "Bater Ponto",
      description: "Bater o ponto com a hora: ${clock.bCompleteFormated}",
      onConfirm: () async {
        final entry = getLoadOverlay(context);
        try {
          final result = await clock.punch();

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
        Navigator.pop(context);
        entry.remove();
      },
    );
  }

  errorMessage(BuildContext context, e) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error on getEnvironments: $e")),
    );
  }
}
