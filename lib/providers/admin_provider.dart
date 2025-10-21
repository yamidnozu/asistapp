import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/assignment.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<User> _users = [];
  int _totalUsers = 0;
  int _activeAssignments = 0;
  int _completedToday = 0;
  bool _isLoading = false;

  List<User> get users => _users;
  int get totalUsers => _totalUsers;
  int get activeAssignments => _activeAssignments;
  int get completedToday => _completedToday;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      final query = await _firestore
          .collection('taskmonitoring')
          .doc('users')
          .collection('users')
          .get();

      _users = query.docs
          .map((doc) => User.fromJson(doc.data()..['uid'] = doc.id))
          .toList();

      _totalUsers = _users.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      // Load active assignments
      final activeQuery = await _firestore
          .collection('taskmonitoring')
          .doc('assignments')
          .collection('assignments')
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      _activeAssignments = activeQuery.docs.length;

      // Load completed today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final completedQuery = await _firestore
          .collection('taskmonitoring')
          .doc('assignments')
          .collection('assignments')
          .where('status', isEqualTo: 'done')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      _completedToday = completedQuery.docs.length;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  Future<void> updateUserRole(String userId, List<String> roles) async {
    try {
      await _firestore
          .collection('taskmonitoring')
          .doc('users')
          .collection('users')
          .doc(userId)
          .update({'roles': roles});

      // Update local list
      final index = _users.indexWhere((u) => u.uid == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(roles: roles);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating user role: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection('taskmonitoring')
          .doc('users')
          .collection('users')
          .doc(userId)
          .delete();

      // Remove from local list
      _users.removeWhere((u) => u.uid == userId);
      _totalUsers = _users.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  Future<void> resetDatabase() async {
    try {
      // This is a dangerous operation - only for super admins
      // Delete all collections except config
      final collections = ['users', 'tasks', 'assignments'];

      for (final collection in collections) {
        final query = await _firestore
            .collection('taskmonitoring')
            .doc(collection)
            .collection(collection)
            .get();

        for (final doc in query.docs) {
          await doc.reference.delete();
        }
      }

      // Reset local data
      _users.clear();
      _totalUsers = 0;
      _activeAssignments = 0;
      _completedToday = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }
  }
}