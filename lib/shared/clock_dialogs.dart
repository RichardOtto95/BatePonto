import 'package:bate_ponto/shared/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void manualPunch(
    BuildContext context, Future<void> Function(DateTime date) onConfirm,
    [DateTime? date]) {
  date ??= DateTime.now();
  showCustomAdaptiveDialog(
    context,
    title: "Bater Ponto",
    description: "",
    child: StatefulBuilder(
      builder: (context, stf) {
        return Row(
          children: [
            PickDate(
              date: date!,
              onPick: (newDate) => stf(() => date = newDate),
            ),
            const Spacer(),
            PickTime(
              date: date!,
              onPick: (newDate) => stf(() => date = newDate),
            ),
          ],
        );
      },
    ),
    onConfirm: () async => await onConfirm(date!).then(
      (_) => Navigator.of(context).pop(),
    ),
  );
}

Future<String?> inputDialog(
  BuildContext context, {
  String title = "Título",
  String? description,
}) async {
  final formKey = GlobalKey<FormState>();
  String? text;
  await showCustomAdaptiveDialog<String>(
    context,
    title: title,
    description: description ?? "",
    child: Form(
      key: formKey,
      child: TextFormField(
        onChanged: (value) => text = value,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Este campo não pode ser vazio.";
          }
          return null;
        },
      ),
    ),
    onConfirm: () {
      if (formKey.currentState!.validate()) {
        Navigator.pop(context, text);
      }
    },
  );
  return text;
}

class PickDate extends StatelessWidget {
  const PickDate({
    super.key,
    required this.onPick,
    required this.date,
  });

  final DateTime date;
  final Function(DateTime newDate) onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          final newDate = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );

          if (newDate != null) {
            onPick(newDate);
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
    );
  }
}

class PickTime extends StatelessWidget {
  const PickTime({
    super.key,
    required this.date,
    required this.onPick,
  });

  final DateTime date;
  final Function(DateTime newDate) onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          final time = TimeOfDay.fromDateTime(date);

          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );

          if (newTime != null) {
            onPick(DateTime(
              date.year,
              date.month,
              date.day,
              newTime.hour,
              newTime.minute,
            ));
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
    );
  }
}
