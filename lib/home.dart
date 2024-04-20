import 'dart:async';

import 'package:bate_ponto/entities/dot.dart';
import 'package:bate_ponto/widgets/adaptive_dialog.dart';
import 'package:bate_ponto/widgets/load_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage(this.user, {super.key});

  final User user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _timer = TimerController();

  void _removeDot(Dot dot) async {
    final entry = getLoadOverlay(context);

    try {
      final result = await dot.delete();

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
                  onPressed: dot.register,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bate Ponto"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          ListenableBuilder(
            listenable: _timer,
            builder: (context, child) {
              return Text(
                DateFormat("kk:mm:ss").format(_timer.now),
                style: Theme.of(context).textTheme.displayLarge,
              );
            },
          ),
          const SizedBox(height: 15),
          Text(DateFormat.yMMMMEEEEd().format(_timer.now)),
          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.user.uid)
                  .collection("dots")
                  .orderBy("id", descending: true)
                  .withConverter<Dot>(
                      fromFirestore: Dot.fromFirestore,
                      toFirestore: (value, options) => value.toFirestore())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum ponto registrado"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 60),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final dotData = docs[index].data();
                    final previousDotData =
                        index - 1 >= 0 ? docs[index - 1].data() : null;
                    final showDate = previousDotData != null &&
                        dotData.ymdFormated != previousDotData.ymdFormated;

                    return DotTile(
                      dotData,
                      onDismissed: (dir) => _removeDot(dotData),
                      showDate: showDate,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            label: const Text("Manual"),
            icon: const Icon(Icons.add),
            onPressed: () {
              DateTime date = _timer.now;
              // TimeOfDay time = TimeOfDay.fromDateTime(_timer.now);
              showCustomAdaptiveDialog(
                context,
                title: "Bater Ponto",
                description: "",
                child: StatefulBuilder(builder: (context, stf) {
                  return Row(
                    children: [
                      Card(
                        child: InkWell(
                          onTap: () async {
                            final newDate = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );

                            if (newDate != null) {
                              stf(() {
                                date = newDate;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(11),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              DateFormat("yyyy/MM/dd").format(date),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Card(
                        child: InkWell(
                          onTap: () async {
                            final time = TimeOfDay.fromDateTime(date);

                            final newTime = await showTimePicker(
                              context: context,
                              initialTime: time,
                            );

                            if (newTime != null) {
                              stf(() {
                                date = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  newTime.hour,
                                  newTime.minute,
                                );
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(11),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              DateFormat("kk:mm").format(date),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                onConfirm: () async {
                  final entry = getLoadOverlay(context);
                  final dot = Dot(widget.user.uid, date);
                  try {
                    final result = await dot.register();

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
            },
          ),
          const SizedBox(height: 20),
          FloatingActionButton.extended(
            label: const Text("Automático"),
            icon: const Icon(Icons.add),
            onPressed: () {
              final dot = Dot(widget.user.uid, _timer.now);
              showCustomAdaptiveDialog(
                context,
                title: "Bater Ponto",
                description:
                    "Bater o ponto com a hora: ${dot.completeFormated}",
                onConfirm: () async {
                  final entry = getLoadOverlay(context);
                  try {
                    final result = await dot.register();

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
            },
          ),
        ],
      ),
    );
  }
}

class DotTile extends StatelessWidget {
  const DotTile(
    this.dot, {
    required this.onDismissed,
    this.showDate = false,
    super.key,
  });

  final Dot dot;

  final bool showDate;

  final Function(DismissDirection dir) onDismissed;

  @override
  Widget build(BuildContext context) {
    final tile = Dismissible(
      key: ValueKey(dot),
      onDismissed: onDismissed,
      child: ListTile(title: Text(dot.completeFormated)),
    );

    if (showDate) {
      return Column(
        children: [Text(dot.day), tile],
      );
    }

    return tile;
  }
}

class TimerController extends ChangeNotifier {
  DateTime now;

  final _second = const Duration(seconds: 1);

  TimerController() : now = DateTime.now() {
    _start();
  }

  Timer _start() => Timer.periodic(_second, (timer) {
        now = now.add(_second);
        notifyListeners();
      });
}
