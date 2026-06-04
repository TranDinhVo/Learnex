
/// Tất cả các event cho AuthBloc
abstract class AuthEvent {}

/// Kiểm tra trạng thái đăng nhập khi khởi động app
class CheckAuthEvent extends AuthEvent {}

/// Đăng nhập
class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  LoginEvent({required this.email, required this.password});
}

/// Đăng ký
class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String username;
  RegisterEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
  });
}

/// Đăng xuất
class LogoutEvent extends AuthEvent {}

/// Quên mật khẩu — gửi OTP
class ForgotPasswordEvent extends AuthEvent {
  final String email;
  ForgotPasswordEvent({required this.email});
}

/// Xác minh OTP
class VerifyOtpEvent extends AuthEvent {
  final String email;
  final String otp;
  VerifyOtpEvent({required this.email, required this.otp});
}

/// Đặt lại mật khẩu mới
class ResetPasswordEvent extends AuthEvent {
  final String resetToken;
  final String newPassword;
  ResetPasswordEvent({required this.resetToken, required this.newPassword});
}

/// Cập nhật profile
class UpdateProfileEvent extends AuthEvent {
  final String? fullName;
  final String? bio;
  final String? school;
  final String? major;
  UpdateProfileEvent({this.fullName, this.bio, this.school, this.major});
}

/// Upload avatar
class UploadAvatarEvent extends AuthEvent {
  final String filePath;
  UploadAvatarEvent({required this.filePath});
}
