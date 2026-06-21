import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';

class QuestionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<QuestionModel>> getQuestions() async {
    try {
      final response = await _client
          .from('questions')
          .select(
            '*, users(full_name, role), question_tags(tags(name)), answers(count)',
          )
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => QuestionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching questions: $e');
      return [];
    }
  }

  Future<List<QuestionModel>> getLatestQuestions({int limit = 5}) async {
    try {
      final response = await _client
          .from('questions')
          .select(
            '*, users(full_name, role), question_tags(tags(name)), answers(count)',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => QuestionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching latest questions: $e');
      return [];
    }
  }

  Future<void> incrementViewCount(String questionId) async {
    try {
      await _client.rpc('increment_view_count', params: {'row_id': questionId});
    } catch (e) {
      // If RPC fails, try manual update (less reliable)
      try {
        final resp = await _client
            .from('questions')
            .select('view_count')
            .eq('id', questionId)
            .single();
        final current = resp['view_count'] ?? 0;
        await _client
            .from('questions')
            .update({'view_count': current + 1})
            .eq('id', questionId);
      } catch (e2) {
        print('Error incrementing view count: $e2');
      }
    }
  }

  Future<List<AnswerModel>> getAnswers(String questionId) async {
    try {
      final response = await _client
          .from('answers')
          .select('*, users(full_name, role)')
          .eq('question_id', questionId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => AnswerModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching answers: $e');
      return [];
    }
  }

  Future<void> createQuestion(
    String authorId,
    String title,
    String content,
    List<String> tags,
  ) async {
    try {
      final result = await _client
          .from('questions')
          .insert({'author_id': authorId, 'title': title, 'content': content})
          .select()
          .single();

      final questionId = result['id'];

      // Assign tags
      for (final tag in tags) {
        // First check/create tag (if tags are uuid, this needs a lookup or upsert)
        final tagResult = await _client
            .from('tags')
            .upsert({'name': tag})
            .select()
            .single();
        final tagId = tagResult['id'];

        await _client.from('question_tags').insert({
          'question_id': questionId,
          'tag_id': tagId,
        });
      }
    } catch (e) {
      print('Error creating question: $e');
      rethrow;
    }
  }

  Future<void> postAnswer(
    String questionId,
    String authorId,
    String content,
  ) async {
    try {
      final response = await _client.from('answers').insert({
        'question_id': questionId,
        'author_id': authorId,
        'content': content,
      }).select('id').single();

      final answerId = response['id'];
      
      // Real-time Vectorization: Call Python Backend to generate embedding
      _vectorizeNewAnswer(answerId, content);

    } catch (e) {
      print('Error posting answer: $e');
      rethrow;
    }
  }

  /// Internal helper to notify Python backend about new content
  Future<void> _vectorizeNewAnswer(String answerId, String content) async {
    try {
      final String baseUrl = (Platform.isAndroid || Platform.isIOS) 
          ? 'http://192.168.1.5:8000' 
          : 'http://127.0.0.1:8000';

      final response = await http.post(
        Uri.parse('$baseUrl/ai/vectorize-answer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'answer_id': answerId,
          'content': content,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Real-time vectorization successful for answer $answerId');
      } else {
        print('Vectorization failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Vectorization trigger error: $e');
    }
  }

  Future<void> vote(
    String targetId,
    String userId,
    bool isQuestion,
    int voteValue,
  ) async {
    try {
      final targetField = isQuestion ? 'question_id' : 'answer_id';
      final table = isQuestion ? 'questions' : 'answers';

      final data = {
        'user_id': userId,
        targetField: targetId,
        'vote_value': voteValue,
      };

      await _client
          .from('votes')
          .upsert(data, onConflict: 'user_id, $targetField');

      final column = voteValue == 1 ? 'upvotes' : 'downvotes';
      try {
        await _client.rpc(
          'increment_score_v2',
          params: {
            'target_table': table,
            'target_id': targetId,
            'column_name': column,
            'amount': 1,
          },
        );
      } catch (e) {
        try {
          final response = await _client
              .from(table)
              .select(column)
              .eq('id', targetId)
              .single();
          final currentVal = response[column] ?? 0;
          await _client
              .from(table)
              .update({column: currentVal + 1})
              .eq('id', targetId);
        } catch (e2) {
          print('Direct update score failed as well: $e2');
        }
      }
    } catch (e) {
      print('Error voting: $e');
      rethrow;
    }
  }

  Future<void> deleteAnswer(String answerId) async {
    try {
      await _client.from('answers').delete().eq('id', answerId);
    } catch (e) {
      print('Error deleting answer: $e');
      rethrow;
    }
  }

  Future<void> updateAnswer(String answerId, String content) async {
    try {
      await _client
          .from('answers')
          .update({
            'content': content,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', answerId);
          
      // Keep embedding in sync with new content
      _vectorizeNewAnswer(answerId, content);
    } catch (e) {
      print('Error updating answer: $e');
      rethrow;
    }
  }
}
