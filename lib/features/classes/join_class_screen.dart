import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/services/class_service.dart';
import 'package:ibex_app/core/services/enrollment_service.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _codeController = TextEditingController();
  final _classService = ClassService();
  final _enrollmentService = EnrollmentService();
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinClass() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a class code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      // Look up class by code
      final classModel = await _classService.getClassByCode(code);
      if (classModel == null) {
        setState(() {
          _error = 'No class found with code "$code"';
          _isLoading = false;
        });
        return;
      }

      // Check if already enrolled
      final isEnrolled = await _enrollmentService.isEnrolled(classModel.id);
      if (isEnrolled) {
        setState(() {
          _error = 'You are already enrolled in this class';
          _isLoading = false;
        });
        return;
      }

      // Enroll
      await _enrollmentService.enrollInClass(classModel.id);

      if (mounted) {
        setState(() {
          _successMessage = 'Successfully joined ${classModel.displayTitle}!';
          _isLoading = false;
        });
        // Navigate to class after a brief delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/classes/${classModel.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Class')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Enter Class Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your teacher for the class code, then enter it here to join.',
              style: TextStyle(fontSize: 14, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 24),
            // Code field
            const Text(
              'CLASS CODE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: AppConstants.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'ABC123',
                hintStyle: TextStyle(letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 16),

            // Error/Success message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppConstants.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppConstants.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppConstants.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: AppConstants.success,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            _isLoading
                ? const LoadingWidget()
                : ElevatedButton(
                    onPressed: _joinClass,
                    child: const Text('Join Class'),
                  ),
          ],
        ),
      ),
    );
  }
}
