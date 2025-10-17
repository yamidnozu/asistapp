import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../services/assignment_service.dart';

class AssignmentProvider with ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();
  late Box<Assignment> _assignmentBox;

  List<Assignment> _assignments = [];
  bool _isLoading = false;

  List<Assignment> get assignments => _assignments;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _assignmentBox = await Hive.openBox<Assignment>('assignments');
  }

  Future<void> loadUserAssignments(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load from local storage first
      final localAssignments = _assignmentBox.values.where((a) => a.userId == userId).toList();
      if (localAssignments.isNotEmpty) {
        _assignments = localAssignments;
        notifyListeners();
      }

      // Sync with Firestore
      final remoteAssignments = await _assignmentService.getAssignmentsForUser(userId);
      
      // Update local storage
      await _assignmentBox.clear();
      for (final assignment in remoteAssignments) {
        await _assignmentBox.put(assignment.id, assignment);
      }

      _assignments = remoteAssignments;
    } catch (e) {
      debugPrint('Error cargando assignments: $e');
      // If remote fails, keep local data
      if (_assignments.isEmpty) {
        _assignments = _assignmentBox.values.where((a) => a.userId == userId).toList();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSiteAssignments(String siteId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _assignments = await _assignmentService.getAssignmentsForSite(siteId);
    } catch (e) {
      debugPrint('Error cargando assignments del sitio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAssignmentStatus(String assignmentId, String status, {String? blockedReason, String? userId}) async {
    try {
      await _assignmentService.updateAssignmentStatus(assignmentId, status, blockedReason: blockedReason, userId: userId);
      
      // Update local storage
      final assignment = _assignmentBox.get(assignmentId);
      if (assignment != null) {
        final updated = assignment.copyWith(
          status: status,
          blockedReason: blockedReason,
          lastUpdateAt: Timestamp.now(),
        );
        await _assignmentBox.put(assignmentId, updated);
        
        // Update in-memory list
        final index = _assignments.indexWhere((a) => a.id == assignmentId);
        if (index != -1) {
          _assignments[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error actualizando status: $e');
      // TODO: Queue for retry when online
    }
  }

  Future<void> updateAssignmentEvidence(String assignmentId, Evidence evidence, String userId) async {
    try {
      await _assignmentService.updateAssignmentEvidence(assignmentId, evidence, userId);
      
      // Update local storage
      final assignment = _assignmentBox.get(assignmentId);
      if (assignment != null) {
        final updated = assignment.copyWith(
          evidence: evidence,
          lastUpdateAt: Timestamp.now(),
        );
        await _assignmentBox.put(assignmentId, updated);
        
        // Update in-memory list
        final index = _assignments.indexWhere((a) => a.id == assignmentId);
        if (index != -1) {
          _assignments[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error actualizando evidencia: $e');
      // TODO: Queue for retry when online
    }
  }

  Stream<List<Assignment>> assignmentsStream(String userId) {
    return _assignmentService.assignmentsStream(userId);
  }

  Future<String> getTaskTitle(String taskId) async {
    try {
      final taskDoc = await FirebaseFirestore.instance
          .collection('taskmonitoring')
          .doc('config')
          .collection('tasks')
          .doc(taskId)
          .get();
      
      if (taskDoc.exists) {
        final taskData = taskDoc.data();
        return taskData?['title'] ?? 'Tarea sin título';
      }
      return 'Tarea no encontrada';
    } catch (e) {
      debugPrint('Error obteniendo título de tarea: $e');
      return 'Error cargando tarea';
    }
  }
}