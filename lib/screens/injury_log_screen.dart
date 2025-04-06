import 'package:flutter/material.dart';

class InjuryLogScreen extends StatelessWidget {
  const InjuryLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Injury Log & Reports")),
      body: const Center(
        child: Text("Display all injury logs here."),
      ),
    );
  }
}
