import 'package:flutter/material.dart';
import 'user_list_by_role_page.dart';

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. DATA ADMIN TETAP
    final Map<String, dynamic> adminRole = {
      'id': 'super_admin', 
      'label': 'Super Admin', 
      'color': Colors.red, 
      'icon': Icons.security
    };

    // 2. UPDATE LIST ROLE LAINNYA
    final List<Map<String, dynamic>> otherRoles = [
      // Role Lapangan
      {'id': 'korlap', 'label': 'Koordinator Lapangan', 'color': Colors.purple, 'icon': Icons.group},
      {'id': 'sekolah', 'label': 'Sekolah', 'color': Colors.blue, 'icon': Icons.school},
      {'id': 'staff_pendataan', 'label': 'Staff Pendataan', 'color': Colors.orange, 'icon': Icons.assignment_ind},
      
      // --- ROLE PRODUKSI BARU ---
      {
        'id': 'supervisor_produksi', 
        'label': 'Supervisor Produksi', 
        'color': Colors.indigo, // Warna Pembeda
        'icon': Icons.manage_accounts
      },
      {
        'id': 'staff_produksi', 
        'label': 'Staff Percetakan', 
        'color': Colors.teal, // Warna Pembeda
        'icon': Icons.print
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kategori Pengguna",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // CARD ADMIN
            _buildWideCard(context, adminRole),
            
            const SizedBox(height: 16),

            // GRID CARD ROLE LAIN
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                ),
                itemCount: otherRoles.length,
                itemBuilder: (context, index) {
                  return _buildGridCard(context, otherRoles[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET UNTUK ADMIN (TAMPILAN MEMANJANG KE SAMPING) ---
  Widget _buildWideCard(BuildContext context, Map<String, dynamic> role) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(context, role),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: role['color'].withOpacity(0.1),
                child: Icon(role['icon'], size: 32, color: role['color']),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role['label'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 4),
                    const Text("Kelola akses tertinggi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, Map<String, dynamic> role) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(context, role),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: role['color'].withOpacity(0.1),
              child: Icon(role['icon'], size: 30, color: role['color']),
            ),
            const SizedBox(height: 12),
            Text(
              role['label'],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserListByRolePage(
          roleId: role['id'],
          roleLabel: role['label'],
        ),
      ),
    );
  }
}