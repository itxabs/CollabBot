import 'package:collab_bot/data/models/user_model.dart';
import '../services/user_service.dart';


class UserRepository {
  final UserService _service = UserService();

  Future<UserModel?> getUserById(String userId) {
    return _service.fetchUser(userId);
  }
}
