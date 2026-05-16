import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> submitReport(ReportModel report) async {
    try {
      await _client.from('reports').insert(report.toMap());
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }

  // Get reports for a specific user (optional, for profile screen or admin check)
  Future<List<ReportModel>> getReportsForUser(String userId) async {
    try {
      final response = await _client
          .from('reports')
          .select()
          .eq('target_user_id', userId);
      
      return (response as List).map((data) => ReportModel.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching reports: $e');
      rethrow;
    }
  }
}
