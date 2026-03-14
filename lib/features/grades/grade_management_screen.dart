import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/grade_model.dart';
import 'package:ibex_app/core/services/grade_service.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  final _gradeService = GradeService();
  bool _isLoading = true;
  List<GradeModel> _grades = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _gradeService.getAllGrades();
      if (mounted) {
        setState(() {
          _grades = grades;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grades: $e')),
        );
      }
    }
  }

  Future<void> _addGrade(String name) async {
    try {
      await _gradeService.createGrade(name);
      _loadGrades();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating grade: $e')),
        );
      }
    }
  }

  Future<void> _deleteGrade(String id) async {
    try {
      await _gradeService.deleteGrade(id);
      _loadGrades();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cannot delete grade. It may contain existing sections/classes.'),
          ),
        );
      }
    }
  }

  void _showAddGradeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surface,
        title: const Text(
          'Add New Grade',
          style: TextStyle(color: AppConstants.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppConstants.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. Grade 11',
            hintStyle: TextStyle(color: AppConstants.textSecondary),
            filled: true,
            fillColor: AppConstants.surfaceLight,
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                _addGrade(name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primary,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Grades'),
        backgroundColor: AppConstants.surface,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading grades...')
          : _grades.isEmpty
              ? const EmptyStateWidget(
                  title: 'No grades found. Add one to get started.',
                  icon: Icons.school_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadGrades,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.pagePadding),
                    itemCount: _grades.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final grade = _grades[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppConstants.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            grade.name,
                            style: const TextStyle(
                              color: AppConstants.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppConstants.error),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppConstants.surface,
                                  title: const Text('Delete Grade?',
                                      style: TextStyle(
                                          color: AppConstants.textPrimary)),
                                  content: Text(
                                    'Are you sure you want to delete ${grade.name}? This action cannot be undone.',
                                    style: const TextStyle(
                                        color: AppConstants.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel',
                                          style: TextStyle(
                                              color:
                                                  AppConstants.textSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteGrade(grade.id);
                                      },
                                      child: const Text('Delete',
                                          style: TextStyle(
                                              color: AppConstants.error)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGradeDialog,
        backgroundColor: AppConstants.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
