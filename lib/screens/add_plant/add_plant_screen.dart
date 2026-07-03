import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

// NOTE: Ensure you have a PlantMasterService class or remove this if you are fetching from Firestore directly.
// For this fix, I will assume you are fetching plants from Firestore as per your broken code.

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  File? _image;

  bool isUploading = false;

  bool isFree = true;

  final _descriptionController = TextEditingController();

  final _locationController = TextEditingController();

  final _priceController = TextEditingController();

  String? selectedPlant;

  Map<String, dynamic>? selectedPlantData;

  Future<void> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (file != null) {
      setState(() {
        _image = File(file.path);
      });
    }
  }

  Future<void> submitPlant() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedPlant == null) {
      Fluttertoast.showToast(
        msg: "Please select plant",
      );
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      final user = FirebaseAuth.instance.currentUser!;

      String imageUrl = "";

      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("plants")
            .child("${const Uuid().v4()}.jpg");

        await ref.putFile(_image!);

        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection("plants").add({
        "name": selectedPlant,
        "scientificName": selectedPlantData?["scientificName"],
        "category": selectedPlantData?["category"],
        "subCategory": selectedPlantData?["subCategory"],
        "description": _descriptionController.text.trim(),
        "location": _locationController.text.trim(),
        "imageUrl": imageUrl,
        "isFree": isFree,
        "price": isFree
            ? 0
            : int.tryParse(_priceController.text.trim()) ?? 0,
        "ownerId": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: "Plant Added Successfully",
      );

      _descriptionController.clear();
      _locationController.clear();
      _priceController.clear();

      setState(() {
        selectedPlant = null;
        selectedPlantData = null;
        _image = null;
        isFree = true;
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }

    setState(() {
      isUploading = false;
    });
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Enter $label";
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Plant"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 60,
                              color: Colors.green,
                            ),
                            SizedBox(height: 10),
                            Text("Tap to select image"),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ FIXED: Proper StreamBuilder for fetching plants
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
    .collection("plant_master")
    .where("active", isEqualTo: true)
    .orderBy("name")
    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading plants"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text("No plants available"));
                  }

                  return DropdownSearch<String>(
                    selectedItem: selectedPlant,
                    items: (String filter, LoadProps? loadProps) {
  return docs
      .map((e) => e["name"]?.toString() ?? "Unknown")
      .where((name) =>
          filter.isEmpty ||
          name.toLowerCase().contains(filter.toLowerCase()))
      .toList();
},
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                    ),
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: "Select Plant",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_florist),
                      ),
                    ),
                    onChanged: (value) {
  final selected = docs.firstWhere(
    (e) => e["name"] == value,
  );

  setState(() {
    selectedPlant = value;
    selectedPlantData =
        selected.data() as Map<String, dynamic>;
  });
},
                  );
                },
              ),

              const SizedBox(height: 20),

              if (selectedPlantData != null)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Scientific Name",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          selectedPlantData!["scientificName"] ?? "N/A",
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Category : ${selectedPlantData!["category"] ?? "N/A"}",
                        ),
                        Text(
                          "Sub Category : ${selectedPlantData!["subCategory"] ?? "N/A"}",
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              buildField(
                controller: _descriptionController,
                label: "Description",
                maxLines: 3,
              ),

              buildField(
                controller: _locationController,
                label: "Location",
                requiredField: true,
              ),

              SwitchListTile(
                title: const Text("Free Plant"),
                value: isFree,
                activeThumbColor: Colors.green,
                onChanged: (value) {
                  setState(() {
                    isFree = value;
                  });
                },
              ),

              if (!isFree)
                buildField(
                  controller: _priceController,
                  label: "Price",
                  keyboardType: TextInputType.number,
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isUploading ? null : submitPlant,
                  icon: isUploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    isUploading ? "Uploading..." : "Submit Plant",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}