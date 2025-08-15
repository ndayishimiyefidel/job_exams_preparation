import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/questions_service.dart';
import '../../core/services/exams_service.dart';
import '../../data/models/question_model.dart';
import '../../data/models/exam_model.dart';
import '../../core/services/notification_service.dart';

class QuestionsManagementWidget extends StatefulWidget {
  final String? externalSearchQuery;
  final VoidCallback? onSearchChanged;

  const QuestionsManagementWidget({
    super.key,
    this.externalSearchQuery,
    this.onSearchChanged,
  });

  @override
  State<QuestionsManagementWidget> createState() =>
      _QuestionsManagementWidgetState();
}

class _QuestionsManagementWidgetState extends State<QuestionsManagementWidget> {
  // Questions data
  List<QuestionModel> _questions = [];
  List<ExamModel> _allExams = [];
  bool _isLoadingQuestions = false;
  String _questionSearchQuery = '';
  int _questionCurrentPage = 1;
  int _questionTotalPages = 1;
  int _questionTotalRecords = 0;
  final int _questionsPerPage = 10;
  Timer? _questionSearchDebounceTimer;
  late TextEditingController _questionSearchController;
  int _selectedExamFilter = 0;
  Map<int, int> _examTotalMarks = {}; // Store total marks for each exam

  @override
  void initState() {
    super.initState();
    _questionSearchController = TextEditingController();
    _loadAllExams();
    _loadQuestions();
  }

  @override
  void didUpdateWidget(QuestionsManagementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalSearchQuery != oldWidget.externalSearchQuery) {
      _questionSearchQuery = widget.externalSearchQuery ?? '';
      _questionSearchController.text = _questionSearchQuery;
      _loadQuestions(resetPage: true);
    }
  }

  @override
  void dispose() {
    _questionSearchDebounceTimer?.cancel();
    _questionSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllExams() async {
    try {
      final result = await ExamsService.getExams(page: 1, limit: 1000);
      setState(() {
        _allExams = result.exams;
      });
    } catch (e) {
      print('Error loading all exams: $e');
    }
  }

  Future<void> _loadQuestions({bool resetPage = false}) async {
    if (resetPage) {
      _questionCurrentPage = 1;
    }

    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      final result = await QuestionsService.getQuestions(
        page: _questionCurrentPage,
        limit: _questionsPerPage,
        search: _questionSearchQuery,
        examId: _selectedExamFilter,
      );

      // Calculate total marks for each exam
      Map<int, int> examTotalMarks = {};
      for (var question in result.questions) {
        examTotalMarks[question.examId] =
            (examTotalMarks[question.examId] ?? 0) + question.questionMarks;
      }

      setState(() {
        _questions = result.questions;
        _questionTotalPages = result.totalPages;
        _questionTotalRecords = result.totalRecords;
        _examTotalMarks = examTotalMarks;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingQuestions = false;
      });
      NotificationService.showError(
        context: context,
        message: 'Failed to load questions: $e',
      );
    }
  }

  void _onQuestionSearchChanged(String value) {
    _questionSearchQuery = value;
    widget.onSearchChanged?.call();
    _questionSearchDebounceTimer?.cancel();
    _questionSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadQuestions(resetPage: true);
    });
  }

  void _clearQuestionSearch() {
    _questionSearchQuery = '';
    _questionSearchController.clear();
    _loadQuestions(resetPage: true);
  }

  void _onExamFilterChanged(int? examId) {
    setState(() {
      _selectedExamFilter = examId ?? 0;
    });
    _loadQuestions(resetPage: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoadingQuestions
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading questions...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : _questions.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Expanded(child: _buildQuestionsList()),
                        const SizedBox(height: 16),
                        _buildPaginationControls(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 768;

        if (isSmallScreen) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Questions Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedExamFilter > 0
                    ? 'Filtered questions • $_questionTotalRecords questions found'
                    : 'Manage exam questions • $_questionTotalRecords total questions',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              if (_selectedExamFilter > 0 &&
                  _examTotalMarks.containsKey(_selectedExamFilter))
                Text(
                  'Total marks: ${_examTotalMarks[_selectedExamFilter]}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 16),
              // Exam filter dropdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedExamFilter == 0 ? null : _selectedExamFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Exam',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('All Exams'),
                    ),
                    ..._allExams.map((exam) => DropdownMenuItem<int>(
                          value: exam.id,
                          child: Text(
                            exam.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )),
                  ],
                  onChanged: _onExamFilterChanged,
                  isExpanded: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_selectedExamFilter > 0) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _onExamFilterChanged(null);
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddQuestionDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showBulkUploadDialog(),
                icon: const Icon(Icons.upload_file),
                label: const Text('Bulk Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Questions Management',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedExamFilter > 0
                            ? 'Filtered questions • $_questionTotalRecords questions found'
                            : 'Manage exam questions • $_questionTotalRecords total questions',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      if (_selectedExamFilter > 0 &&
                          _examTotalMarks.containsKey(_selectedExamFilter))
                        Text(
                          'Total marks: ${_examTotalMarks[_selectedExamFilter]}',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showAddQuestionDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showBulkUploadDialog(),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Bulk Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Filter row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;

                  if (isSmallScreen) {
                    // Stack vertically on small screens
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonFormField<int>(
                            value: _selectedExamFilter == 0
                                ? null
                                : _selectedExamFilter,
                            decoration: const InputDecoration(
                              labelText: 'Filter by Exam',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 16),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('All Exams'),
                              ),
                              ..._allExams.map((exam) => DropdownMenuItem<int>(
                                    value: exam.id,
                                    child: Text(
                                      exam.title,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  )),
                            ],
                            onChanged: _onExamFilterChanged,
                            isExpanded: true,
                          ),
                        ),
                        if (_selectedExamFilter > 0) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _onExamFilterChanged(null);
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear Filters'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  } else {
                    // Use row layout on larger screens
                    return Row(
                      children: [
                        // Exam filter dropdown
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: _selectedExamFilter == 0
                                  ? null
                                  : _selectedExamFilter,
                              decoration: const InputDecoration(
                                labelText: 'Filter by Exam',
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 16),
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('All Exams'),
                                ),
                                ..._allExams
                                    .map((exam) => DropdownMenuItem<int>(
                                          value: exam.id,
                                          child: Text(
                                            exam.title,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        )),
                              ],
                              onChanged: _onExamFilterChanged,
                              isExpanded: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_selectedExamFilter > 0)
                          OutlinedButton.icon(
                            onPressed: () {
                              _onExamFilterChanged(null);
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Filters'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                },
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _questionSearchQuery.isNotEmpty;
    final isFiltering = _selectedExamFilter > 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.question_answer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No questions found' : 'No questions found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No questions match your search "${_questionSearchQuery}"'
                : isFiltering
                    ? 'No questions found for the selected exam'
                    : 'Create your first question to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          if (isSearching) ...[
            OutlinedButton.icon(
              onPressed: _clearQuestionSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddQuestionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showBulkUploadDialog(),
                icon: const Icon(Icons.upload_file),
                label: const Text('Bulk Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView.builder(
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        return _buildQuestionCard(question);
      },
    );
  }

  Widget _buildQuestionCard(QuestionModel question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with exam info and actions
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 500;

                if (isSmallScreen) {
                  // Stack vertically on small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.question_answer,
                                color: AppColors.info, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question.examTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                                ),
                                Text(
                                  question.positionTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _showEditQuestionDialog(question),
                            icon: Icon(Icons.edit, color: AppColors.warning),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showDeleteQuestionDialog(question),
                            icon: Icon(Icons.delete, color: AppColors.error),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Use row layout on larger screens
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.question_answer,
                            color: AppColors.info, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.examTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                            Text(
                              question.positionTitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showEditQuestionDialog(question),
                            icon: Icon(Icons.edit, color: AppColors.warning),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showDeleteQuestionDialog(question),
                            icon: Icon(Icons.delete, color: AppColors.error),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            // Question text with marks
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;

                if (isSmallScreen) {
                  // Stack vertically on small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text(
                          '${question.questionMarks} mark${question.questionMarks > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Use row layout on larger screens
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          question.questionText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text(
                          '${question.questionMarks} mark${question.questionMarks > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            // Choices
            ...question.choices.asMap().entries.map((entry) {
              final index = entry.key;
              final choice = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: choice.isCorrect
                      ? AppColors.success.withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: choice.isCorrect
                        ? AppColors.success
                        : Colors.grey[300]!,
                    width: choice.isCorrect ? 2 : 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 350;

                    if (isSmallScreen) {
                      // Stack vertically on very small screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: choice.isCorrect
                                      ? AppColors.success
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(
                                        65 + index), // A, B, C, D, E
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (choice.isCorrect)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            choice.choiceText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: choice.isCorrect
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: choice.isCorrect
                                  ? AppColors.success
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Use row layout on larger screens
                      return Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: choice.isCorrect
                                  ? AppColors.success
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(
                                    65 + index), // A, B, C, D, E
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              choice.choiceText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: choice.isCorrect
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: choice.isCorrect
                                    ? AppColors.success
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          if (choice.isCorrect)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                        ],
                      );
                    }
                  },
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            // Footer info
            Text(
              'Created: ${question.createdAt}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_questionTotalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          if (isSmallScreen) {
            return Column(
              children: [
                Text(
                  'Showing ${_questions.length} of $_questionTotalRecords questions',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _questionCurrentPage > 1
                          ? () {
                              setState(() {
                                _questionCurrentPage--;
                              });
                              _loadQuestions();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: _questionCurrentPage > 1
                          ? AppColors.info
                          : Colors.grey[400],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_questionCurrentPage / $_questionTotalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _questionCurrentPage < _questionTotalPages
                          ? () {
                              setState(() {
                                _questionCurrentPage++;
                              });
                              _loadQuestions();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: _questionCurrentPage < _questionTotalPages
                          ? AppColors.info
                          : Colors.grey[400],
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_questions.length} of $_questionTotalRecords questions',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _questionCurrentPage > 1
                          ? () {
                              setState(() {
                                _questionCurrentPage--;
                              });
                              _loadQuestions();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: _questionCurrentPage > 1
                          ? AppColors.info
                          : Colors.grey[400],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_questionCurrentPage / $_questionTotalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _questionCurrentPage < _questionTotalPages
                          ? () {
                              setState(() {
                                _questionCurrentPage++;
                              });
                              _loadQuestions();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: _questionCurrentPage < _questionTotalPages
                          ? AppColors.info
                          : Colors.grey[400],
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // Dialog methods
  void _showAddQuestionDialog() {
    final questionController = TextEditingController();
    final marksController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    int selectedExamId = _allExams.isNotEmpty ? _allExams.first.id : 0;
    List<Map<String, dynamic>> choices = [
      {'choice_text': '', 'is_correct': false},
      {'choice_text': '', 'is_correct': false},
      {'choice_text': '', 'is_correct': false},
      {'choice_text': '', 'is_correct': false},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width *
                (MediaQuery.of(context).size.width < 768 ? 0.95 : 0.6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width < 768
                  ? double.infinity
                  : 800,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.info.withOpacity(0.05),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.info,
                          AppColors.info.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Question',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create a new question with multiple choice answers',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exam Selection
                          const Text(
                            'Select Exam *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonFormField<int>(
                              value:
                                  selectedExamId == 0 ? null : selectedExamId,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 16),
                              ),
                              items: _allExams
                                  .map((exam) => DropdownMenuItem<int>(
                                        value: exam.id,
                                        child: Text(
                                          exam.title,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedExamId = value ?? 0;
                                });
                              },
                              validator: (value) {
                                if (value == null || value == 0) {
                                  return 'Please select an exam';
                                }
                                return null;
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Question Text
                          const Text(
                            'Question Text *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: questionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter your question here...',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.info),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter question text';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Question Marks
                          const Text(
                            'Question Marks *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: marksController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter marks (default: 1)',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.info),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter marks';
                              }
                              final marks = int.tryParse(value);
                              if (marks == null || marks < 1) {
                                return 'Marks must be a positive number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Choices Section
                          Row(
                            children: [
                              const Text(
                                'Answer Choices *',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  if (choices.length < 5) {
                                    setDialogState(() {
                                      choices.add({
                                        'choice_text': '',
                                        'is_correct': false
                                      });
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add_circle,
                                    color: AppColors.info),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (choices.length > 2) {
                                    setDialogState(() {
                                      choices.removeLast();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.remove_circle,
                                    color: AppColors.error),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Choices List
                          ...choices.asMap().entries.map((entry) {
                            final index = entry.key;
                            final choice = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: choice['is_correct']
                                      ? AppColors.success
                                      : Colors.grey[300]!,
                                  width: choice['is_correct'] ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Choice letter
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: choice['is_correct']
                                          ? AppColors.success
                                          : Colors.grey[400],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Choice text
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: choice['choice_text'],
                                      decoration: InputDecoration(
                                        hintText:
                                            'Enter choice ${String.fromCharCode(65 + index)}',
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8),
                                      ),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          choices[index]['choice_text'] = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Choice cannot be empty';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Correct answer toggle
                                  Switch(
                                    value: choice['is_correct'],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        // Set all other choices to false
                                        for (int i = 0;
                                            i < choices.length;
                                            i++) {
                                          choices[i]['is_correct'] =
                                              (i == index && value);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.success,
                                  ),
                                  Text(
                                    'Correct',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: choice['is_correct']
                                          ? AppColors.success
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: Colors.grey[400]!),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      // Validate that exactly one choice is correct
                                      int correctCount = choices
                                          .where((c) => c['is_correct'] == true)
                                          .length;
                                      if (correctCount != 1) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please select exactly one correct answer'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        await QuestionsService.createQuestion(
                                          examId: selectedExamId,
                                          questionText:
                                              questionController.text.trim(),
                                          questionMarks: int.parse(
                                              marksController.text.trim()),
                                          choices: choices,
                                        );
                                        Navigator.of(context).pop();
                                        _loadQuestions();
                                        NotificationService.showSuccess(
                                          context: context,
                                          message:
                                              'Question created successfully! 📝',
                                        );
                                      } catch (e) {
                                        NotificationService.showError(
                                          context: context,
                                          message:
                                              'Failed to create question: $e',
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor:
                                        AppColors.info.withOpacity(0.3),
                                  ),
                                  child: const Text(
                                    'Create Question',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditQuestionDialog(QuestionModel question) {
    final questionController =
        TextEditingController(text: question.questionText);
    final marksController =
        TextEditingController(text: question.questionMarks.toString());
    final formKey = GlobalKey<FormState>();
    int selectedExamId = question.examId;
    List<Map<String, dynamic>> choices = question.choices
        .map((choice) => {
              'choice_text': choice.choiceText,
              'is_correct': choice.isCorrect,
            })
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width *
                (MediaQuery.of(context).size.width < 768 ? 0.95 : 0.6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width < 768
                  ? double.infinity
                  : 800,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.warning.withOpacity(0.05),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning,
                          AppColors.warning.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Question',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Update question and answer choices',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exam Selection
                          const Text(
                            'Select Exam *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: selectedExamId,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 16),
                              ),
                              items: _allExams
                                  .map((exam) => DropdownMenuItem<int>(
                                        value: exam.id,
                                        child: Text(
                                          exam.title,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedExamId = value ?? 0;
                                });
                              },
                              validator: (value) {
                                if (value == null || value == 0) {
                                  return 'Please select an exam';
                                }
                                return null;
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Question Text
                          const Text(
                            'Question Text *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: questionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter your question here...',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: AppColors.warning),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter question text';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Question Marks
                          const Text(
                            'Question Marks *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: marksController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter marks (default: 1)',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: AppColors.warning),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter marks';
                              }
                              final marks = int.tryParse(value);
                              if (marks == null || marks < 1) {
                                return 'Marks must be a positive number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Choices Section
                          Row(
                            children: [
                              const Text(
                                'Answer Choices *',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  if (choices.length < 5) {
                                    setDialogState(() {
                                      choices.add({
                                        'choice_text': '',
                                        'is_correct': false
                                      });
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add_circle,
                                    color: AppColors.warning),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (choices.length > 2) {
                                    setDialogState(() {
                                      choices.removeLast();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.remove_circle,
                                    color: AppColors.error),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Choices List
                          ...choices.asMap().entries.map((entry) {
                            final index = entry.key;
                            final choice = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: choice['is_correct']
                                      ? AppColors.success
                                      : Colors.grey[300]!,
                                  width: choice['is_correct'] ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Choice letter
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: choice['is_correct']
                                          ? AppColors.success
                                          : Colors.grey[400],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Choice text
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: choice['choice_text'],
                                      decoration: InputDecoration(
                                        hintText:
                                            'Enter choice ${String.fromCharCode(65 + index)}',
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8),
                                      ),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          choices[index]['choice_text'] = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Choice cannot be empty';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Correct answer toggle
                                  Switch(
                                    value: choice['is_correct'],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        // Set all other choices to false
                                        for (int i = 0;
                                            i < choices.length;
                                            i++) {
                                          choices[i]['is_correct'] =
                                              (i == index && value);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.success,
                                  ),
                                  Text(
                                    'Correct',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: choice['is_correct']
                                          ? AppColors.success
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: Colors.grey[400]!),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      // Validate that exactly one choice is correct
                                      int correctCount = choices
                                          .where((c) => c['is_correct'] == true)
                                          .length;
                                      if (correctCount != 1) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please select exactly one correct answer'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        await QuestionsService.updateQuestion(
                                          id: question.id,
                                          examId: selectedExamId,
                                          questionText:
                                              questionController.text.trim(),
                                          questionMarks: int.parse(
                                              marksController.text.trim()),
                                          choices: choices,
                                        );
                                        Navigator.of(context).pop();
                                        _loadQuestions();
                                        NotificationService.showSuccess(
                                          context: context,
                                          message:
                                              'Question updated successfully! ✏️',
                                        );
                                      } catch (e) {
                                        NotificationService.showError(
                                          context: context,
                                          message:
                                              'Failed to update question: $e',
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.warning,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor:
                                        AppColors.warning.withOpacity(0.3),
                                  ),
                                  child: const Text(
                                    'Update Question',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteQuestionDialog(QuestionModel question) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width *
              (MediaQuery.of(context).size.width < 768 ? 0.9 : 0.4),
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width < 768 ? double.infinity : 500,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.error.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error,
                      AppColors.error.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_forever,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Question',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This action cannot be undone',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Are you sure you want to delete this question?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.questionText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Exam: ${question.examTitle}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Choices: ${question.choices.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await QuestionsService.deleteQuestion(
                                    question.id);
                                Navigator.of(context).pop();
                                _loadQuestions();
                                NotificationService.showSuccess(
                                  context: context,
                                  message: 'Question deleted successfully! 🗑️',
                                );
                              } catch (e) {
                                NotificationService.showError(
                                  context: context,
                                  message: 'Failed to delete question: $e',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.error.withOpacity(0.3),
                            ),
                            child: const Text(
                              'Delete Question',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkUploadDialog() {
    int selectedExamId = _allExams.isNotEmpty ? _allExams.first.id : 0;
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width *
                (MediaQuery.of(context).size.width < 768 ? 0.9 : 0.5),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width < 768
                  ? double.infinity
                  : 600,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.upload_file,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bulk Upload Questions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload CSV file with multiple questions',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exam Selection
                        const Text(
                          'Select Exam *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonFormField<int>(
                            value: selectedExamId == 0 ? null : selectedExamId,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            items: _allExams
                                .map((exam) => DropdownMenuItem<int>(
                                      value: exam.id,
                                      child: Text(
                                        exam.title,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedExamId = value ?? 0;
                              });
                            },
                            validator: (value) {
                              if (value == null || value == 0) {
                                return 'Please select an exam';
                              }
                              return null;
                            },
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // File Upload
                        const Text(
                          'Upload CSV File *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedFile != null
                                  ? AppColors.success
                                  : Colors.grey[300]!,
                              width: selectedFile != null ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                selectedFile != null
                                    ? Icons.check_circle
                                    : Icons.cloud_upload,
                                size: 32,
                                color: selectedFile != null
                                    ? AppColors.success
                                    : Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                selectedFile != null
                                    ? 'File selected'
                                    : 'Click to select CSV file',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: selectedFile != null
                                      ? AppColors.success
                                      : Colors.grey[600],
                                ),
                              ),
                              if (selectedFile != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  selectedFile!.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final result =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['csv'],
                                    );
                                    if (result != null) {
                                      setDialogState(() {
                                        selectedFile = result.files.single;
                                      });
                                    }
                                  } catch (e) {
                                    print("FilePicker Error: $e");
                                    NotificationService.showError(
                                      context: context,
                                      message: 'Failed to pick file: $e',
                                    );
                                  }
                                },
                                icon: Icon(selectedFile != null
                                    ? Icons.refresh
                                    : Icons.file_upload),
                                label: Text(selectedFile != null
                                    ? 'Change File'
                                    : 'Select File'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // CSV Format Instructions
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.info.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info,
                                      color: AppColors.info, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CSV Format Instructions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'CSV should have columns: question_text, choice_a, choice_b, choice_c, choice_d, choice_e, correct_answer, marks\n'
                                'Example: "What is 2+2?",4,5,6,7,A,2\n'
                                'question_text: The text of the question\n'
                                'choice_a, choice_b, choice_c, choice_d, choice_e: The answer choices\n'
                                'correct_answer: The correct answer choice (A, B, C, D, or E)\n'
                                'marks: Number of marks for this question (optional, defaults to 1)\n'
                                'Note: All questions will be added to the selected exam above',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selectedFile != null &&
                                        selectedExamId > 0
                                    ? () async {
                                        try {
                                          final result = await QuestionsService
                                              .uploadBulkQuestions(
                                            examId: selectedExamId,
                                            file: selectedFile!,
                                          );
                                          Navigator.of(context).pop();
                                          _loadQuestions();
                                          NotificationService.showSuccess(
                                            context: context,
                                            message:
                                                '${result['questions_added']} questions uploaded successfully! 📁',
                                          );
                                        } catch (e) {
                                          NotificationService.showError(
                                            context: context,
                                            message:
                                                'Failed to upload questions: $e',
                                          );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  shadowColor:
                                      AppColors.warning.withOpacity(0.3),
                                ),
                                child: const Text(
                                  'Upload Questions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
