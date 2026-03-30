abstract class AuthRepository {
  Future<bool> login(String username, String password);
  Future<bool> register(String email, String username, String password);
}
