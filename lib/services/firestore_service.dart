import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTask(String userId, Task task) async {
    await _firestore.collection('users').doc(userId).collection('tasks').doc(task.id).set({
      'title': task.title,
      'description': task.description,
      'isCompleted': task.isCompleted,
      'createdAt': task.createdAt,
      'dueDate': task.dueDate,
    });
  }

  Future<void> updateTask(String userId, Task task) async {
    await _firestore.collection('users').doc(userId).collection('tasks').doc(task.id).update({
      'title': task.title,
      'description': task.description,
      'isCompleted': task.isCompleted,
      'dueDate': task.dueDate,
    });
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _firestore.collection('users').doc(userId).collection('tasks').doc(taskId).delete();
  }

  Stream<List<Task>> getTasks(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return Task(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          isCompleted: data['isCompleted'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
        );
      }).toList(),
    );
  }
}