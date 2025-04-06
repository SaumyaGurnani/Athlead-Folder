import 'package:flutter/material.dart';

class RehabilitationProgramScreen extends StatelessWidget {
  const RehabilitationProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rehabilitation Programs")),
      body: const Center(
        child: Text("Your rehab programs and exercises."),
      ),
    );
  }
}
