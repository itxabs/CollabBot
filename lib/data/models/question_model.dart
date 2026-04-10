import 'package:intl/intl.dart';

class QuestionModel {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final DateTime createdAt;
  final int viewCount;
  final int upvotes;
  final int downvotes;
  final bool isSolved;
  final List<String> tags;
  final int answerCount;

  QuestionModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.viewCount = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isSolved = false,
    this.tags = const [],
    this.answerCount = 0,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['users']?['full_name'] ?? 'Unknown User',
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at']),
      viewCount: json['view_count'] ?? 0,
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      isSolved: json['is_solved'] ?? false,
      tags:
          (json['question_tags'] as List?)
              ?.map((t) => t['tags']['name'].toString())
              .toList() ??
          [],
      answerCount: json['answers']?[0]?['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_id': authorId,
      'title': title,
      'content': content,
      'is_solved': isSolved,
    };
  }

  String get formattedDate => DateFormat.yMMMd().format(createdAt);
  String get formattedTime => DateFormat('h:mm a').format(createdAt);
  int get score => upvotes - downvotes;
}

class AnswerModel {
  final String id;
  final String questionId;
  final String authorId;
  final String authorName;
  final String content;
  final bool isAccepted;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;

  AnswerModel({
    required this.id,
    required this.questionId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.isAccepted = false,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.createdAt,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['users']?['full_name'] ?? 'Unknown User',
      content: json['content'] as String,
      isAccepted: json['is_accepted'] ?? false,
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'author_id': authorId,
      'content': content,
      'is_accepted': isAccepted,
    };
  }

  String get formattedDate => DateFormat.yMMMd().format(createdAt);
  String get formattedTime => DateFormat('h:mm a').format(createdAt);
  int get score => upvotes - downvotes;
}
