import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../models/task.dart';
import '../models/log.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Assignment>> getAssignmentsForUser(String userId, {int limit = 50, DocumentSnapshot? startAfter}) async {
    Query query = _firestore
        .collection('taskmonitoring')
        .doc('assignments')
        .collection('assignments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Assignment.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Future<List<Assignment>> getAssignmentsForSite(String siteId, {int limit = 50, DocumentSnapshot? startAfter}) async {
    Query query = _firestore
        .collection('taskmonitoring')
        .doc('assignments')
        .collection('assignments')
        .where('siteId', isEqualTo: siteId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Assignment.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> createAssignment(Assignment assignment) async {
    final docRef = _firestore.collection('taskmonitoring').doc('assignments').collection('assignments').doc();
    final assignmentWithId = assignment.copyWith(id: docRef.id);
    await docRef.set(assignmentWithId.toJson());

    // Log creation
    await _logAction(assignmentWithId.userId, docRef.id, 'create', {'taskId': assignment.taskId});
  }

  Future<void> updateAssignmentStatus(String assignmentId, String status, {String? blockedReason, String? userId}) async {
    final updates = {'status': status, 'lastUpdateAt': Timestamp.now()};
    if (blockedReason != null) {
      updates['blockedReason'] = blockedReason;
    }

    await _firestore.collection('taskmonitoring').doc('assignments').collection('assignments').doc(assignmentId).update(updates);

    // Log status change
    if (userId != null) {
      await _logAction(userId, assignmentId, 'status_change', {'newStatus': status, 'blockedReason': blockedReason});
    }
  }

  Future<void> updateAssignmentEvidence(String assignmentId, Evidence evidence, String userId) async {
    await _firestore.collection('taskmonitoring').doc('assignments').collection('assignments').doc(assignmentId).update({
      'evidence': evidence.toJson(),
      'lastUpdateAt': Timestamp.now(),
    });

    // Log evidence upload
    await _logAction(userId, assignmentId, 'evidence_upload', {'storagePath': evidence.storagePath});
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _firestore.collection('taskmonitoring').doc('assignments').collection('assignments').doc(assignmentId).delete();
  }

  // Generate assignments from task template for users
  Future<void> generateAssignmentsFromTask(Task task, List<String> userIds, String siteId) async {
    final batch = _firestore.batch();

    for (final userId in userIds) {
      final assignmentId = _firestore.collection('taskmonitoring').doc('assignments').collection('assignments').doc().id;
      final assignment = Assignment(
        id: assignmentId,
        userId: userId,
        taskId: task.id,
        siteId: siteId,
        schedule: Schedule(
          times: task.recurrence.times,
          daysOfWeek: task.recurrence.daysOfWeek,
          dateRange: task.recurrence.dateRange,
        ),
        status: 'pending',
      );

      final docRef = _firestore.collection('taskmonitoring').doc('assignments').collection('assignments').doc(assignmentId);
      batch.set(docRef, assignment.toJson());
    }

    await batch.commit();
  }

  Future<void> _logAction(String userId, String assignmentId, String action, Map<String, dynamic>? metadata) async {
    final logId = _firestore.collection('taskmonitoring').doc('logs').collection('logs').doc().id;
    final log = Log(
      id: logId,
      userId: userId,
      assignmentId: assignmentId,
      action: action,
      metadata: metadata,
    );

    await _firestore.collection('taskmonitoring').doc('logs').collection('logs').doc(logId).set(log.toJson());
  }

  Stream<List<Assignment>> assignmentsStream(String userId) {
    return _firestore
        .collection('taskmonitoring')
        .doc('assignments')
        .collection('assignments')
        .where('userId', isEqualTo: userId)
        .orderBy('lastUpdateAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Assignment.fromJson(doc.id, doc.data())).toList());
  }
}