import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import Widget StatCard
import '../widgets/stat_card.dart'; 

class DashboardStatsView extends StatelessWidget {
  const DashboardStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ringkasan Data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'sekolah').snapshots(),
                  builder: (ctx, snap) => StatCard(title: "Total Sekolah", count: snap.hasData ? "${snap.data!.docs.length}" : "...", color: Colors.blue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'staff').snapshots(),
                  builder: (ctx, snap) => StatCard(title: "Total Staff", count: snap.hasData ? "${snap.data!.docs.length}" : "...", color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('members').snapshots(),
              builder: (ctx, snap) => StatCard(title: "Total Anggota Terdata", count: snap.hasData ? "${snap.data!.docs.length}" : "...", color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}