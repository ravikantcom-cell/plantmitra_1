// lib/screens/add_plant/add_plant_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plantmitra_1/services/firestore_service.dart';
import 'package:plantmitra_1/services/storage_service.dart';
import 'package:plantmitra_1/theme/app_colors.dart';
import 'package:plantmitra_1/utils/logger.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final List<String> _itemTypes = const ['Plant', 'Seed', 'Cutting', 'Sapling'];

  File? _selectedImage;
  bool _isUploading = false;
  bool _isFree = true;
  String _selectedItemType = 'Plant';

  List<Map<String, dynamic>> _masterPlants = [];
  Map<String, dynamic>? _selectedPlant;
  bool _isLoadingPlants = true;
  String? _plantLoadError;

  bool get _isOtherPlant {
    final id = _selectedPlant?['id']?.toString().trim().toLowerCase();
    final name = _selectedPlant?['name']?.toString().trim().toLowerCase();
    return id == 'other' || name == 'other';
  }

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    if (mounted) {
      setState(() {
        _isLoadingPlants = true;
        _plantLoadError = null;
      });
    }

    try {
      Logger.debug('Loading plant master list from Firestore...');

      final snapshot = await FirestoreService.masterPlants.get();

      final plants = snapshot.docs
          .map((document) {
            final data = document.data();

            return <String, dynamic>{
              'id': document.id,
              'name': data['name']?.toString().trim() ?? '',
              'scientificName': data['scientificName']?.toString().trim() ?? '',
              'category': data['category']?.toString().trim() ?? '',
              'subCategory': data['subCategory']?.toString().trim() ?? '',
              'active': data['active'] ?? true,
            };
          })
          .where((plant) {
            return plant['active'] == true &&
                plant['name'].toString().trim().isNotEmpty;
          })
          .toList();

      plants.sort(
        (first, second) => first['name'].toString().toLowerCase().compareTo(
          second['name'].toString().toLowerCase(),
        ),
      );

      Logger.info('Loaded ${plants.length} active master plants');

      if (!mounted) return;

      setState(() {
        _masterPlants = plants;
        _isLoadingPlants = false;

        if (plants.isEmpty) {
          _plantLoadError = 'No plants are available in the master list.';
        }
      });
    } catch (error, stackTrace) {
      Logger.error('Failed to load master plants: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoadingPlants = false;
        _plantLoadError =
            'Unable to load the plant list. Check your internet and try again.';
      });
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (_isUploading) return;

    FocusScope.of(context).unfocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add plant photo',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose where you want to select the image from.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _SourceIcon(
                    icon: Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Select an existing plant photo'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _SourceIcon(
                    icon: Icons.camera_alt_outlined,
                    color: AppColors.primaryDark,
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Use your camera to take a new photo'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (error, stackTrace) {
      Logger.error('Image selection failed: $error\n$stackTrace');

      if (!mounted) return;
      _showMessage(
        'Unable to select the image. Please try again.',
        isError: true,
      );
    }
  }

  void _removeSelectedImage() {
    if (_isUploading) return;

    setState(() {
      _selectedImage = null;
    });
  }

  String? _validateLocation(String? value) {
    final location = value?.trim() ?? '';

    if (location.isEmpty) {
      return 'Please enter the plant location';
    }

    if (location.length < 2) {
      return 'Please enter a valid location';
    }

    return null;
  }

  String? _validatePrice(String? value) {
    if (_isFree) return null;

    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter the selling price';
    }

    final price = double.tryParse(text);

    if (price == null) {
      return 'Please enter a valid number';
    }

    if (price <= 0) {
      return 'Price must be greater than zero';
    }

    return null;
  }

  Future<void> _submitPlant() async {
    if (_isUploading) return;

    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      _showMessage('Please correct the highlighted fields.', isError: true);
      return;
    }

    if (_selectedPlant == null) {
      _showMessage(
        'Please select a plant from the master list.',
        isError: true,
      );
      return;
    }

    if (_isOtherPlant && _descriptionController.text.trim().isEmpty) {
      _showMessage('Please write the plant name.', isError: true);
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Your session has expired. Please log in again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var imageUrl = '';

      if (_selectedImage != null) {
        imageUrl = await StorageService.uploadPlantImage(_selectedImage!);
      }

      final price = _isFree ? 0.0 : double.parse(_priceController.text.trim());

      final ownerName = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Jarvis Green User');

      final plantData = <String, dynamic>{
        'masterPlantId': _selectedPlant!['id'],
        'name': _isOtherPlant
            ? _descriptionController.text.trim()
            : _selectedPlant!['name'],
        'scientificName': _selectedPlant!['scientificName'] ?? '',
        'category': _selectedPlant!['category'] ?? '',
        'subCategory': _selectedPlant!['subCategory'] ?? '',
        'itemType': _selectedItemType,
        'description': _isOtherPlant ? '' : _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'imageUrl': imageUrl,
        'isFree': _isFree,
        'price': price,
        'ownerId': user.uid,
        'ownerName': ownerName,
        'ownerEmail': user.email ?? '',
        'ownerPhoto': user.photoURL ?? '',
        'favoriteCount': 0,
        'chatCount': 0,
        'views': 0,
        'status': 'Available',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirestoreService.addPlant(plantData);

      if (!mounted) return;

      _showMessage('Plant added successfully 🌱', isError: false);

      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      Logger.error('Plant submission failed: $error\n$stackTrace');

      if (!mounted) return;

      _showMessage('Failed to add the plant. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.error : AppColors.primaryDark,
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: AppColors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isUploading) {
          _showMessage(
            'Please wait while your plant is being uploaded.',
            isError: true,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 4,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Plant',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Share a plant with the community',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh plant list',
              onPressed: _isUploading ? null : _loadPlants,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildPhotoSection(),
                const SizedBox(height: 24),
                const _FormSectionHeader(
                  icon: Icons.eco_outlined,
                  title: 'Plant details',
                  subtitle: 'Select the plant and listing type',
                ),
                const SizedBox(height: 12),
                _buildPlantDetailsCard(),
                const SizedBox(height: 24),
                const _FormSectionHeader(
                  icon: Icons.notes_rounded,
                  title: 'Listing information',
                  subtitle: 'Describe the plant and where it is available',
                ),
                const SizedBox(height: 12),
                _buildListingInformationCard(),
                const SizedBox(height: 24),
                const _FormSectionHeader(
                  icon: Icons.sell_outlined,
                  title: 'Availability',
                  subtitle: 'Choose whether it is free or for sale',
                ),
                const SizedBox(height: 12),
                _buildAvailabilityCard(),
                const SizedBox(height: 28),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormSectionHeader(
          icon: Icons.photo_camera_outlined,
          title: 'Plant photo',
          subtitle: 'A clear photo helps your listing get noticed',
        ),
        const SizedBox(height: 12),
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: _showImageSourceSheet,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: _selectedImage == null
                  ? _buildEmptyPhotoState()
                  : _buildSelectedPhoto(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPhotoState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 31,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Add a plant photo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tap to use camera or choose from gallery',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 7),
          Text(
            'Optional',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPhoto() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.error,
                  size: 42,
                ),
              );
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, color: AppColors.white, size: 17),
                SizedBox(width: 6),
                Text(
                  'Change photo',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton.filled(
            tooltip: 'Remove photo',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.55),
              foregroundColor: AppColors.white,
            ),
            onPressed: _removeSelectedImage,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildPlantDetailsCard() {
    return _FormCard(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedItemType,
          decoration: _inputDecoration(
            label: 'Item type',
            hint: 'Select listing type',
            icon: Icons.category_outlined,
          ),
          items: _itemTypes.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: _isUploading
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedItemType = value;
                  });
                },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select the item type';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildMasterPlantField(),
        if (_selectedPlant != null) ...[
          const SizedBox(height: 14),
          _buildSelectedPlantCard(),
        ],
      ],
    );
  }

  Widget _buildMasterPlantField() {
    if (_isLoadingPlants) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Loading plant master list...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_plantLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Plant list unavailable',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _plantLoadError!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _loadPlants,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownSearch<Map<String, dynamic>>(
        items: (filter, infiniteScrollProps) {
          final query = filter.trim().toLowerCase();

          if (query.isEmpty) {
            return _masterPlants;
          }

          return _masterPlants.where((plant) {
            final name = plant['name'].toString().toLowerCase();
            final scientificName = plant['scientificName']
                .toString()
                .toLowerCase();
            final category = plant['category'].toString().toLowerCase();
            final subCategory = plant['subCategory'].toString().toLowerCase();

            return name.contains(query) ||
                scientificName.contains(query) ||
                category.contains(query) ||
                subCategory.contains(query);
          }).toList();
        },
        selectedItem: _selectedPlant,
        itemAsString: (item) => item['name'].toString(),
        compareFn: (first, second) => first['id'] == second['id'],
        enabled: !_isUploading,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          fit: FlexFit.loose,
          searchFieldProps: const TextFieldProps(
            decoration: InputDecoration(
              hintText: 'Search by name, category or scientific name',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          emptyBuilder: (context, searchEntry) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    color: AppColors.textSecondary,
                    size: 38,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No matching plant found',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: _inputDecoration(
            label: 'Plant name',
            hint: 'Search and select a plant',
            icon: Icons.local_florist_outlined,
            border: InputBorder.none,
          ),
        ),
        onChanged: (plant) {
          setState(() {
            _selectedPlant = plant;
            _descriptionController.clear();
          });

          if (plant != null) {
            Logger.debug('Selected plant: ${plant['name']} (${plant['id']})');
          }
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a plant';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSelectedPlantCard() {
    final scientificName = _selectedPlant!['scientificName'].toString().trim();
    final category = _selectedPlant!['category'].toString().trim();
    final subCategory = _selectedPlant!['subCategory'].toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPlant!['name'].toString(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (scientificName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    scientificName,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (category.isNotEmpty || subCategory.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (category.isNotEmpty) _PlantInfoChip(label: category),
                      if (subCategory.isNotEmpty)
                        _PlantInfoChip(label: subCategory),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingInformationCard() {
    return _FormCard(
      children: [
        TextFormField(
          controller: _descriptionController,
          enabled: !_isUploading,
          maxLines: _isOtherPlant ? 1 : 4,
          minLines: _isOtherPlant ? 1 : 3,
          maxLength: _isOtherPlant ? 80 : 500,
          textCapitalization: _isOtherPlant
              ? TextCapitalization.words
              : TextCapitalization.sentences,
          validator: (value) {
            if (!_isOtherPlant) return null;
            if (value == null || value.trim().isEmpty) {
              return 'Please write the plant name';
            }
            if (value.trim().length < 2) {
              return 'Plant name is too short';
            }
            return null;
          },
          decoration: _inputDecoration(
            label: _isOtherPlant ? 'Plant name' : 'Description',
            hint: _isOtherPlant
                ? 'Type your plant name here'
                : 'Mention plant condition, size, care or pickup details',
            icon: _isOtherPlant
                ? Icons.local_florist_outlined
                : Icons.description_outlined,
            requiredField: _isOtherPlant,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          enabled: !_isUploading,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          validator: _validateLocation,
          decoration: _inputDecoration(
            label: 'Location',
            hint: 'Example: Rohini, Delhi',
            icon: Icons.location_on_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    return _FormCard(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _isFree
                ? AppColors.primary.withValues(alpha: 0.07)
                : AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFree
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.warning.withValues(alpha: 0.25),
            ),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            value: _isFree,
            onChanged: _isUploading
                ? null
                : (value) {
                    setState(() {
                      _isFree = value;

                      if (value) {
                        _priceController.clear();
                      }
                    });
                  },
            activeThumbColor: AppColors.primary,
            title: Text(
              _isFree ? 'Free plant' : 'Plant for sale',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              _isFree
                  ? 'Share this plant with someone for free'
                  : 'Set a price for this plant listing',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            secondary: Icon(
              _isFree ? Icons.volunteer_activism_rounded : Icons.sell_rounded,
              color: _isFree ? AppColors.primary : AppColors.warning,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _isFree
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey('price-field'),
                  padding: const EdgeInsets.only(top: 16),
                  child: TextFormField(
                    controller: _priceController,
                    enabled: !_isUploading,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: _validatePrice,
                    decoration: _inputDecoration(
                      label: 'Price',
                      hint: 'Enter selling price',
                      icon: Icons.currency_rupee_rounded,
                      prefixText: '₹ ',
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: _isUploading ? null : _submitPlant,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.50),
          disabledForegroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isUploading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.white,
                ),
              )
            : const Icon(Icons.cloud_upload_outlined),
        label: Text(
          _isUploading ? 'Publishing plant...' : 'Publish Plant',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    InputBorder? border,
    String? prefixText,
    bool requiredField = true,
  }) {
    return InputDecoration(
      labelText: requiredField ? '$label *' : '$label (optional)',
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      prefixText: prefixText,
      filled: true,
      fillColor: AppColors.background,
      counterText: '',
      border:
          border ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
      enabledBorder:
          border ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
      focusedBorder:
          border ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
      errorBorder:
          border ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error),
          ),
      focusedErrorBorder:
          border ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _PlantInfoChip extends StatelessWidget {
  const _PlantInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
