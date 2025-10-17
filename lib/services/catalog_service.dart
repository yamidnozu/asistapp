import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/site.dart';
import '../models/job.dart';
import '../models/responsibility.dart';
import '../models/task.dart';

class CatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sites
  Future<List<Site>> getSites() async {
    final query = await _firestore.collection('taskmonitoring').doc('sites').collection('sites').get();
    return query.docs.map((doc) => Site.fromJson(doc.id, doc.data())).toList();
  }

  Future<void> createSite(Site site) async {
    await _firestore.collection('taskmonitoring').doc('sites').collection('sites').doc(site.id).set(site.toJson());
  }

  Future<void> updateSite(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('taskmonitoring').doc('sites').collection('sites').doc(id).update(updates);
  }

  Future<void> deleteSite(String id) async {
    await _firestore.collection('taskmonitoring').doc('sites').collection('sites').doc(id).delete();
  }

  // Jobs
  Future<List<Job>> getJobs() async {
    final query = await _firestore.collection('taskmonitoring').doc('jobs').collection('jobs').get();
    return query.docs.map((doc) => Job.fromJson(doc.id, doc.data())).toList();
  }

  Future<void> createJob(Job job) async {
    await _firestore.collection('taskmonitoring').doc('jobs').collection('jobs').doc(job.id).set(job.toJson());
  }

  Future<void> updateJob(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('taskmonitoring').doc('jobs').collection('jobs').doc(id).update(updates);
  }

  Future<void> deleteJob(String id) async {
    await _firestore.collection('taskmonitoring').doc('jobs').collection('jobs').doc(id).delete();
  }

  // Responsibilities
  Future<List<Responsibility>> getResponsibilities() async {
    final query = await _firestore.collection('taskmonitoring').doc('responsibilities').collection('responsibilities').get();
    return query.docs.map((doc) => Responsibility.fromJson(doc.id, doc.data())).toList();
  }

  Future<void> createResponsibility(Responsibility responsibility) async {
    await _firestore.collection('taskmonitoring').doc('responsibilities').collection('responsibilities').doc(responsibility.id).set(responsibility.toJson());
  }

  Future<void> updateResponsibility(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('taskmonitoring').doc('responsibilities').collection('responsibilities').doc(id).update(updates);
  }

  Future<void> deleteResponsibility(String id) async {
    await _firestore.collection('taskmonitoring').doc('responsibilities').collection('responsibilities').doc(id).delete();
  }

  // Tasks
  Future<List<Task>> getTasks() async {
    final query = await _firestore.collection('taskmonitoring').doc('tasks').collection('tasks').get();
    return query.docs.map((doc) => Task.fromJson(doc.id, doc.data())).toList();
  }

  Future<void> createTask(Task task) async {
    await _firestore.collection('taskmonitoring').doc('tasks').collection('tasks').doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('taskmonitoring').doc('tasks').collection('tasks').doc(id).update(updates);
  }

  Future<void> deleteTask(String id) async {
    await _firestore.collection('taskmonitoring').doc('tasks').collection('tasks').doc(id).delete();
  }
}