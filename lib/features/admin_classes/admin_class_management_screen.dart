import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/class_model.dart';
import 'package:ibex_app/core/models/grade_model.dart';
import 'package:ibex_app/core/models/section_model.dart';
import 'package:ibex_app/core/models/user_model.dart';
import 'package:ibex_app/core/services/class_service.dart';
import 'package:ibex_app/core/services/grade_service.dart';
import 'package:ibex_app/core/services/section_service.dart';
import 'package:ibex_app/core/services/user_service.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';

class AdminClassManagementScreen extends StatefulWidget {
  const AdminClassManagementScreen({super.key});

  @override
  State<AdminClassManagementScreen> createState() =>
      _AdminClassManagementScreenState();
}

class _AdminClassManagementScreenState
    extends State<AdminClassManagementScreen> {
  final _classService = ClassService();
  final _gradeService = GradeService();
  final _sectionService = SectionService();
  final _userService = UserService();

  bool _isLoading = true;
  bool _isLoadingClasses = false;

  List<GradeModel> _grades = [];
  List<SectionModel> _allSections = [];
  List<UserModel> _teachers = [];

  GradeModel? _selectedGrade;
  SectionModel? _selectedSection;
  List<ClassModel> _classes = [];

  List<SectionModel> get _filteredSections {
    if (_selectedGrade == null) return [];
    return _allSections.where((s) => s.gradeId == _selectedGrade!.id).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _gradeService.getAllGrades(),
        _sectionService.getAllSections(),
        _userService.getUsersByRole('teacher'),
      ]);

      if (mounted) {
        setState(() {
          _grades = results[0] as List<GradeModel>;
          _allSections = results[1] as List<SectionModel>;
          _teachers = (results[2] as List<UserModel>)
            ..sort((a, b) => a.name.compareTo(b.name));

          if (_grades.isNotEmpty) {
            _selectedGrade = _grades.first;
            if (_filteredSections.isNotEmpty) {
              _selectedSection = _filteredSections.first;
              _loadClasses();
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedSection == null) {
      setState(() => _classes = []);
      return;
    }

    setState(() => _isLoadingClasses = true);
    try {
      final classes =
          await _classService.getClassesBySection(_selectedSection!.id);
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading classes: $e')),
        );
      }
    }
  }

  Future<void> _addClass(String subjectName, String teacherId) async {
    if (_selectedSection == null) return;
    try {
      await _classService.createClass(
        sectionId: _selectedSection!.id,
        subjectName: subjectName,
        teacherId: teacherId,
      );
      _loadClasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating class: $e')),
        );
      }
    }
  }

  Future<void> _deleteClass(String id) async {
    try {
      await _classService.deleteClass(id);
      _loadClasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Cannot delete class. It may have existing enrollments or assignments.'),
          ),
        );
      }
    }
  }

  void _showAddClassDialog() {
    if (_selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a grade and section first.')),
      );
      return;
    }

    if (_teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No teachers exist yet. Add a teacher account to create classes.')),
      );
      return;
    }

    final controller = TextEditingController();
    String? selectedTeacherId = _teachers.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppConstants.surface,
            title: const Text(
              'Add New Class',
              style: TextStyle(color: AppConstants.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Adding to: ${_selectedGrade?.name} - ${_selectedSection?.name}',
                  style: const TextStyle(
                      color: AppConstants.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: AppConstants.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Subject Name (e.g. Mathematics)',
                    hintStyle: TextStyle(color: AppConstants.textSecondary),
                    filled: true,
                    fillColor: AppConstants.surfaceLight,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTeacherId,
                  dropdownColor: AppConstants.surface,
                  style: const TextStyle(color: AppConstants.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Assign Teacher',
                    labelStyle: TextStyle(color: AppConstants.textSecondary),
                    filled: true,
                    fillColor: AppConstants.surfaceLight,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  items: _teachers.map((t) {
                    return DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedTeacherId = val;
                    });
                  },
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
                  if (name.isNotEmpty && selectedTeacherId != null) {
                    Navigator.pop(context);
                    _addClass(name, selectedTeacherId!);
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
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading hierarchy...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes'),
        backgroundColor: AppConstants.surface,
      ),
      body: Column(
        children: [
          // Hierarchy Selectors
          Container(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            color: AppConstants.surfaceLight,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.school,
                        color: AppConstants.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<GradeModel>(
                        value: _selectedGrade,
                        dropdownColor: AppConstants.surface,
                        isExpanded: true,
                        style: const TextStyle(color: AppConstants.textPrimary),
                        underline: const SizedBox(),
                        hint: const Text('Select Grade',
                            style: TextStyle(color: AppConstants.textSecondary)),
                        items: _grades.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(g.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGrade = val;
                              _selectedSection = _filteredSections.isNotEmpty
                                  ? _filteredSections.first
                                  : null;
                            });
                            _loadClasses();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppConstants.surfaceLight),
                Row(
                  children: [
                    const Icon(Icons.class_,
                        color: AppConstants.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<SectionModel>(
                        value: _selectedSection,
                        dropdownColor: AppConstants.surface,
                        isExpanded: true,
                        style: const TextStyle(color: AppConstants.textPrimary),
                        underline: const SizedBox(),
                        hint: const Text('Select Section',
                            style: TextStyle(color: AppConstants.textSecondary)),
                        items: _filteredSections.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSection = val;
                            });
                            _loadClasses();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Class List
          Expanded(
            child: _selectedSection == null
                ? const EmptyStateWidget(
                    title: 'Select a section to view its classes.',
                    icon: Icons.list,
                  )
                : _isLoadingClasses
                    ? const Center(child: CircularProgressIndicator())
                    : _classes.isEmpty
                        ? const EmptyStateWidget(
                            title: 'No classes in this section yet.',
                            icon: Icons.menu_book,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadClasses,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(
                                  AppConstants.pagePadding),
                              itemCount: _classes.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final cls = _classes[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppConstants.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      cls.subjectName,
                                      style: const TextStyle(
                                        color: AppConstants.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Teacher: ${cls.teacherName ?? 'Unassigned'} • Code: ${cls.classCode}',
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
                                            backgroundColor:
                                                AppConstants.surface,
                                            title: const Text('Delete Class?',
                                                style: TextStyle(
                                                    color: AppConstants
                                                        .textPrimary)),
                                            content: Text(
                                              'Are you sure you want to delete ${cls.subjectName}? This action cannot be undone.',
                                              style: const TextStyle(
                                                  color: AppConstants
                                                      .textSecondary),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel',
                                                    style: TextStyle(
                                                        color: AppConstants
                                                            .textSecondary)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteClass(cls.id);
                                                },
                                                child: const Text('Delete',
                                                    style: TextStyle(
                                                        color: AppConstants
                                                            .error)),
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
          ),
        ],
      ),
      floatingActionButton: _selectedSection != null
          ? FloatingActionButton.extended(
              onPressed: _showAddClassDialog,
              backgroundColor: AppConstants.primary,
              icon: const Icon(Icons.add),
              label: const Text('New Class'),
            )
          : null,
    );
  }
}
