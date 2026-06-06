import 'package:flutter/material.dart';
import '../data/models/job_model.dart';
import '../data/repositories/job_repository.dart';

class JobsViewModel extends ChangeNotifier {
  final JobRepository _repository = JobRepository();
  
  List<JobModel> _allJobs = [];
  List<JobModel> _filteredJobs = [];
  List<JobModel> _savedJobs = [];
  bool _isLoading = false;

  List<JobModel> get allJobs => _allJobs;
  List<JobModel> get filteredJobs => _filteredJobs;
  List<JobModel> get savedJobs => _savedJobs;
  bool get isLoading => _isLoading;

  JobsViewModel() {
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dbJobs = await _repository.getJobs();
      _allJobs = dbJobs;
      _filteredJobs = List.from(_allJobs);
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterJobs({String? query}) {
    _filteredJobs = _allJobs.where((job) {
      bool matchesQuery = true;
      if (query != null && query.isNotEmpty) {
        matchesQuery = job.title.toLowerCase().contains(query.toLowerCase());
      }
      return matchesQuery;
    }).toList();
    notifyListeners();
  }

  void toggleSaveJob(JobModel job) {
    job.isSaved = !job.isSaved;
    if (job.isSaved) {
      if (!_savedJobs.any((j) => j.id == job.id)) {
        _savedJobs.add(job);
      }
    } else {
      _savedJobs.removeWhere((j) => j.id == job.id);
    }
    notifyListeners();
  }

  Future<bool> createJob(JobModel job) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _repository.postJob(job);
      if (success) {
        await fetchJobs();
      }
      return success;
    } catch (e) {
      debugPrint('Error creating job: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
