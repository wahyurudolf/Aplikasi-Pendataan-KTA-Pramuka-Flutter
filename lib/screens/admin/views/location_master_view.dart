import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ubah nama class biar jelas ini adalah KONTEN-nya saja
class LocationMasterContent extends StatelessWidget {
  final TabController tabController;

  const LocationMasterContent({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: const [
        _MasterKwardaTab(),
        _MasterKwarcabTab(),
        _MasterKwarranTab(),
      ],
    );
  }
}

// --- TAB KWARDA ---
class _MasterKwardaTab extends StatelessWidget {
  const _MasterKwardaTab();

  void _addKwarda(BuildContext context) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Tambah Kwarda"),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Nama Kwarda (Contoh: Banten)")),
      actions: [
        ElevatedButton(onPressed: () {
          if (controller.text.isNotEmpty) {
            FirebaseFirestore.instance.collection('master_kwarda').add({'nama': controller.text});
            Navigator.pop(ctx);
          }
        }, child: const Text("Simpan"))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Floating button tetap di sini agar spesifik per tab
      floatingActionButton: FloatingActionButton(onPressed: () => _addKwarda(context), child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('master_kwarda').orderBy('nama').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(children: snap.data!.docs.map((doc) => ListTile(
            title: Text(doc['nama']),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
          )).toList());
        },
      ),
    );
  }
}

// --- TAB KWARCAB ---
class _MasterKwarcabTab extends StatelessWidget {
  const _MasterKwarcabTab();

  void _addKwarcab(BuildContext context) {
    final nameController = TextEditingController();
    String? selectedKwardaId;
    
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: const Text("Tambah Kwarcab"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('master_kwarda').orderBy('nama').snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              return DropdownButtonFormField<String>(
                hint: const Text("Pilih Kwarda"),
                initialValue: selectedKwardaId,
                items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['nama']))).toList(),
                onChanged: (v) => setState(() => selectedKwardaId = v),
              );
            },
          ),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Kwarcab")),
        ]),
        actions: [
          ElevatedButton(onPressed: () {
            if (nameController.text.isNotEmpty && selectedKwardaId != null) {
              FirebaseFirestore.instance.collection('master_kwarcab').add({
                'nama': nameController.text,
                'kwarda_id': selectedKwardaId
              });
              Navigator.pop(ctx);
            }
          }, child: const Text("Simpan"))
        ],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _addKwarcab(context), child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('master_kwarcab').orderBy('nama').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(children: snap.data!.docs.map((doc) => ListTile(
            title: Text(doc['nama']),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
          )).toList());
        },
      ),
    );
  }
}

// --- TAB KWARRAN ---
class _MasterKwarranTab extends StatelessWidget {
  const _MasterKwarranTab();

  void _addKwarran(BuildContext context) {
    final nameController = TextEditingController();
    String? selectedKwarcabId;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: const Text("Tambah Kwarran"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('master_kwarcab').orderBy('nama').snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              return DropdownButtonFormField<String>(
                hint: const Text("Pilih Kwarcab"),
                initialValue: selectedKwarcabId,
                items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['nama']))).toList(),
                onChanged: (v) => setState(() => selectedKwarcabId = v),
              );
            },
          ),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Kwarran")),
        ]),
        actions: [
          ElevatedButton(onPressed: () {
            if (nameController.text.isNotEmpty && selectedKwarcabId != null) {
              FirebaseFirestore.instance.collection('master_kwarran').add({
                'nama': nameController.text,
                'kwarcab_id': selectedKwarcabId
              });
              Navigator.pop(ctx);
            }
          }, child: const Text("Simpan"))
        ],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _addKwarran(context), child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('master_kwarran').orderBy('nama').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(children: snap.data!.docs.map((doc) => ListTile(
            title: Text(doc['nama']),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
          )).toList());
        },
      ),
    );
  }
}