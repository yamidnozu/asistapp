import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/site.dart';
import '../models/job.dart';
import '../models/responsibility.dart';
import '../models/task.dart';

class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDemo() async {
    // Check if seeding is allowed
    final configDoc = await _firestore.collection('taskmonitoring').doc('config').get();
    if (configDoc.exists) {
      final config = configDoc.data();
      if (!(config?['allowSeed'] ?? false)) {
        throw Exception('Seeding not allowed');
      }
    }

    final batch = _firestore.batch();

    // Sites
    final sites = [
      Site(id: 'site1', name: 'Oficina Central', address: 'Calle Principal 123', active: true),
      Site(id: 'site2', name: 'Sucursal Norte', address: 'Avenida Norte 456', active: true),
    ];

    for (final site in sites) {
      final ref = _firestore.collection('taskmonitoring').doc('sites').collection('sites').doc(site.id);
      batch.set(ref, site.toJson());
    }

    // Jobs
    final jobs = [
      Job(id: 'job1', name: 'Gerente', description: 'Gestión general', siteIds: ['site1', 'site2']),
      Job(id: 'job2', name: 'Empleado', description: 'Trabajador general', siteIds: ['site1', 'site2']),
    ];

    for (final job in jobs) {
      final ref = _firestore.collection('taskmonitoring').doc('jobs').collection('jobs').doc(job.id);
      batch.set(ref, job.toJson());
    }

    // Responsibilities
    final responsibilities = [
      Responsibility(id: 'resp1', name: 'Limpieza', description: 'Mantener áreas limpias', jobIds: ['job2']),
      Responsibility(id: 'resp2', name: 'Reportes', description: 'Generar reportes diarios', jobIds: ['job1', 'job2']),
    ];

    for (final resp in responsibilities) {
      final ref = _firestore.collection('taskmonitoring').doc('responsibilities').collection('responsibilities').doc(resp.id);
      batch.set(ref, resp.toJson());
    }

    // Tasks
    final tasks = [
      Task(
        id: 'task1',
        title: 'Limpiar oficina',
        description: 'Limpiar mesas y pisos',
        responsibilityId: 'resp1',
        location: 'Oficina',
        evidenceRequired: true,
        durationMin: 30,
        priority: 'medium',
        recurrence: Recurrence(
          type: 'daily',
          times: ['09:00'],
          daysOfWeek: [1, 2, 3, 4, 5], // Lunes a Viernes
        ),
      ),
      Task(
        id: 'task2',
        title: 'Generar reporte diario',
        description: 'Crear reporte de actividades',
        responsibilityId: 'resp2',
        evidenceRequired: false,
        durationMin: 15,
        priority: 'high',
        recurrence: Recurrence(
          type: 'daily',
          times: ['17:00'],
          daysOfWeek: [1, 2, 3, 4, 5],
        ),
      ),
    ];

    for (final task in tasks) {
      final ref = _firestore.collection('taskmonitoring').doc('tasks').collection('tasks').doc(task.id);
      batch.set(ref, task.toJson());
    }

    await batch.commit();
  }

  Future<void> clearSeed() async {
    final collections = ['sites', 'jobs', 'responsibilities', 'tasks', 'assignments', 'logs'];

    for (final collection in collections) {
      final query = await _firestore.collection('taskmonitoring').doc(collection).collection(collection).get();
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> resetDatabase() async {
    // Get current superAdminUids
    final configDoc = await _firestore.collection('taskmonitoring').doc('config').get();
    List<String> superAdminUids = [];
    if (configDoc.exists) {
      final data = configDoc.data();
      superAdminUids = List<String>.from(data?['superAdminUids'] ?? []);
    }

    // Delete all subcollections
    final collections = ['sites', 'jobs', 'responsibilities', 'tasks', 'assignments', 'logs', 'users'];
    for (final collection in collections) {
      final query = await _firestore.collection('taskmonitoring').doc(collection).collection(collection).get();
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Recreate config
    await _firestore.collection('taskmonitoring').doc('config').set({
      'superAdminUids': superAdminUids,
      'allowSeed': true,
      'version': '1.0.0',
      'createdAt': Timestamp.now(),
    });
  }
}