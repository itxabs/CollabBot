import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/chat_service.dart';

class NewChatViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ChatService _chatService;

  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> users = [];

  NewChatViewModel() {
    _chatService = ChatService(_supabase);
    loadUsers();
  }

  Future<void> loadUsers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User signed out');
      }
      users = await _chatService.searchUsers('', currentUser.id);
    } catch (e) {
      errorMessage = 'Failed to load users: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String value) async {
    isLoading = true;
    notifyListeners();
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('No current user');
      users = await _chatService.searchUsers(value, currentUser.id);
    } catch (e) {
      errorMessage = 'Search failed: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createChatWithUser(String otherUserId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not signed in');
    }
    return _chatService.createOrGetChat(currentUser.id, otherUserId);
  }
}
