import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  // --- Firebase ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // --- Form & UI ---
  final _formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  bool isUploading = false;
  bool isFree = true;
  String selectedItemType = "Plant";

final List<String> itemTypes = [
  "Plant",
  "Seed",
  "Cutting",
  "Sapling",
];
  List<Map<String, dynamic>> masterPlants = [];
  Map<String, dynamic>? selectedPlant;

  // --- Controllers ---
  final TextEditingController plantController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPlants();
  }

  Future<void> loadPlants() async {
    debugPrint("loadPlants() STARTED");
    try {
      final snapshot = await firestore
    .collection("plant_master")
    .get();

          debugPrint("Documents = ${snapshot.docs.length}");

      masterPlants = snapshot.docs
    .map((e) => {"id": e.id, ...e.data()})
    .toList();
    masterPlants.sort(
  (a, b) => a["name"].toString().compareTo(
        b["name"].toString(),
      ),
);

setState(() {});

debugPrint("Plants Loaded: ${masterPlants.length}");
debugPrint(masterPlants.toString());
if (masterPlants.isNotEmpty) {
  debugPrint(masterPlants.first.toString());
}

if (mounted) {
  setState(() {});
}
   } catch (e, stack) {
  print("================================");
  print("ERROR TYPE : ${e.runtimeType}");
  print("ERROR      : $e");
  print("STACK");
  print(stack);
  print("================================");

  Fluttertoast.showToast(msg: "$e");
}  }
  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to pick image: $e");
    }
  }

  

   Future<String> uploadImage() async {
  // Temporary
  // Firebase Storage use nahi karenge

  if (selectedImage == null) {
    return "";
  }

  debugPrint("Image selected but upload skipped.");

  return "";
}

  Future<void> submitPlant() async {
    print("Selected Plant = ${selectedPlant?["name"]}");
    if (!_formKey.currentState!.validate()) return;

    if (selectedPlant == null) {
      Fluttertoast.showToast(msg: "Please select a plant from the list");
      return;
    }

   

    try {
      setState(() {
        isUploading = true;
      });

      // 1. Upload Image
      // 1. Upload Image (Optional)
String imageUrl = await uploadImage();

      final user = auth.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: "User not logged in");
        setState(() => isUploading = false);
        return;
      }

      // 2. Parse Price Safely
      double priceValue = 0.0;
      if (!isFree) {
        final priceStr = priceController.text.trim();
        if (priceStr.isEmpty) {
          Fluttertoast.showToast(msg: "Enter a valid price");
          setState(() => isUploading = false);
          return;
        }
        try {
          priceValue = double.parse(priceStr);
        } catch (e) {
          Fluttertoast.showToast(msg: "Price must be a number");
          setState(() => isUploading = false);
          return;
        }
      }

      // 3. Add to Firestore
      await firestore.collection("plants").add({
        "masterPlantId": selectedPlant!["id"],
        "name": selectedPlant!["name"],
        "scientificName": selectedPlant!["scientificName"],
        "category": selectedPlant!["category"],
        "subCategory": selectedPlant!["subCategory"],
        "itemType": selectedItemType,
        "description": descriptionController.text.trim(),
        "location": locationController.text.trim(),
        "imageUrl": imageUrl,
        "isFree": isFree,
        "price": isFree ? 0 : priceValue, // Using double for flexibility
        "ownerId": user.uid,
        "ownerName": user.displayName ?? "",
        "ownerEmail": user.email ?? "",
        "ownerPhoto": user.photoURL ?? "",
        "favoriteCount": 0,
        "chatCount": 0,
        "views": 0,
        "status": "Available",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Fluttertoast.showToast(msg: "Plant Added Successfully 🌱", backgroundColor: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      print("Submit Error: $e");
      if (mounted) {
        Fluttertoast.showToast(msg: "Failed to add plant: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    plantController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Plant"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
  onTap: isUploading ? null : pickImage,
  child: Container(
    height: 220,
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.green,
      ),
    ),
    child: selectedImage == null
        ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(
                Icons.camera_alt,
                size: 70,
                color: Colors.green,
              ),

              SizedBox(height: 10),

              Text(
                "Image Optional",
                style: TextStyle(fontSize: 18),
              ),

              SizedBox(height: 6),

              Text(
                "Tap to choose image",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(
              selectedImage!,
              fit: BoxFit.cover,
            ),
          ),
  ),
),

const SizedBox(height: 20),
DropdownButtonFormField<String>(
  value: selectedItemType,
  decoration: InputDecoration(
    labelText: "Item Type",
    prefixIcon: const Icon(
      Icons.category,
      color: Colors.green,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
  ),
  items: itemTypes.map((item) {
    return DropdownMenuItem(
      value: item,
      child: Text(item),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedItemType = value!;
    });
  },
),
            // Plant Name Autocomplete
            DropdownSearch<Map<String, dynamic>>(
  items: (filter, infiniteScrollProps) => masterPlants,

  itemAsString: (item) => item["name"].toString(),
  compareFn: (item1, item2) => item1["id"] == item2["id"],
  selectedItem: selectedPlant,

  popupProps: PopupProps.menu(
    showSearchBox: true,
    fit: FlexFit.loose,
    searchFieldProps: const TextFieldProps(
      decoration: InputDecoration(
        hintText: "Search Plant...",
      ),
    ),
  ),

  decoratorProps: DropDownDecoratorProps(
    decoration: InputDecoration(
      labelText: "Plant Name",
      prefixIcon: const Icon(Icons.local_florist),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  onChanged: (plant) {
    setState(() {
      selectedPlant = plant;
    });

    print("Selected Plant = ${plant?["name"]}");
  },

  validator: (value) {
    if (value == null) {
      return "Select Plant";
    }
    return null;
  },
),

            const SizedBox(height: 20),

            // Description
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 20),

            // Location
            TextFormField(
              controller: locationController,
              validator: (value) {
                if (value == null || value.isEmpty) return "Enter Location";
                return null;
              },
              decoration: InputDecoration(
                labelText: "Location",
                prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 20),

            // Free Switch
            SwitchListTile(
              value: isFree,
              title: const Text("Free Plant?", style: TextStyle(fontSize: 16)),
              subtitle: const Text("Gift this plant for free"),
              onChanged: (value) {
                setState(() {
                  isFree = value;
                  if (value) priceController.clear(); // Clear price if free
                });
              },
            ),

            if (!isFree) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter Price";
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Price (₹)",
                  prefixIcon: const Icon(Icons.money, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isUploading ? null : submitPlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: isUploading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload, size: 24),
                label: Text(
                  isUploading ? "Uploading..." : "Submit Plant",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}