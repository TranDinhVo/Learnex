import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC xử lý toàn bộ luồng xác thực.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImpl _repository;

  AuthBloc({required AuthRepositoryImpl repository})
      : _repository = repository,
        super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResetPasswordEvent>(_onResetPassword);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadAvatarEvent>(_onUploadAvatar);
  }

  /// Kiểm tra token lưu sẵn → tự động đăng nhập nếu có
  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final hasToken = await _repository.hasStoredToken();
      if (hasToken) {
        final user = await _repository.getMe();
        getIt<WebSocketService>().connect();
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      getIt<WebSocketService>().connect();
      emit(Authenticated(user));
    } on DioException catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Đăng nhập thất bại. Vui lòng thử lại.'));
    }
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        username: event.username,
      );
      getIt<WebSocketService>().connect();
      emit(Authenticated(user));
    } on DioException catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Đăng ký thất bại. Vui lòng thử lại.'));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    getIt<WebSocketService>().disconnect();
    await _repository.logout();
    emit(Unauthenticated());
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _repository.forgotPassword(email: event.email);
      emit(ForgotPasswordSent(event.email));
    } on DioException catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Không thể gửi OTP. Vui lòng thử lại.'));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final resetToken = await _repository.verifyOtp(
        email: event.email,
        otp: event.otp,
      );
      emit(OtpVerified(resetToken));
    } on DioException catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError('OTP không hợp lệ. Vui lòng thử lại.'));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _repository.resetPassword(
        resetToken: event.resetToken,
        newPassword: event.newPassword,
      );
      emit(PasswordResetSuccess());
    } on DioException catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Đặt lại mật khẩu thất bại.'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.updateProfile(
        fullName: event.fullName,
        bio: event.bio,
        school: event.school,
        major: event.major,
      );
      emit(ProfileUpdated(user));
    } on DioException catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Cập nhật thất bại.'));
    }
  }

  Future<void> _onUploadAvatar(
    UploadAvatarEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.uploadAvatar(event.filePath);
      emit(ProfileUpdated(user));
    } on DioException catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError('Upload avatar thất bại.'));
    }
  }

  /// Trích xuất message lỗi từ DioException
  String _extractErrorMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'Đã có lỗi xảy ra';
      }
    } catch (_) {}
    return e.message ?? 'Đã có lỗi xảy ra';
  }
}
