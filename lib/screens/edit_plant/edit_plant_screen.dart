import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditPlantScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> plant;

  const EditPlantScreen({
    super.key,
    required this.documentId,
    required this.plant,
  });

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;

  bool isFree = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.plant["name"] ?? "");

    _descriptionController =
        TextEditingController(text: widget.plant["description"] ?? "");

    _locationController =
        TextEditingController(text: widget.plant["location"] ?? "");

    _priceController =
        TextEditingController(text: "${widget.plant["price"] ?? 0}");

    isFree = widget.plant["isFree"] ?? true;
  }

  Future<void> updatePlant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("plants")
          .doc(widget.documentId)
          .update({
        "name": _nameController.text.trim(),
        "description": _descriptionController.text.trim(),
        "location": _locationController.text.trim(),
        "isFree": isFree,
        "price": isFree
            ? 0
            : int.tryParse(_priceController.text.trim()) ?? 0,
      });

      Fluttertoast.showToast(
        msg: "Plant Updated Successfully 🌱",
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    bool requiredField = false,
    int maxLines = 1,
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
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Plant"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(
                Icons.edit,
                size: 100,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              buildField(
                controller: _nameController,
                label: "Plant Name",
                requiredField: true,
              ),

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
                  onPressed: isSaving ? null : updatePlant,
                  icon: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving ? "Saving..." : "Save Changes",
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