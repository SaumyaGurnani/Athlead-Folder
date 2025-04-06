import 'package:flutter/material.dart';
import 'injury_log_screen.dart';
import 'medical_consultation_screen.dart';
import 'rehabilitation_program_screen.dart';

class InjuryManagementScreen extends StatelessWidget {
  const InjuryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Injury Management & Recovery")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              context,
              title: "Injury Log & Reports",
              subtitle: "Track your injury history",
              screen: const InjuryLogScreen(),
            ),
            _buildCard(
              context,
              title: "Medical Consultation & Advice",
              subtitle: "Get expert medical help",
              screen: const MedicalConsultationScreen(),
            ),
            _buildCard(
              context,
              title: "Rehabilitation Programs",
              subtitle: "Follow recovery routines",
              screen: const RehabilitationProgramScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title,
      required String subtitle,
      required Widget screen}) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}
