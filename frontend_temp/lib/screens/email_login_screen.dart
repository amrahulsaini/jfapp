import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../config/theme.dart';
import '../config/api_constants.dart';
import '../widgets/jf_logo.dart';
import '../widgets/loading_button.dart';
import 'otp_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedBatch = ApiConstants.activeBatch;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isJecrcEmail(String email) {
    return email.toLowerCase().endsWith(ApiConstants.allowedEmailDomain);
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Call API to send OTP
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Navigate to OTP screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OTPScreen(
          email: _emailController.text.trim(),
          batch: _selectedBatch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // JF Logo
                const JFLogo(size: 100),
                
                const SizedBox(height: 50),
                
                // Welcome Text
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in with your JECRC email',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'your.name@jecrc.ac.in',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!EmailValidator.validate(value)) {
                      return 'Please enter a valid email';
                    }
                    if (!_isJecrcEmail(value)) {
                      return 'Please use your JECRC email (@jecrc.ac.in)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Batch Selection
                DropdownButtonFormField<String>(
                  value: _selectedBatch,
                  decoration: const InputDecoration(
                    labelText: 'Batch',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: ApiConstants.availableBatches.map((batch) {
                    final isActive = batch == ApiConstants.activeBatch;
                    return DropdownMenuItem(
                      value: batch,
                      enabled: isActive,
                      child: Row(
                        children: [
                          Text(
                            batch,
                            style: TextStyle(
                              color: isActive ? AppTheme.textPrimary : AppTheme.textHint,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (!isActive) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(Coming Soon)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedBatch = value);
                    }
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Send OTP Button
                LoadingButton(
                  text: 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: _handleSendOTP,
                  backgroundColor: AppTheme.primaryColor,
                  textColor: AppTheme.secondaryColor,
                ),
                
                const SizedBox(height: 24),
                
                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'An OTP will be sent to your JECRC email address. Your session will be saved for 30 days.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
