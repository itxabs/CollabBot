import 'package:supabase_flutter/supabase_flutter.dart';
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
      return true;
    } catch (e) {
      print('Error saving job: $e');
      return false;
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
