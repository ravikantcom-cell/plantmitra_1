// lib/screens/admin/upload_master_plants_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plantmitra_1/utils/logger.dart';

class UploadMasterPlantsScreen extends StatefulWidget {
  const UploadMasterPlantsScreen({super.key});

  @override
  State<UploadMasterPlantsScreen> createState() =>
      _UploadMasterPlantsScreenState();
}

class _UploadMasterPlantsScreenState
    extends State<UploadMasterPlantsScreen> {
  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);

  // Five-column files load first. The richer 14-column batch loads last so
  // its non-empty care fields take priority for duplicate IDs.
  static const List<String> _assetFiles = <String>[
    'assets/data/plant_master.csv',
    'assets/data/plant_master_phase1_batch2.csv',
    'assets/data/plant_master_phase1_batch3.csv',
    'assets/data/plant_master_phase1_batch1.csv',
  ];

  bool _uploading = false;
  double _progress = 0;
  String _status = 'Ready to validate plant data';

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _uploadPlants() async {
    if (_uploading || _uid.isEmpty) return;
    final confirmed = await _confirmUpload();
    if (confirmed != true || !mounted) return;

    setState(() {
      _uploading = true;
      _progress = 0;
      _status = 'Reading CSV files...';
    });

    try {
      final plants = await _loadAndMergePlants();
      if (plants.isEmpty) throw StateError('No valid plant records were found.');

      if (!mounted) return;
      setState(() => _status = 'Uploading ${plants.length} unique plants...');

      final firestore = FirebaseFirestore.instance;
      final entries = plants.entries.toList();
      const batchSize = 400;
      var completed = 0;

      while (completed < entries.length) {
        final end = (completed + batchSize).clamp(0, entries.length);
        final batch = firestore.batch();

        for (var index = completed; index < end; index++) {
          final entry = entries[index];
          final data = <String, dynamic>{
            ...entry.value,
            'id': entry.key,
            'active': true,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          batch.set(
            firestore.collection('plant_master').doc(entry.key),
            data,
            SetOptions(merge: true),
          );
        }

        await batch.commit();
        completed = end;
        if (mounted) {
          setState(() {
            _progress = completed / entries.length;
            _status = 'Uploaded $completed of ${entries.length} plants';
          });
        }
      }

      if (!mounted) return;
      setState(() => _status = '${entries.length} unique plants uploaded');
      _message('${entries.length} plants uploaded successfully.');
    } on FirebaseException catch (error) {
      Logger.error('Plant master upload failed: ${error.code} - ${error.message}');
      if (!mounted) return;
      final message = error.code == 'permission-denied'
          ? 'Upload permission denied. Publish the temporary admin rule first.'
          : 'Firebase upload failed: ${error.message ?? error.code}';
      setState(() => _status = message);
      _message(message, error: true);
    } catch (error) {
      Logger.error('Plant master upload failed: $error');
      if (!mounted) return;
      setState(() => _status = 'Upload failed. Check the CSV files and try again.');
      _message(_status, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadAndMergePlants() async {
    final merged = <String, Map<String, dynamic>>{};

    for (var fileIndex = 0; fileIndex < _assetFiles.length; fileIndex++) {
      final asset = _assetFiles[fileIndex];
      if (mounted) {
        setState(() {
          _status = 'Reading ${asset.split('/').last}';
          _progress = fileIndex / _assetFiles.length * 0.15;
        });
      }

      final csv = await rootBundle.loadString(asset);
      final rows = _parseCsv(csv);
      if (rows.length < 2) continue;

      final headers = rows.first.map((value) => value.trim()).toList();
      for (final row in rows.skip(1)) {
        final record = <String, dynamic>{};
        for (var column = 0; column < headers.length; column++) {
          if (column >= row.length) continue;
          final key = headers[column];
          final value = row[column].trim();
          if (key.isEmpty || value.isEmpty) continue;
          record[key] = _typedValue(key, value);
        }

        final id = record['id']?.toString().trim() ?? '';
        final name = record['name']?.toString().trim() ?? '';
        if (id.isEmpty || name.isEmpty) continue;

        final current = merged.putIfAbsent(id, () => <String, dynamic>{});
        current.addAll(record);
      }
    }

    // Fallback choice for plants that are not available in the master list.
    merged['other'] = <String, dynamic>{
      'id': 'other',
      'name': 'Other',
      'scientificName': '',
      'family': '',
      'category': 'Other',
      'subCategory': 'Other',
      'description': 'Plant not currently available in the master list.',
    };

    return merged;
  }

  dynamic _typedValue(String key, String value) {
    if (key == 'airPurifying' || key == 'petSafe') {
      return value.toLowerCase() == 'true';
    }
    return value;
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var insideQuotes = false;

    for (var index = 0; index < input.length; index++) {
      final character = input[index];

      if (character == '"') {
        final escapedQuote = insideQuotes &&
            index + 1 < input.length &&
            input[index + 1] == '"';
        if (escapedQuote) {
          field.write('"');
          index++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (character == ',' && !insideQuotes) {
        row.add(field.toString());
        field.clear();
      } else if ((character == '\n' || character == '\r') && !insideQuotes) {
        if (character == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index++;
        }
        row.add(field.toString());
        field.clear();
        if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
        row = <String>[];
      } else {
        field.write(character);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
    }
    return rows;
  }

  Future<bool?> _confirmUpload() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.cloud_upload_outlined, color: _green),
        title: const Text('Update Plant Master?'),
        content: const Text(
          'This will merge all non-empty CSV batches, remove duplicate IDs and update matching Firebase documents. Existing fields are preserved when a CSV value is empty.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : _darkGreen,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text('Update Plant Master'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0E9E1)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: _green,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Plant Master Database',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _darkGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '4 CSV files • 527 source rows • 494 plants + Other',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF69806E), fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                  LinearProgressIndicator(
                    value: _uploading ? _progress : null,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(12),
                    color: _green,
                    backgroundColor: const Color(0xFFE0ECE1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF69806E)),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _uploading || _uid.isEmpty ? null : _uploadPlants,
                      icon: _uploading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(_uploading ? 'Uploading...' : 'Validate and upload'),
                    ),
                  ),
                  const SizedBox(height: 13),
                  SelectableText(
                    _uid.isEmpty ? 'Sign in before uploading.' : 'Your admin UID: $_uid',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF69806E),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
