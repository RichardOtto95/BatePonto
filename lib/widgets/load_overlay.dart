import 'package:flutter/material.dart';

OverlayEntry getLoadOverlay(BuildContext context) {
  final entry = OverlayEntry(builder: (context) => const LoadOverlay());
  Overlay.of(context).insert(entry);
  return entry;
}

class LoadOverlay extends StatelessWidget {
  const LoadOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.black.withOpacity(.3),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}
