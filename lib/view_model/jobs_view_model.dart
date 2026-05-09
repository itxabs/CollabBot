import 'package:flutter/material.dart';
import '../data/models/job_model.dart';
import '../data/repositories/job_repository.dart';

class JobsViewModel extends ChangeNotifier {
  final JobRepository _repository = JobRepository();
  
  List<JobModel> _allJobs = [];
  List<JobModel> _filteredJobs = [];
  List<JobModel> _savedJobs = [];
  List<JobModel> _myApplications = [];
  bool _isLoading = false;

  List<JobModel> get allJobs => _allJobs;
  List<JobModel> get filteredJobs => _filteredJobs;
  List<JobModel> get savedJobs => _savedJobs;
  List<JobModel> get myApplications => _myApplications;
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

  void filterJobs({String? query, String? location, String? type, List<String>? userSkills}) {
    _filteredJobs = _allJobs.where((job) {
      bool matchesQuery = true;
      if (query != null && query.isNotEmpty) {
        matchesQuery = job.title.toLowerCase().contains(query.toLowerCase()) || 
                       job.company.toLowerCase().contains(query.toLowerCase());
      }

      bool matchesLocation = true;
      if (location != null && location.isNotEmpty) {
        matchesLocation = job.location.toLowerCase().contains(location.toLowerCase());
      }

      bool matchesType = true;
      if (type != null && type != 'All') {
        matchesType = job.employmentType == type;
      }

      bool matchesSkills = true;
      if (userSkills != null && userSkills.isNotEmpty) {
        matchesSkills = job.skills.any((s) => userSkills.contains(s));
      }

      return matchesQuery && matchesLocation && matchesType && matchesSkills;
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

  Future<bool> checkIfApplied(String userId, String jobId) async {
    return await _repository.checkIfApplied(userId, jobId);
  }

  Future<bool> submitApplication({
    required JobModel job,
    required String userId,
    String? coverLetter,
    required String resumePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload Resume
      final resumeUrl = await _repository.uploadResume(userId, resumePath);
      if (resumeUrl == null) return false;

      // 2. Submit Application
      final success = await _repository.applyForJob(
        jobId: job.id,
        userId: userId,
        coverLetter: coverLetter,
        resumeUrl: resumeUrl,
      );

      if (success) {
        job.isApplied = true;
        job.applicationStatus = 'Pending';
        if (!_myApplications.any((j) => j.id == job.id)) {
          _myApplications.add(job);
        }
      }
      return success;
    } catch (e) {
      debugPrint('Error submitting application: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
