import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../models/task.dart';

class AssignmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Assignment> _assignments = [];
  bool _isLoading = false;

  List<Assignment> get assignments => _assignments;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadUserAssignments(String userId) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      final query = await _firestore
          .collection('taskmonitoring')
          .doc('assignments')
          .collection('assignments')
          .where('userId', isEqualTo: userId)
          .get();

      _assignments = query.docs
          .map((doc) => Assignment.fromJson(doc.id, doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading assignments: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAssignmentStatus(String assignmentId, String status, {String? userId}) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status,
      };

      if (status == 'in_progress' && userId != null) {
        updateData['startedAt'] = Timestamp.now();
      } else if (status == 'done') {
        updateData['completedAt'] = Timestamp.now();
      }

      await _firestore
          .collection('taskmonitoring')
          .doc('assignments')
          .collection('assignments')
          .doc(assignmentId)
          .update(updateData);

      // Update local list
      final index = _assignments.indexWhere((a) => a.id == assignmentId);
      if (index != -1) {
        final updatedAssignment = _assignments[index].copyWith(
          status: status,
          startedAt: status == 'in_progress' ? DateTime.now() : _assignments[index].startedAt,
          completedAt: status == 'done' ? DateTime.now() : _assignments[index].completedAt,
        );
        _assignments[index] = updatedAssignment;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating assignment status: $e');
    }
  }

  Future<void> updateAssignmentEvidence(String assignmentId, Evidence evidence, String userId) async {
    try {
      await _firestore
          .collection('taskmonitoring')
          .doc('assignments')
          .collection('assignments')
          .doc(assignmentId)
          .update({
            'evidence': evidence.toJson(),
          });

      // Update local list
      final index = _assignments.indexWhere((a) => a.id == assignmentId);
      if (index != -1) {
        _assignments[index] = _assignments[index].copyWith(evidence: evidence);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating assignment evidence: $e');
    }
  }

  Future<String> getTaskTitle(String taskId) async {
    try {
      final doc = await _firestore
          .collection('taskmonitoring')
          .doc('tasks')
          .collection('tasks')
          .doc(taskId)
          .get();

      if (doc.exists) {
        final task = Task.fromJson(taskId, doc.data()!);
        return task.title;
      }
      return taskId;
    } catch (e) {
      debugPrint('Error getting task title: $e');
      return taskId;
    }
  }

  Future<void> createAssignment(String taskId, String userId) async {
    try {
      final assignmentRef = _firestore
          .collection('taskmonitoring')
          .doc('assignments')
          .collection('assignments')
          .doc();

      final assignment = Assignment(
        id: assignmentRef.id,
        taskId: taskId,
        userId: userId,
        status: 'pending',
        assignedAt: DateTime.now(),
      );

      await assignmentRef.set(assignment.toJson());

      // Add to local list
      _assignments.add(assignment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating assignment: $e');
    }
  }
}