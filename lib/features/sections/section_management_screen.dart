import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/grade_model.dart';
import 'package:ibex_app/core/models/section_model.dart';
import 'package:ibex_app/core/services/grade_service.dart';
import 'package:ibex_app/core/services/section_service.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';

class SectionManagementScreen extends StatefulWidget {
  const SectionManagementScreen({super.key});

  @override
  State<SectionManagementScreen> createState() =>
      _SectionManagementScreenState();
}

class _SectionManagementScreenState extends State<SectionManagementScreen> {
  final _sectionService = SectionService();
  final _gradeService = GradeService();

  bool _isLoading = true;
  List<SectionModel> _sections = [];
  List<GradeModel> _grades = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _sectionService.getAllSections(),
        _gradeService.getAllGrades(),
      ]);
      if (mounted) {
        setState(() {
          _sections = results[0] as List<SectionModel>;
          _grades = results[1] as List<GradeModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sections: $e')),
        );
      }
    }
  }

  Future<void> _addSection(String name, String gradeId) async {
    try {
      await _sectionService.createSection(gradeId: gradeId, name: name);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating section: $e')),
        );
      }
    }
  }

  Future<void> _deleteSection(String id) async {
    try {
      await _sectionService.deleteSection(id);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Cannot delete section. It may contain existing classes.'),
          ),
        );
      }
    }
  }

  void _showAddSectionDialog() {
    if (_grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a Grade first.')),
      );
      return;
    }

    final controller = TextEditingController();
    String? selectedGradeId = _grades.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppConstants.surface,
            title: const Text(
              'Add New Section',
              style: TextStyle(color: AppConstants.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedGradeId,
                  dropdownColor: AppConstants.surface,
                  style: const TextStyle(color: AppConstants.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Select Grade',
                    labelStyle: TextStyle(color: AppConstants.textSecondary),
                    filled: true,
                    fillColor: AppConstants.surfaceLight,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  items: _grades.map((g) {
                    return DropdownMenuItem(
                      value: g.id,
                      child: Text(g.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedGradeId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: AppConstants.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Section Name (e.g. Tulip)',
                    hintStyle: TextStyle(color: AppConstants.textSecondary),
                    filled: true,
                    fillColor: AppConstants.surfaceLight,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ],
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
                  if (name.isNotEmpty && selectedGradeId != null) {
                    Navigator.pop(context);
                    _addSection(name, selectedGradeId!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primary,
                ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sections'),
        backgroundColor: AppConstants.surface,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading sections...')
          : _sections.isEmpty
              ? const EmptyStateWidget(
                  title: 'No sections found. Add one to get started.',
                  icon: Icons.view_list_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.pagePadding),
                    itemCount: _sections.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppConstants.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            section.name,
                            style: const TextStyle(
                              color: AppConstants.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Grade: ${section.gradeName ?? 'Unknown'}',
                            style: const TextStyle(
                                color: AppConstants.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppConstants.error),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppConstants.surface,
                                  title: const Text('Delete Section?',
                                      style: TextStyle(
                                          color: AppConstants.textPrimary)),
                                  content: Text(
                                    'Are you sure you want to delete ${section.name}? This action cannot be undone.',
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
                                        _deleteSection(section.id);
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
        onPressed: _showAddSectionDialog,
        backgroundColor: AppConstants.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
