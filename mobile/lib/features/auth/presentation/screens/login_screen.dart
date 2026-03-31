import 'package:flutter/material.dart';
import '../../data/repositories/mock_auth_repository.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final MockAuthRepository _authRepository = MockAuthRepository();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _primary = Color(0xFF4F46E5);
  static const _fieldFill = Color(0xFFEEF2FF);

  static const _bg = Color(0xFFF5F5FF);

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final success = await _authRepository.login(
        _emailController.text,
        _passwordController.text,
      );
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FeedScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 12),
                const Text(
                  'LearnEx',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chào mừng bạn trở lại với không gian học tập.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // EMAIL field
                _buildFieldLabel('EMAIL'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailController,
                  hint: 'example@learnex.vn',
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email không hợp lệ';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // PASSWORD field
                _buildFieldLabel('MẬT KHẨU'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscure: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Remember me + Forgot password
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        activeColor: _primary,
                        side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 13, color: Color(0xFF374151))),
                    const Spacer(),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(fontSize: 13, color: _primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Đăng nhập  →',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: Color(0xFFE5E7EB))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'HOẶC TIẾP TỤC VỚI',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Color(0xFFE5E7EB))),
                  ],
                ),

                const SizedBox(height: 16),

                // Social buttons
                Row(
                  children: [
                    Expanded(child: _buildSocialButton('Google', '🇬')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSocialButton('Facebook', 'f')),
                  ],
                ),

                const SizedBox(height: 28),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản?', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    const SizedBox(width: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(fontSize: 14, color: _primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Footer
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hỗ trợ', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF)))),
                    Text('Điều khoản', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF)))),
                    Text('Bảo mật', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: _fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC7D2FE), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC7D2FE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildSocialButton(String label, String emoji) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji == 'f'
                ? '🇫'
                : emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}