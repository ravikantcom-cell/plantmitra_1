import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlantTransferService {
  PlantTransferService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _transfers =>
      _firestore.collection('plant_transfers');

  String transferId(String plantId, String receiverId) =>
      '${plantId}_$receiverId';

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to continue.');
    }
    return user;
  }

  Future<void> requestFreePlant({
    required String plantId,
    required Map<String, dynamic> plant,
  }) async {
    final user = _requireUser();
    final giverId = (plant['ownerId'] ?? '').toString();

    if (giverId.isEmpty) throw StateError('Plant owner is unavailable.');
    if (giverId == user.uid) throw StateError('You own this plant.');
    if (plant['isFree'] != true) {
      throw StateError(
        'Requests are currently available for free plants only.',
      );
    }

    final plantRef = _firestore.collection('plants').doc(plantId);
    final transferRef = _transfers.doc(transferId(plantId, user.uid));

    await _firestore.runTransaction((transaction) async {
      final plantSnapshot = await transaction.get(plantRef);
      if (!plantSnapshot.exists) throw StateError('Plant no longer exists.');

      final currentPlant = plantSnapshot.data()!;
      if (currentPlant['isFree'] != true ||
          currentPlant['status'] != 'Available') {
        throw StateError('This plant is no longer available.');
      }

      final existing = await transaction.get(transferRef);
      if (existing.exists) {
        final status = (existing.data()?['status'] ?? '').toString();
        if (status != 'cancelled' && status != 'rejected') {
          throw StateError('You have already requested this plant.');
        }
      }

      transaction.set(transferRef, <String, dynamic>{
        'plantId': plantId,
        'plantName': (currentPlant['name'] ?? 'Plant').toString(),
        'plantImage': (currentPlant['imageUrl'] ?? '').toString(),
        'giverId': giverId,
        'giverName': (currentPlant['ownerName'] ?? 'Plant owner').toString(),
        'receiverId': user.uid,
        'receiverName': (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : (user.email?.split('@').first ?? 'Plant receiver'),
        'status': 'requested',
        'giverConfirmed': false,
        'receiverConfirmed': false,
        'requestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': null,
      });
    });
  }

  Future<void> approveRequest(String transferId) async {
    final user = _requireUser();
    final transferRef = _transfers.doc(transferId);

    await _firestore.runTransaction((transaction) async {
      final transferSnapshot = await transaction.get(transferRef);
      if (!transferSnapshot.exists) throw StateError('Request not found.');

      final transfer = transferSnapshot.data()!;
      if (transfer['giverId'] != user.uid) {
        throw StateError('Only the plant owner can approve this request.');
      }
      if (transfer['status'] != 'requested') {
        throw StateError('This request has already been processed.');
      }

      final plantId = transfer['plantId'].toString();
      final receiverId = transfer['receiverId'].toString();
      final plantRef = _firestore.collection('plants').doc(plantId);
      final plantSnapshot = await transaction.get(plantRef);

      if (!plantSnapshot.exists ||
          plantSnapshot.data()?['ownerId'] != user.uid ||
          plantSnapshot.data()?['status'] != 'Available') {
        throw StateError('This plant is no longer available.');
      }

      transaction.update(transferRef, <String, dynamic>{
        'status': 'approved',
        'giverConfirmed': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(plantRef, <String, dynamic>{
        'status': 'Reserved',
        'approvedReceiverId': receiverId,
        'activeTransferId': transferId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRequest(String transferId) async {
    final user = _requireUser();
    final ref = _transfers.doc(transferId);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data()?['giverId'] != user.uid) {
      throw StateError('Only the plant owner can reject this request.');
    }
    await ref.update(<String, dynamic>{
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelRequest(String transferId) async {
    final user = _requireUser();
    final ref = _transfers.doc(transferId);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data()?['receiverId'] != user.uid) {
      throw StateError('You cannot cancel this request.');
    }
    if (snapshot.data()?['status'] != 'requested') {
      throw StateError('An approved request cannot be cancelled here.');
    }
    await ref.update(<String, dynamic>{
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmReceived(String transferId) async {
    final user = _requireUser();
    final transferRef = _transfers.doc(transferId);

    await _firestore.runTransaction((transaction) async {
      final transferSnapshot = await transaction.get(transferRef);
      if (!transferSnapshot.exists) throw StateError('Transfer not found.');

      final transfer = transferSnapshot.data()!;
      if (transfer['receiverId'] != user.uid) {
        throw StateError('Only the receiver can confirm this transfer.');
      }
      if (transfer['status'] != 'approved') {
        throw StateError('The owner has not approved this request yet.');
      }

      final plantRef = _firestore
          .collection('plants')
          .doc(transfer['plantId'].toString());
      final plantSnapshot = await transaction.get(plantRef);
      final plant = plantSnapshot.data();

      if (!plantSnapshot.exists ||
          plant?['activeTransferId'] != transferId ||
          plant?['approvedReceiverId'] != user.uid) {
        throw StateError('This transfer is no longer active.');
      }

      transaction.update(transferRef, <String, dynamic>{
        'status': 'completed',
        'receiverConfirmed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(plantRef, <String, dynamic>{
        'status': 'Given',
        'transferredTo': user.uid,
        'transferredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> incomingRequests(String giverId) {
    return _transfers.where('giverId', isEqualTo: giverId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> outgoingRequests(
    String receiverId,
  ) {
    return _transfers.where('receiverId', isEqualTo: receiverId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> transferForPlant(
    String plantId,
    String receiverId,
  ) {
    return _transfers.doc(transferId(plantId, receiverId)).snapshots();
  }

  Future<int> completedGivenCount(String uid) async {
    final result = await _transfers
        .where('giverId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<int> completedReceivedCount(String uid) async {
    final result = await _transfers
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .count()
        .get();
    return result.count ?? 0;
  }

  String giverBadge(int givenCount) {
    if (givenCount >= 50) return 'Green Champion';
    if (givenCount >= 25) return 'Plant Hero';
    if (givenCount >= 10) return 'Community Helper';
    if (givenCount >= 5) return 'Green Giver';
    if (givenCount >= 1) return 'First Giver';
    return 'New Gardener';
  }
}
