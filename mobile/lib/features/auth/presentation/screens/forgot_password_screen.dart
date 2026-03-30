import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  static const _primary = Color(0xFF3525CD);
  static const _fieldFill = Color(0xFFEEF2FF);
  static const _bg = Color(0xFFF5F5FF);

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: _emailController.text)),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Logo centered
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'LearnEx',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Card content
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Lock icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.lock_outline, color: _primary, size: 32),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B4B),
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nhập email để nhận mã OTP xác\nnhận',
                          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 28),

                        // Email field label
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'EMAIL ĐĂNG KÝ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email không hợp lệ';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'example@learnex.edu.vn',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6366F1), size: 20),
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
                        ),
                        const SizedBox(height: 20),

                        // Send OTP button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Gửi mã OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Back to login
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, size: 14, color: _primary),
                                SizedBox(width: 4),
                                Text(
                                  'Quay lại đăng nhập',
                                  style: TextStyle(fontSize: 14, color: _primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Footer
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bảo mật', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
                      ),
                      Text('Hỗ trợ 24/7', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
                      ),
                      Text('LearnEx v2.4', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
