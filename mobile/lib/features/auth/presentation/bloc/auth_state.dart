import '../../domain/entities/user.dart';

/// Tất cả các state cho AuthBloc
abstract class AuthState {}

/// Trạng thái ban đầu — chưa xác định
class AuthInitial extends AuthState {}

/// Đang tải (login, register, check auth, ...)
class AuthLoading extends AuthState {}

/// Đã xác thực — có thông tin user
class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

/// Chưa xác thực
class Unauthenticated extends AuthState {}

/// Lỗi xảy ra
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

/// Quên mật khẩu: đã gửi OTP thành công
class ForgotPasswordSent extends AuthState {
  final String email;
  ForgotPasswordSent(this.email);
}

/// OTP đã xác minh thành công, có resetToken
class OtpVerified extends AuthState {
  final String resetToken;
  OtpVerified(this.resetToken);
}

/// Đặt lại mật khẩu thành công
class PasswordResetSuccess extends AuthState {}

/// Cập nhật profile thành công
class ProfileUpdated extends AuthState {
  final User user;
  ProfileUpdated(this.user);
}
