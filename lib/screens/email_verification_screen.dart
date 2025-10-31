import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/user_details.dart';
import '../services/email_verification_service.dart';
import 'LoginActivity.dart';
import '../l10n/app_localizations.dart';
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({Key? key, required this.email})
      : super(key: key);

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _verificationService = EmailVerificationService();
  bool _isLoading = false;
  String? _errorMessage;

  // ✅ Email validation function
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ Check email validity first
      if (!_isValidEmail(widget.email)) {
        setState(() {
          _errorMessage = 'Invalid email format. Please enter a valid email.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final sent =
        await _verificationService.sendVerificationEmail(widget.email);
        print("UserDetails.emailCode: ${UserDetails.emailCode}");

        if (!mounted) return;

        if (!sent) {
          setState(() {
            _errorMessage =
            'Failed to send verification email. You can try resending.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'An error occurred. Please try again.';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _verificationService.verifyEmailCode(
        widget.email,
        _codeController.text,
      );

      if (!mounted) return;

      if (success) {
        // ✅ Show confirmation message before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.email_verified_success),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Wait for the snackbar to finish before navigating
        await Future.delayed(const Duration(seconds: 2));

        // ✅ Navigate to LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid verification code';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    print("UserDetails.emailCode: ${UserDetails.emailCode}");
    // ✅ Validate email again before resending
    if (!_isValidEmail(widget.email)) {
      setState(() {
        _errorMessage = 'Invalid email format. Please enter a valid email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success =
      await _verificationService.sendVerificationEmail(widget.email);
      if (!mounted) return;

      if (!success) {
        setState(() {
          _errorMessage = 'Failed to send verification code';
        });
        ScaffoldMessenger.of(context as BuildContext)
            .showSnackBar(SnackBar(content: Text('Error: Failed to send email')));
      }
      else
        {
          ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            SnackBar(
              content:
              Text('Confirmation email sent successfully!'),
            ),
          );
        }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Please enter the verification code sent to:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification code';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify'),
              ),
              TextButton(
                onPressed: _isLoading ? null : _resendCode,
                child: const Text('Resend Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
