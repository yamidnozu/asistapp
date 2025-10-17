import 'package:flutter/foundation.dart';
import '../models/site.dart';
import '../models/job.dart';
import '../models/responsibility.dart';
import '../models/task.dart';
import '../services/catalog_service.dart';

class CatalogProvider with ChangeNotifier {
  final CatalogService _catalogService = CatalogService();

  List<Site> _sites = [];
  List<Job> _jobs = [];
  List<Responsibility> _responsibilities = [];
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Site> get sites => _sites;
  List<Job> get jobs => _jobs;
  List<Responsibility> get responsibilities => _responsibilities;
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> loadSites() async {
    try {
      _sites = await _catalogService.getSites();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando sites: $e');
    }
  }

  Future<void> loadJobs() async {
    try {
      _jobs = await _catalogService.getJobs();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando jobs: $e');
    }
  }

  Future<void> loadResponsibilities() async {
    try {
      _responsibilities = await _catalogService.getResponsibilities();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando responsibilities: $e');
    }
  }

  Future<void> loadTasks() async {
    try {
      _tasks = await _catalogService.getTasks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando tasks: $e');
    }
  }

  Future<void> loadAllCatalog() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadSites(),
      loadJobs(),
      loadResponsibilities(),
      loadTasks(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSite(Site site) async {
    await _catalogService.createSite(site);
    await loadSites();
  }

  Future<void> updateSite(String id, Map<String, dynamic> updates) async {
    await _catalogService.updateSite(id, updates);
    await loadSites();
  }

  Future<void> deleteSite(String id) async {
    await _catalogService.deleteSite(id);
    await loadSites();
  }

  // Similar methods for jobs, responsibilities, tasks
  Future<void> createJob(Job job) async {
    await _catalogService.createJob(job);
    await loadJobs();
  }

  Future<void> createResponsibility(Responsibility responsibility) async {
    await _catalogService.createResponsibility(responsibility);
    await loadResponsibilities();
  }

  Future<void> createTask(Task task) async {
    await _catalogService.createTask(task);
    await loadTasks();
  }
}