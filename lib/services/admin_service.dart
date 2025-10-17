import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> assignRoles(String uid, List<String> roles) async {
    await _firestore.collection('taskmonitoring').doc('users').collection('users').doc(uid).update({
      'roles': roles,
    });
  }

  Future<void> assignSites(String uid, List<String> sites) async {
    await _firestore.collection('taskmonitoring').doc('users').collection('users').doc(uid).update({
      'sites': sites,
    });
  }

  Future<void> setUserStatus(String uid, String status) async {
    await _firestore.collection('taskmonitoring').doc('users').collection('users').doc(uid).update({
      'status': status,
    });
  }

  Future<List<String>> getSuperAdminUids() async {
    final doc = await _firestore.collection('taskmonitoring').doc('config').get();
    if (doc.exists) {
      final data = doc.data();
      return List<String>.from(data?['superAdminUids'] ?? []);
    }
    return [];
  }

  Future<void> addSuperAdmin(String uid) async {
    final current = await getSuperAdminUids();
    if (!current.contains(uid)) {
      current.add(uid);
      await _firestore.collection('taskmonitoring').doc('config').update({
        'superAdminUids': current,
      });
    }
  }

  Future<void> removeSuperAdmin(String uid) async {
    final current = await getSuperAdminUids();
    current.remove(uid);
    await _firestore.collection('taskmonitoring').doc('config').update({
      'superAdminUids': current,
    });
  }
}