import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../models/job_model.dart';

class JobRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<JobModel>> getJobs() async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('*, poster:users!fk_jobs_creator(full_name), status_info:job_statuses!fk_jobs_status(name)')
          .eq('status_id', 2) // 2 = Approved
          .order('created_at', ascending: false);

      return (response as List).map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching jobs: $e');
      return [];
    }
  }

  Future<bool> saveJob(String userId, String jobId) async {
    try {
      // Assuming a 'saved_jobs' table exists or would be created
      // If it doesn't exist, this will fail. For now, we'll return true to simulate success in mock mode
      /*
      await _supabase.from('saved_jobs').insert({
        'user_id': userId,
        'job_id': jobId,
      });
      */
      return true;
    } catch (e) {
      print('Error saving job: $e');
      return false;
    }
  }

  Future<bool> checkIfApplied(String userId, String jobId) async {
    try {
      final response = await _supabase
          .from('job_applications')
          .select('id')
          .eq('user_id', userId)
          .eq('job_id', jobId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking application status: $e');
      return false;
    }
  }

  Future<String?> uploadResume(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final fileExt = path.extension(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final storagePath = 'resumes/$userId/$fileName';

      await _supabase.storage.from('resumes').upload(storagePath, file);
      
      return _supabase.storage.from('resumes').getPublicUrl(storagePath);
    } catch (e) {
      print('Error uploading resume: $e');
      return null;
    }
  }

  Future<bool> applyForJob({
    required String jobId,
    required String userId,
    String? coverLetter,
    required String resumeUrl,
  }) async {
    try {
      await _supabase.from('job_applications').insert({
        'job_id': jobId,
        'user_id': userId,
        'cover_letter': coverLetter,
        'resume_url': resumeUrl,
        'status': 'Pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error applying for job: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMyApplications(String userId) async {
    try {
      final response = await _supabase
          .from('job_applications')
          .select('*, jobs(*, poster:users!fk_jobs_creator(full_name))')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching applications: $e');
      return [];
    }
  }

  Future<bool> postJob(JobModel job) async {
    try {
      await _supabase.from('jobs').insert(job.toJson());
      return true;
    } catch (e) {
      print('Error posting job: $e');
      return false;
    }
  }
}
