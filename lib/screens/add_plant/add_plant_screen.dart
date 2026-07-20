// lib/screens/add_plant/add_plant_screen.dart
import 'dart:io';
import 'package:plantmitra_1/services/storage_service.dart';
import 'package:plantmitra_1/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:plantmitra_1/utils/logger.dart';


class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;

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
  bool isLoadingPlants = true;
  String errorMessage = '';

  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPlants();
  }

  Future<void> loadPlants() async {
    setState(() {
      isLoadingPlants = true;
      errorMessage = '';
    });
    
    try {
      Logger.debug("🔄 Loading plant_master from Firebase...");
      
      // Simple query - no orderBy or where to avoid index issues
      final snapshot = await FirestoreService.masterPlants.get();

      Logger.debug("📊 Total plant_master documents: ${snapshot.docs.length}");

      if (snapshot.docs.isEmpty) {
        Logger.warning("⚠️ No documents found in plant_master collection!");
        setState(() {
          errorMessage = "No plants found in master list";
          isLoadingPlants = false;
        });
        return;
      }

      masterPlants = snapshot.docs.map((e) {
        final data = e.data();
        Logger.debug("🌱 Plant: ${e.id} - ${data['name']}");
        
        return {
          "id": e.id,
          "name": data["name"]?.toString() ?? "",
          "scientificName": data["scientificName"]?.toString() ?? "",
          "category": data["category"]?.toString() ?? "",
          "subCategory": data["subCategory"]?.toString() ?? "",
          "active": data["active"] ?? true,
        };
      }).toList();

      // Filter active plants and sort in memory
      masterPlants = masterPlants
          .where((plant) => plant["active"] == true)
          .toList();
      
      masterPlants.sort((a, b) => 
          a["name"].toString().compareTo(b["name"].toString())
      );

      Logger.info("✅ Loaded ${masterPlants.length} active plants successfully");
      
      if (mounted) {
        setState(() {
          isLoadingPlants = false;
        });
      }
    } catch (e) {
      Logger.error("❌ Error loading plants: $e");
      setState(() {
        errorMessage = "Error loading plants. Please try again.";
        isLoadingPlants = false;
      });
      if (mounted) {
        Fluttertoast.showToast(msg: "Error loading plants: $e");
      }
    }
  }

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
      if (mounted) {
        Fluttertoast.showToast(msg: "Failed to pick image: $e");
      }
    }
  }

   

  Future<void> submitPlant() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "Please fill all required fields");
      return;
    }

    if (selectedPlant == null) {
      Fluttertoast.showToast(msg: "Please select a plant from the list");
      return;
    }

    if (locationController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter location");
      return;
    }

    if (!isFree && priceController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter price");
      return;
    }

    try {
      setState(() => isUploading = true);

      String imageUrl = "";

if (selectedImage != null) {
  imageUrl = await StorageService.uploadPlantImage(selectedImage!);
}

      final user = auth.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: "User not logged in");
        setState(() => isUploading = false);
        return;
      }

      double priceValue = 0.0;
      if (!isFree) {
        try {
          priceValue = double.parse(priceController.text.trim());
        } catch (e) {
          Fluttertoast.showToast(msg: "Price must be a number");
          setState(() => isUploading = false);
          return;
        }
      }

      final plantData = {
        "masterPlantId": selectedPlant!["id"],
        "name": selectedPlant!["name"],
        "scientificName": selectedPlant!["scientificName"] ?? "",
        "category": selectedPlant!["category"] ?? "",
        "subCategory": selectedPlant!["subCategory"] ?? "",
        "itemType": selectedItemType,
        "description": descriptionController.text.trim(),
        "location": locationController.text.trim(),
        "imageUrl": imageUrl,
        "isFree": isFree,
        "price": isFree ? 0 : priceValue,
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
      };

      await FirestoreService.addPlant(plantData);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Plant Added Successfully 🌱",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Logger.error("Submit Error: $e");
      if (mounted) {
        Fluttertoast.showToast(msg: "Failed to add plant: $e");
      }
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  void dispose() {
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
        actions: [
          if (isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadPlants,
            tooltip: 'Refresh plant list',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Picker
            GestureDetector(
              onTap: isUploading ? null : pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green),
                ),
                child: selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 70, color: Colors.green),
                          SizedBox(height: 10),
                          Text("Tap to select image", style: TextStyle(fontSize: 16)),
                          Text("(Optional)", style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Item Type
            DropdownButtonFormField<String>(
              initialValue: selectedItemType,
              decoration: InputDecoration(
                labelText: "Item Type *",
                prefixIcon: const Icon(Icons.category, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: itemTypes.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedItemType = value!);
              },
              validator: (value) => value == null ? "Please select item type" : null,
            ),
            const SizedBox(height: 20),

            // Plant Name Dropdown
            isLoadingPlants
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 12),
                        Text("Loading plants..."),
                      ],
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.red.shade50,
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: loadPlants,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    : masterPlants.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.orange.shade50,
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                                const SizedBox(height: 8),
                                const Text(
                                  "No plants available in master list",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.orange),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: loadPlants,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text("Refresh"),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownSearch<Map<String, dynamic>>(
                              items: (filter, infiniteScrollProps) {
                                if (filter.isEmpty) {
                                  return masterPlants;
                                }
                                return masterPlants.where((plant) {
                                  final name = plant["name"].toString().toLowerCase();
                                  return name.contains(filter.toLowerCase());
                                }).toList();
                              },
                              itemAsString: (item) => item["name"].toString(),
                              compareFn: (item1, item2) => item1["id"] == item2["id"],
                              selectedItem: selectedPlant,
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                fit: FlexFit.loose,
                                searchFieldProps: const TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Search Plant...",
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                                emptyBuilder: (context, searchEntry) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        "No plants found",
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: "Plant Name *",
                                  prefixIcon: const Icon(Icons.local_florist, color: Colors.green),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  hintText: "Select a plant...",
                                ),
                              ),
                              onChanged: (plant) {
                                setState(() {
                                  selectedPlant = plant;
                                });
                                if (plant != null) {
                                  Logger.debug(
                                    "✅ Selected Plant: ${plant["name"]} (${plant["id"]})",
                                  );
                                }
                              },
                              validator: (value) => value == null ? "Please select a plant" : null,
                            ),
                          ),
            const SizedBox(height: 20),

            // Show selected plant info
            if (selectedPlant != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Selected: ${selectedPlant!['name']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (selectedPlant!['scientificName'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 4),
                        child: Text(
                          "Scientific: ${selectedPlant!['scientificName']}",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (selectedPlant!['category'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 2),
                        child: Text(
                          "Category: ${selectedPlant!['category']}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Description
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                prefixIcon: const Icon(Icons.description, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),

            // Location
            TextFormField(
              controller: locationController,
              validator: (value) => value?.isEmpty == true ? "Enter Location" : null,
              decoration: InputDecoration(
                labelText: "Location *",
                prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),

            // Free Switch - Fixed: activeColor -> activeThumbColor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFree ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFree ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: SwitchListTile(
                value: isFree,
                title: Text(
                  "Free Plant?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isFree ? Colors.green : Colors.orange,
                  ),
                ),
                subtitle: Text(
                  isFree ? "Gift this plant for free" : "This plant is for sale",
                  style: TextStyle(
                    color: isFree ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
                activeThumbColor: Colors.green, // Fixed: activeColor -> activeThumbColor
                onChanged: (value) {
                  setState(() {
                    isFree = value;
                    if (value) priceController.clear();
                  });
                },
              ),
            ),

            if (!isFree) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? "Enter Price" : null,
                decoration: InputDecoration(
                  labelText: "Price (₹) *",
                  prefixIcon: const Icon(Icons.money, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
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