import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';

class EvidenceService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }

  Future<String> uploadEvidence(String assignmentId, XFile image) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp.jpg';
    final path = 'taskmonitoring/evidence/$assignmentId/$fileName';
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putFile(File(image.path));
    final snapshot = await uploadTask.whenComplete(() => null);
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> updateAssignmentWithEvidence(String assignmentId, String downloadUrl, String userId) async {
    final evidence = Evidence(
      storagePath: 'taskmonitoring/evidence/$assignmentId/',
      url: downloadUrl,
      takenAt: Timestamp.now(),
    );

    // Update assignment
    await FirebaseFirestore.instance
        .collection('taskmonitoring')
        .doc('assignments')
        .collection('assignments')
        .doc(assignmentId)
        .update({
          'evidence': evidence.toJson(),
          'lastUpdateAt': Timestamp.now(),
        });

    // Log action
    final logId = FirebaseFirestore.instance.collection('taskmonitoring').doc('logs').collection('logs').doc().id;
    await FirebaseFirestore.instance.collection('taskmonitoring').doc('logs').collection('logs').doc(logId).set({
      'userId': userId,
      'assignmentId': assignmentId,
      'action': 'evidence_upload',
      'at': Timestamp.now(),
      'metadata': {'storagePath': evidence.storagePath},
    });
  }
}