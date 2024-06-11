import 'package:bate_ponto/models/clock_model.dart';
import 'package:bate_ponto/models/environment_model.dart';
import 'package:bate_ponto/shared/clock_dialogs.dart';
import 'package:bate_ponto/view_models/clock_view_model.dart';
import 'package:bate_ponto/view_models/timer_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _timer = TimerViewModel();

  final viewModel = ClockViewModel();

  @override
  void initState() {
    viewModel.getEnvironments(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bate Ponto"),
        actions: [
          ValueListenableBuilder<List<Environment>?>(
            valueListenable: viewModel.environments,
            builder: (context, environments, child) {
              return PopupMenuButton(
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      onTap: environments == null
                          ? null
                          : () => viewModel.createEnvironment(context),
                      enabled: environments != null,
                      child: ListTile(
                        enabled: environments != null,
                        title: const Text("Criar Ambiente"),
                        leading: const Icon(Icons.domain_add_rounded),
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => viewModel.signOut(context),
                      child: const ListTile(
                        title: Text("Logout"),
                        leading: Icon(Icons.logout_rounded),
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
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
            child: ValueListenableBuilder<List<Environment>?>(
              valueListenable: viewModel.environments,
              builder: (context, environments, child) {
                if (environments == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (environments.isEmpty) {
                  return const Center(
                      child: Text("Nenhum ambiente cadastrado."));
                }

                return StatefulBuilder(
                  builder: (context, stf) {
                    return Column(
                      children: [
                        DefaultTabController(
                          length: environments.length,
                          child: TabBar(
                            onTap: (value) =>
                                viewModel.environmentIndex.value = value,
                            tabs: [
                              for (final environment in environments)
                                Tab(text: environment.title),
                            ],
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                );
              },
              child: Flexible(
                child: ValueListenableBuilder<int>(
                  valueListenable: viewModel.environmentIndex,
                  builder: (context, index, child) {
                    final env = viewModel.environments.value![index];
                    return StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(viewModel.user.uid)
                          .collection("environments")
                          .doc(env.id)
                          .collection("clocks")
                          .orderBy("id", descending: true)
                          .withConverter<Clock>(
                            fromFirestore: Clock.fromFirestore,
                            toFirestore: (value, options) =>
                                value.toFirestore(),
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("Nenhum ponto registrado"));
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 15),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final clockData = docs[index].data();
                            final previousClockData =
                                index - 1 >= 0 ? docs[index - 1].data() : null;
                            final showDate = (previousClockData != null &&
                                    clockData.ymdFormated !=
                                        previousClockData.ymdFormated) ||
                                index == 0;

                            return ClockTile(
                              clockData,
                              onDismissed: (dir) => viewModel.removeClock(
                                context,
                                clockData,
                              ),
                              showDate: showDate,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            isExtended: true,
            label: const Text("Manual"),
            icon: const Icon(Icons.add),
            onPressed: () => viewModel.manualPunchDialog(context),
          ),
          const SizedBox(height: 20),
          FloatingActionButton.extended(
            label: const Text("Automático"),
            icon: const Icon(Icons.add),
            onPressed: () => viewModel.autoPunchDialog(context),
          ),
        ],
      ),
    );
  }
}

class ClockTile extends StatelessWidget {
  const ClockTile(
    this.clock, {
    required this.onDismissed,
    this.showDate = false,
    super.key,
  });

  final Clock clock;

  final bool showDate;

  final Function(DismissDirection dir) onDismissed;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge;
    final shape = StadiumBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.primary),
    );
    final tile = Dismissible(
      key: ValueKey(clock),
      onDismissed: onDismissed,
      child: ListTile(
        dense: true,
        onTap: () => manualPunch(
          context,
          (date) => clock.punchEnd(date),
          clock.end,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Card(
              shape: shape,
              child: Container(
                width: 70,
                height: 40,
                alignment: Alignment.center,
                child: Text(clock.bHour, style: bodyStyle),
              ),
            ),
            Icon(
              Icons.remove_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            Card(
              shape: shape,
              child: Container(
                width: 70,
                height: 40,
                alignment: Alignment.center,
                child: Text(clock.eHour, style: bodyStyle),
              ),
            ),
            Icon(
              Icons.arrow_right_alt_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            Card(
              shape: shape,
              child: Container(
                width: 70,
                height: 40,
                alignment: Alignment.center,
                child: Text(clock.diffenrenceText(), style: bodyStyle),
              ),
            ),
          ],
        ),
      ),
    );

    if (showDate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              clock.day,
              style: titleStyle,
            ),
          ),
          tile,
        ],
      );
    }

    return tile;
  }
}
