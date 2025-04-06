import 'package:flutter/material.dart';

class MedicalConsultationScreen extends StatelessWidget {
  const MedicalConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medical Consultation & Advice")),
      body: const Center(
        child: Text("Medical advice and chat with experts."),
      ),
    );
  }
}
