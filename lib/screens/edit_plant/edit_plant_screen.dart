// lib/screens/edit_plant/edit_plant_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plantmitra_1/utils/logger.dart';

class EditPlantScreen extends StatefulWidget {
  const EditPlantScreen({
    super.key,
    required this.documentId,
    required this.plant,
  });

  final String documentId;
  final Map<String, dynamic> plant;

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _secondaryText = Color(0xFF69806E);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;

  bool _isFree = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.plant['name']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.plant['description']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: widget.plant['location']?.toString() ?? '',
    );
    _isFree = widget.plant['isFree'] == true;

    final currentPrice = widget.plant['price'];
    _priceController = TextEditingController(
      text: _isFree || currentPrice == null || currentPrice.toString() == '0'
          ? ''
          : currentPrice.toString(),
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

  String? _requiredValidator(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) return 'Please enter $fieldName';
    return null;
  }

  String? _priceValidator(String? value) {
    if (_isFree) return null;
    final price = num.tryParse((value ?? '').trim());
    if (price == null || price <= 0) return 'Please enter a valid price';
    return null;
  }

  Future<void> _updatePlant() async {
    FocusScope.of(context).unfocus();
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    final currentUserId = _auth.currentUser?.uid;
    final ownerId = widget.plant['ownerId']?.toString() ?? '';
    if (currentUserId == null || ownerId.isEmpty || currentUserId != ownerId) {
      _showMessage('Only the owner can edit this plant.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final price = _isFree
          ? 0
          : num.parse(_priceController.text.trim());

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'isFree': _isFree,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('plants').doc(widget.documentId).update(updates);

      if (!mounted) return;
      _showMessage('Plant updated successfully.');
      Navigator.of(context).pop(<String, dynamic>{
        ...widget.plant,
        ...updates,
      });
    } on FirebaseException catch (error) {
      Logger.error('Firebase edit plant error: ${error.code} - ${error.message}');
      if (!mounted) return;
      final message = error.code == 'permission-denied'
          ? 'You do not have permission to update this plant.'
          : error.code == 'not-found'
              ? 'This plant listing no longer exists.'
              : 'Could not update the plant. Please try again.';
      _showMessage(message, isError: true);
    } catch (error) {
      Logger.error('Edit plant error: $error');
      if (mounted) {
        _showMessage('Could not update the plant. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmLeave() async {
    if (_isSaving) return false;
    return true;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : _darkGreen,
        ),
      );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: Icon(icon, color: _green),
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE8DD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE8DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _green, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.plant['imageUrl']?.toString() ?? '';

    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FBF6),
        appBar: AppBar(
          title: const Text('Edit plant'),
          backgroundColor: Colors.white,
          foregroundColor: _darkGreen,
          elevation: 0,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF5FBF5), Color(0xFFEAF7EC)],
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ImagePreview(imageUrl: imageUrl),
                        const SizedBox(height: 22),
                        const Text(
                          'Listing details',
                          style: TextStyle(
                            color: _darkGreen,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Keep the information accurate so plant lovers know what to expect.',
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE0ECE1)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F174D2B),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                enabled: !_isSaving,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    _requiredValidator(value, 'the plant name'),
                                decoration: _decoration(
                                  label: 'Plant name',
                                  icon: Icons.local_florist_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _locationController,
                                enabled: !_isSaving,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    _requiredValidator(value, 'the location'),
                                decoration: _decoration(
                                  label: 'Location',
                                  icon: Icons.location_on_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                enabled: !_isSaving,
                                textCapitalization: TextCapitalization.sentences,
                                minLines: 4,
                                maxLines: 7,
                                decoration: _decoration(
                                  label: 'Description',
                                  icon: Icons.notes_rounded,
                                  hint: 'Describe the plant and its condition',
                                ),
                              ),
                              const SizedBox(height: 18),
                              _ListingTypeSelector(
                                isFree: _isFree,
                                enabled: !_isSaving,
                                onChanged: (value) {
                                  setState(() {
                                    _isFree = value;
                                    if (value) _priceController.clear();
                                  });
                                },
                              ),
                              if (!_isFree) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _priceController,
                                  enabled: !_isSaving,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  validator: _priceValidator,
                                  onFieldSubmitted: (_) => _updatePlant(),
                                  decoration: _decoration(
                                    label: 'Price',
                                    icon: Icons.currency_rupee_rounded,
                                    prefixText: '₹ ',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _updatePlant,
                            style: FilledButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _green.withValues(alpha: 0.45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox.square(
                                    dimension: 21,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _isSaving ? 'Saving changes...' : 'Save changes',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: imageUrl.isEmpty
            ? const _ImageFallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const _ImageFallback(showLoader: true),
                errorBuilder: (_, __, ___) => const _ImageFallback(),
              ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.showLoader = false});

  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7F3E8),
      alignment: Alignment.center,
      child: showLoader
          ? const CircularProgressIndicator(color: Color(0xFF2E7D32))
          : const Icon(
              Icons.local_florist_rounded,
              color: Color(0xFF2E7D32),
              size: 72,
            ),
    );
  }
}

class _ListingTypeSelector extends StatelessWidget {
  const _ListingTypeSelector({
    required this.isFree,
    required this.enabled,
    required this.onChanged,
  });

  final bool isFree;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listing type',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                title: 'Free',
                icon: Icons.volunteer_activism_outlined,
                selected: isFree,
                enabled: enabled,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceCard(
                title: 'For sale',
                icon: Icons.sell_outlined,
                selected: !isFree,
                enabled: enabled,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2E7D32) : const Color(0xFF69806E);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF7EC) : const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? const Color(0xFF2E7D32) : const Color(0xFFDCE8DD),
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
