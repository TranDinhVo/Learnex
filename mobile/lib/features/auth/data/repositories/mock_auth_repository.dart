import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<bool> login(String username, String password) async {
    // Giả lập thời gian load mạng
    await Future.delayed(const Duration(seconds: 1)); 
    
    // Giả lập logic kiểm tra
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ thông tin');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải từ 6 ký tự trở lên');
    }
    
    // Mặc định cho phép qua mọi tài khoản hợp lệ để dễ test
    return true; 
  }

  @override
  Future<bool> register(String email, String username, String password) async {
    // Giả lập thời gian load mạng
    await Future.delayed(const Duration(seconds: 1));
    
    if (!email.contains('@')) {
      throw Exception('Email không hợp lệ');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu quá yếu');
    }
    
    return true;
  }
}
