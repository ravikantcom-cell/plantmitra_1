import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UploadMasterPlantsScreen extends StatefulWidget {
  const UploadMasterPlantsScreen({super.key});

  @override
  State<UploadMasterPlantsScreen> createState() =>
      _UploadMasterPlantsScreenState();
}

class _UploadMasterPlantsScreenState
    extends State<UploadMasterPlantsScreen> {

  bool uploading = false;

  Future<void> uploadPlants() async {

    setState(() {
      uploading = true;
    });

    final csv =
        await rootBundle.loadString("assets/data/plant_master.csv");

    final rows = const LineSplitter().convert(csv);

    final firestore = FirebaseFirestore.instance;

    int uploaded = 0;

    for (int i = 1; i < rows.length; i++) {

      final columns = rows[i].split(",");

      if (columns.length < 5) continue;

      await firestore
          .collection("plant_master")
          .doc(columns[0])
          .set({
        "id": columns[0],
        "name": columns[1],
        "scientificName": columns[2],
        "category": columns[3],
        "subCategory": columns[4],
        "active": true,
      });

      uploaded++;
    }

    setState(() {
      uploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$uploaded plants uploaded successfully"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Master Plants"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
            body: Center(
        child: uploading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: uploadPlants,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text(
                      "Upload Plant Master",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}