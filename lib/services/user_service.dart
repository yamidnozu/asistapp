import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> ensureUserDocOnFirstLogin(User user) async {
    final docRef = _firestore.collection('taskmonitoring').doc('users').collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      // Check if this is the first user (database is empty)
      final usersCollection = _firestore.collection('taskmonitoring').doc('users').collection('users');
      final existingUsers = await usersCollection.limit(1).get();
      
      bool isFirstUser = existingUsers.docs.isEmpty;
      
      // Create user with appropriate role
      final userWithRole = user.copyWith(
        roles: isFirstUser ? ['super_admin'] : ['employee'],
      );
      
      await docRef.set(userWithRole.toJson());
      
      // If this is the first user, create config document
      if (isFirstUser) {
        await _createInitialConfig(user.uid);
      }
    }
  }

  Future<void> _createInitialConfig(String firstUserUid) async {
    final configRef = _firestore.collection('taskmonitoring').doc('config');
    final configDoc = await configRef.get();
    
    if (!configDoc.exists) {
      await configRef.set({
        'superAdminUids': [firstUserUid],
        'allowSeed': true,
        'version': '1.0.0',
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<User?> getUser(String uid) async {
    final doc = await _firestore.collection('taskmonitoring').doc('users').collection('users').doc(uid).get();
    if (doc.exists) {
      return User.fromJson(doc.data()!..['uid'] = uid);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    await _firestore.collection('taskmonitoring').doc('users').collection('users').doc(uid).update(updates);
  }

  Stream<User?> userStream(String uid) {
    return _firestore.collection('taskmonitoring').doc('users').collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return User.fromJson(doc.data()!..['uid'] = uid);
      }
      return null;
    });
  }

  Future<List<User>> getAllUsers() async {
    final query = await _firestore.collection('taskmonitoring').doc('users').collection('users').get();
    return query.docs.map((doc) => User.fromJson(doc.data()..['uid'] = doc.id)).toList();
  }
}