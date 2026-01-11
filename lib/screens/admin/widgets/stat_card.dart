import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(count, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}