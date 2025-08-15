import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/positions_service.dart';
import '../../../core/services/exams_service.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../data/models/position_model.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../../../data/models/activity_log_model.dart';
import '../../widgets/questions_management_widget.dart';
import '../../widgets/profile_management_widget.dart';
import '../../../core/services/notification_service.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _selectedSection = 0;
  bool _isSidebarCollapsed = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Positions data
  List<PositionModel> _positions = [];
  bool _isLoadingPositions = false;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  final int _positionsPerPage = 10;
  Timer? _searchDebounceTimer;
  late TextEditingController _searchController;

  // Exams data
  List<ExamModel> _exams = [];
  List<PositionModel> _allPositions = [];
  bool _isLoadingExams = false;
  String _examSearchQuery = '';
  int _examCurrentPage = 1;
  int _examTotalPages = 1;
  int _examTotalRecords = 0;
  final int _examsPerPage = 10;
  Timer? _examSearchDebounceTimer;
  late TextEditingController _examSearchController;
  int _selectedPositionFilter = 0;

  // Questions state
  String _questionSearchQuery = '';
  late TextEditingController _questionSearchController;
  Timer? _questionSearchDebounceTimer;

  // Dashboard data
  DashboardStatsModel? _dashboardStats;
  List<ActivityLogModel> _recentActivities = [];
  bool _isLoadingDashboard = false;
  String _dashboardSearchQuery = '';
  Timer? _dashboardSearchDebounceTimer;
  late TextEditingController _dashboardSearchController;

  final List<Map<String, dynamic>> _sections = [
    {'title': 'Overview', 'icon': Icons.dashboard, 'color': AppColors.primary},
    {'title': 'Positions', 'icon': Icons.work, 'color': AppColors.success},
    {'title': 'Exams', 'icon': Icons.quiz, 'color': AppColors.warning},
    {
      'title': 'Questions',
      'icon': Icons.question_answer,
      'color': AppColors.info
    },
    // {'title': 'Users', 'icon': Icons.people, 'color': AppColors.error},
    // {'title': 'Analytics', 'icon': Icons.analytics, 'color': Colors.purple},
    {'title': 'Profile', 'icon': Icons.person, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _searchController = TextEditingController();
    _examSearchController = TextEditingController();
    _questionSearchController = TextEditingController();
    _dashboardSearchController = TextEditingController();
    _loadPositions();
    _loadAllPositions();
    _loadDashboardData();

    // Auto-hide sidebar on small screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth < 768) {
        setState(() {
          _isSidebarCollapsed = true;
        });
        print(
            '🔄 [SIDEBAR] Auto-hiding sidebar on small screen: ${screenWidth}px');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchDebounceTimer?.cancel();
    _examSearchDebounceTimer?.cancel();
    _questionSearchDebounceTimer?.cancel();
    _dashboardSearchDebounceTimer?.cancel();
    _searchController.dispose();
    _examSearchController.dispose();
    _questionSearchController.dispose();
    _dashboardSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadPositions(resetPage: true);
    });
  }

  void _clearSearch() {
    _searchQuery = '';
    _searchController.clear();
    _loadPositions(resetPage: true);
  }

  void _onDashboardSearchChanged(String value) {
    _dashboardSearchQuery = value;
    _dashboardSearchDebounceTimer?.cancel();
    _dashboardSearchDebounceTimer =
        Timer(const Duration(milliseconds: 500), () {
      _loadDashboardData();
    });
  }

  void _clearDashboardSearch() {
    _dashboardSearchQuery = '';
    _dashboardSearchController.clear();
    _loadDashboardData();
  }

  Future<void> _loadPositions({bool resetPage = false}) async {
    if (_selectedSection != 1)
      return; // Only load when positions section is selected

    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isLoadingPositions = true;
    });

    try {
      final result = await PositionsService.getPositions(
        page: _currentPage,
        limit: _positionsPerPage,
        search: _searchQuery,
      );

      setState(() {
        _positions = result.positions;
        _totalPages = result.totalPages;
        _totalRecords = result.totalItems;
        _isLoadingPositions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPositions = false;
      });
      NotificationService.showError(
          context: context, message: 'Failed to load positions: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
    });

    try {
      // Load dashboard stats and recent activity in parallel
      final results = await Future.wait([
        DashboardService.getDashboardStats(),
        DashboardService.getRecentActivity(),
      ]);

      setState(() {
        _dashboardStats = results[0] as DashboardStatsModel;
        _recentActivities = results[1] as List<ActivityLogModel>;
        _isLoadingDashboard = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDashboard = false;
      });
      NotificationService.showError(
          context: context, message: 'Failed to load dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
          return const LoginScreen();
        }

        return Scaffold(
          body: Row(
            children: [
              _buildSidebar(context, authProvider),
              Expanded(child: _buildMainContent(context, authProvider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, AuthProvider authProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;
    final isVerySmallScreen = screenWidth < 480;

    // Hide sidebar completely on very small screens when collapsed
    if (isVerySmallScreen && _isSidebarCollapsed) {
      return const SizedBox.shrink();
    }

    // Hide sidebar completely on small screens when collapsed
    if (isSmallScreen && _isSidebarCollapsed) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarCollapsed ? 70 : 250,
      color: const Color(0xFF1a1a2e),
      child: Column(
        children: [
          _buildLogoSection(),
          Expanded(child: _buildNavigationItems()),
          _buildCollapseButton(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isSidebarCollapsed
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.work, color: Colors.white, size: 20),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.work, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Text(
                    'JobExam Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavigationItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        return _buildNavigationItem(section, index);
      },
    );
  }

  Widget _buildNavigationItem(Map<String, dynamic> section, int index) {
    final isSelected = _selectedSection == index;
    final color = section['color'] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _selectedSection = index);
            if (index == 0) {
              _loadDashboardData(); // Load dashboard data when overview is selected
            } else if (index == 1) {
              _loadPositions(); // Load positions when section is selected
            } else if (index == 2) {
              _loadExams(); // Load exams when section is selected
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: _isSidebarCollapsed
                ? Icon(
                    section['icon'],
                    color: isSelected ? color : Colors.grey[400],
                    size: 24,
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Icon(
                          section['icon'],
                          color: isSelected ? color : Colors.grey[400],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          section['title'],
                          style: TextStyle(
                            color: isSelected ? color : Colors.grey[400],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: IconButton(
        icon: Icon(
          _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
          color: Colors.white,
        ),
        onPressed: () =>
            setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        _buildTopNavigationBar(context, authProvider),
        Expanded(child: _buildDashboardContent()),
      ],
    );
  }

  Widget _buildMobileMenuButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Icon(
          _isSidebarCollapsed ? Icons.menu : Icons.close,
          color: AppColors.primary,
          size: 24,
        ),
        onPressed: () {
          setState(() {
            _isSidebarCollapsed = !_isSidebarCollapsed;
          });
          print(
              '🔄 [SIDEBAR] Toggle sidebar: ${_isSidebarCollapsed ? 'collapsed' : 'expanded'}');
        },
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[100],
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(
      BuildContext context, AuthProvider authProvider) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final isMediumScreen = constraints.maxWidth < 900;
          final isMobileScreen = constraints.maxWidth < 768;

          return Row(
            children: [
              // Mobile menu button
              if (isMobileScreen) _buildMobileMenuButton(),
              Expanded(
                child: Text(
                  _sections[_selectedSection]['title'],
                  style: TextStyle(
                    fontSize: isMobileScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isSmallScreen) ...[
                if (constraints.maxWidth > 600)
                  Flexible(
                    child: Container(
                      width: 300,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _selectedSection == 0
                            ? _dashboardSearchController
                            : _selectedSection == 1
                                ? _searchController
                                : _selectedSection == 2
                                    ? _examSearchController
                                    : _questionSearchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: _selectedSection == 0
                              ? 'Search dashboard...'
                              : _selectedSection == 1
                                  ? 'Search positions...'
                                  : _selectedSection == 2
                                      ? 'Search exams...'
                                      : _selectedSection == 3
                                          ? 'Search questions...'
                                          : 'Search...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: ((_dashboardSearchQuery.isNotEmpty &&
                                      _selectedSection == 0) ||
                                  (_searchQuery.isNotEmpty &&
                                      _selectedSection == 1) ||
                                  (_examSearchQuery.isNotEmpty &&
                                      _selectedSection == 2) ||
                                  (_questionSearchQuery.isNotEmpty &&
                                      _selectedSection == 3))
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    if (_selectedSection == 0) {
                                      _clearDashboardSearch();
                                    } else if (_selectedSection == 1) {
                                      _clearSearch();
                                    } else if (_selectedSection == 2) {
                                      _clearExamSearch();
                                    } else if (_selectedSection == 3) {
                                      _clearQuestionSearch();
                                    }
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          if (_selectedSection == 0) {
                            _onDashboardSearchChanged(value);
                          } else if (_selectedSection == 1) {
                            _onSearchChanged(value);
                          } else if (_selectedSection == 2) {
                            _onExamSearchChanged(value);
                          } else if (_selectedSection == 3) {
                            _onQuestionSearchChanged(value);
                          }
                        },
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.grey),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logout button
                    IconButton(
                      onPressed: () => _showLogoutDialog(context, authProvider),
                      icon: const Icon(Icons.logout, color: Colors.grey),
                      tooltip: 'Logout',
                    ),
                    const SizedBox(width: 8),
                    // Profile button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSection = 6; // Profile section
                        });
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          authProvider.user!.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (constraints.maxWidth > 600) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            authProvider.user!.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Administrator',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding:
            EdgeInsets.all(MediaQuery.of(context).size.width < 768 ? 16 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFf8f9fa),
              const Color(0xFFe9ecef),
            ],
          ),
        ),
        child: _buildSectionContent(),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0:
        return _buildOverviewSection();
      case 1:
        return _buildPositionsSection();
      case 2:
        return _buildExamsSection();
      case 3:
        return _buildQuestionsSection();
      case 4:
        //   return _buildUsersSection();
        // case 5:
        return _buildProfileSection();
      default:
        return _buildOverviewSection();
    }

    //   return _buildAnalyticsSection();
    // case 6:
  }

  Widget _buildOverviewSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentActivityAndCharts(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            AppColors.primary.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 15),
            spreadRadius: 2,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 768;

          if (isSmallScreen) {
            // Mobile layout - stacked vertically
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back! 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Here\'s what\'s happening with your job exam system today.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                // const SizedBox(height: 20),
                // Container(
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(12),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.1),
                //         blurRadius: 10,
                //         offset: const Offset(0, 4),
                //       ),
                //     ],
                //   ),
                //   child: ElevatedButton.icon(
                //     onPressed: () {},
                //     icon: const Icon(Icons.add),
                //     label: const Text('Create New Position'),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.white,
                //       foregroundColor: AppColors.primary,
                //       padding: const EdgeInsets.symmetric(
                //           horizontal: 20, vertical: 12),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.rocket_launch,
                        color: Colors.white, size: 48),
                  ),
                ),
              ],
            );
          } else {
            // Desktop layout - side by side
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back! 👋',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Here\'s what\'s happening with your job exam system today.',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),

                      // Container(
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(12),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.black.withOpacity(0.1),
                      //         blurRadius: 10,
                      //         offset: const Offset(0, 4),
                      //       ),
                      //     ],
                      //   ),
                      //   child: ElevatedButton.icon(
                      //     onPressed: () {},
                      //     icon: const Icon(Icons.add),
                      //     label: const Text('Create New Position'),
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.white,
                      //       foregroundColor: AppColors.primary,
                      //       padding: const EdgeInsets.symmetric(
                      //           horizontal: 24, vertical: 12),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.rocket_launch,
                      color: Colors.white, size: 56),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_isLoadingDashboard) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth > 768;
          final crossAxisCount = isMobile ? 1 : (isTablet ? 4 : 2);

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 12 : 16,
            mainAxisSpacing: isMobile ? 12 : 16,
            childAspectRatio: isMobile ? 3.0 : (isTablet ? 4.0 : 3.5),
            children: List.generate(4, (index) => _buildStatCardLoading()),
          );
        },
      );
    }

    final stats = _dashboardStats;
    if (stats == null) {
      return const Center(
        child: Text('Failed to load dashboard stats'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth > 768;
        final crossAxisCount = isMobile ? 1 : (isTablet ? 4 : 2);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 12 : 16,
          mainAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: isMobile ? 3.0 : (isTablet ? 4.0 : 3.5),
          children: [
            _buildStatCard(
              'Total Positions',
              stats.totalPositions.toString(),
              Icons.work,
              AppColors.primary,
              '+${stats.recentPositions} this week',
            ),
            _buildStatCard(
              'Active Exams',
              stats.totalExams.toString(),
              Icons.quiz,
              AppColors.success,
              '+${stats.recentExams} this week',
            ),
            _buildStatCard(
              'Total Questions',
              stats.totalQuestions.toString(),
              Icons.question_answer,
              AppColors.warning,
              '+${stats.recentQuestions} this week',
            ),
            _buildStatCard(
              'Registered Users',
              stats.totalUsers.toString(),
              Icons.people,
              AppColors.info,
              '+${stats.recentUsers} this week',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCardLoading() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Loading icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Loading content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 10),
          ),

          const SizedBox(width: 6),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Value and trend in same row
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 0),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        trend.split(' ').first,
                        style: TextStyle(
                          fontSize: 6,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityAndCharts() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 768;

        if (isTablet) {
          return Row(
            children: [
              Expanded(flex: 2, child: _buildRecentActivity()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildQuickChart()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildRecentActivity(),
              const SizedBox(height: 24),
              _buildQuickChart(),
            ],
          );
        }
      },
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;

              if (isSmallScreen) {
                // Mobile layout - stacked vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'View All',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                );
              } else {
                // Desktop layout - side by side
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'View All',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          if (_isLoadingDashboard)
            ...List.generate(4, (index) => _buildActivityItemLoading())
          else if (_recentActivities.isEmpty)
            _buildEmptyActivityState()
          else
            ..._recentActivities
                .take(4)
                .map((activity) => _buildActivityItemFromData(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItemLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Activity will appear here as users interact with the system',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItemFromData(ActivityLogModel activity) {
    // Map action to icon and color
    IconData icon;
    Color color;

    switch (activity.action.toLowerCase()) {
      case 'login':
        icon = Icons.login;
        color = AppColors.success;
        break;
      case 'logout':
        icon = Icons.logout;
        color = AppColors.warning;
        break;
      case 'create':
      case 'created':
        icon = Icons.add;
        color = AppColors.success;
        break;
      case 'update':
      case 'updated':
        icon = Icons.edit;
        color = AppColors.warning;
        break;
      case 'delete':
      case 'deleted':
        icon = Icons.delete;
        color = AppColors.error;
        break;
      case 'register':
      case 'registered':
        icon = Icons.person_add;
        color = AppColors.info;
        break;
      default:
        icon = Icons.info;
        color = AppColors.primary;
    }

    // Format time
    String timeAgo = _formatTimeAgo(activity.createdAt);

    return _buildActivityItem(
      activity.action,
      activity.details ?? 'No details available',
      timeAgo,
      icon,
      color,
    );
  }

  String _formatTimeAgo(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  Widget _buildQuickChart() {
    return Container(
      padding:
          EdgeInsets.all(MediaQuery.of(context).size.width < 768 ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;

              if (isSmallScreen) {
                // Mobile layout - stacked vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.trending_up,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Exam Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              } else {
                // Desktop layout - side by side
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.trending_up,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Exam Performance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 768 ? 16 : 20),
          SizedBox(
            height: MediaQuery.of(context).size.width < 768 ? 150 : 200,
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: PerformanceChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 768;

            if (isSmallScreen) {
              // Mobile layout - stacked vertically
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Positions Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Searching for "$_searchQuery" • $_totalRecords positions found'
                        : 'Manage job positions and categories • $_totalRecords total positions',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_searchQuery.isNotEmpty) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearSearch,
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
                          onPressed: () => _showAddPositionDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Position'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Desktop layout - side by side
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Positions Management',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Searching for "$_searchQuery" • $_totalRecords positions found'
                            : 'Manage job positions and categories • $_totalRecords total positions',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_searchQuery.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Search'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      if (_searchQuery.isNotEmpty) const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPositionDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Position'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
              );
            }
          },
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoadingPositions
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading positions...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : _positions.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Expanded(child: _buildPositionsList()),
                        const SizedBox(height: 16),
                        _buildPaginationControls(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No positions found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first position to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddPositionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Position'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionsList() {
    return ListView.builder(
      itemCount: _positions.length,
      itemBuilder: (context, index) {
        final position = _positions[index];
        return _buildPositionCard(position);
      },
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

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
            // Mobile layout - stacked vertically
            return Column(
              children: [
                Text(
                  'Showing ${_positions.length} of $_totalRecords positions',
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
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                              _loadPositions();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: _currentPage > 1
                          ? AppColors.primary
                          : Colors.grey[400],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < _totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                              _loadPositions();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: _currentPage < _totalPages
                          ? AppColors.primary
                          : Colors.grey[400],
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Desktop layout - side by side
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_positions.length} of $_totalRecords positions',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                              _loadPositions();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: _currentPage > 1
                          ? AppColors.primary
                          : Colors.grey[400],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < _totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                              _loadPositions();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: _currentPage < _totalPages
                          ? AppColors.primary
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

  Widget _buildPositionCard(PositionModel position) {
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
            // Header row with title and actions
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.work, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    position.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditPositionDialog(position),
                      icon: Icon(Icons.edit, color: AppColors.warning),
                    ),
                    IconButton(
                      onPressed: () => _showDeletePositionDialog(position),
                      icon: Icon(Icons.delete, color: AppColors.error),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              position.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            // Footer row with exam count and date
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${position.examCount} exams',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Created: ${position.createdAt}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPositionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
                AppColors.primary.withValues(alpha: 0.05),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.work,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Position',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add a new job position to your system',
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
                    children: [
                      // Position Title Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: titleController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Position title is required';
                            }
                            if (value.length < 3) {
                              return 'Title must be at least 3 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Position Title',
                            hintText: 'e.g., Senior Software Engineer',
                            prefixIcon: const Icon(Icons.title,
                                color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: descriptionController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Description is required';
                            }
                            if (value.length < 10) {
                              return 'Description must be at least 10 characters';
                            }
                            return null;
                          },
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Position Description',
                            hintText:
                                'Describe the role, responsibilities, and requirements...',
                            prefixIcon: const Icon(Icons.description,
                                color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: AppColors.primary),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  try {
                                    await PositionsService.createPosition(
                                      title: titleController.text.trim(),
                                      description:
                                          descriptionController.text.trim(),
                                    );
                                    Navigator.of(context).pop();
                                    _loadPositions();
                                    NotificationService.showSuccess(
                                      context: context,
                                      message:
                                          'Position created successfully! 🎉',
                                    );
                                  } catch (e) {
                                    NotificationService.showError(
                                      context: context,
                                      message: 'Failed to create position: $e',
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.primary.withOpacity(0.3),
                              ),
                              child: const Text(
                                'Create Position',
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
    );
  }

  void _showEditPositionDialog(PositionModel position) {
    final titleController = TextEditingController(text: position.title);
    final descriptionController =
        TextEditingController(text: position.description);
    final formKey = GlobalKey<FormState>();

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
                AppColors.primary.withValues(alpha: 0.05),
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
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Position',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Update position details',
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
                    children: [
                      // Position Title Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: titleController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Position title is required';
                            }
                            if (value.length < 3) {
                              return 'Title must be at least 3 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Position Title',
                            hintText: 'e.g., Senior Software Engineer',
                            prefixIcon: const Icon(Icons.title,
                                color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: descriptionController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Description is required';
                            }
                            if (value.length < 10) {
                              return 'Description must be at least 10 characters';
                            }
                            return null;
                          },
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Position Description',
                            hintText:
                                'Describe the role, responsibilities, and requirements...',
                            prefixIcon: const Icon(Icons.description,
                                color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: AppColors.primary),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  try {
                                    await PositionsService.updatePosition(
                                      id: position.id,
                                      title: titleController.text.trim(),
                                      description:
                                          descriptionController.text.trim(),
                                    );
                                    Navigator.of(context).pop();
                                    _loadPositions();
                                    NotificationService.showSuccess(
                                      context: context,
                                      message:
                                          'Position updated successfully! 🎉',
                                    );
                                  } catch (e) {
                                    NotificationService.showError(
                                      context: context,
                                      message: 'Failed to update position: $e',
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor:
                                    AppColors.primary.withValues(alpha: 0.3),
                              ),
                              child: const Text(
                                'Update Position',
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
    );
  }

  void _showDeletePositionDialog(PositionModel position) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width *
              (MediaQuery.of(context).size.width < 768 ? 0.9 : 0.3),
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width < 768 ? double.infinity : 400,
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
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Position',
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
                              'Are you sure you want to delete "${position.title}"?',
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
                    const SizedBox(height: 8),
                    Text(
                      'This will permanently remove the position and all associated data. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
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
                                await PositionsService.deletePosition(
                                    position.id);
                                Navigator.of(context).pop();
                                _loadPositions();
                                NotificationService.showSuccess(
                                  context: context,
                                  message: 'Position deleted successfully! 🗑️',
                                );
                              } catch (e) {
                                NotificationService.showError(
                                  context: context,
                                  message: 'Failed to delete position: $e',
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
                              'Delete Position',
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

  // Exam Dialog Methods
  void _showAddExamDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int selectedPositionId =
        _allPositions.isNotEmpty ? _allPositions.first.id : 0;
    bool isPaid = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width *
                (MediaQuery.of(context).size.width < 768 ? 0.9 : 0.4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width < 768
                  ? double.infinity
                  : 500,
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
                          child: const Icon(
                            Icons.quiz,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Exam',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add a new exam to your system',
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
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Position Selection
                          const Text(
                            'Position *',
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
                              value: selectedPositionId == 0
                                  ? null
                                  : selectedPositionId,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 16),
                              ),
                              items: _allPositions
                                  .map((position) => DropdownMenuItem<int>(
                                        value: position.id,
                                        child: Text(
                                          position.title,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedPositionId = value ?? 0;
                                });
                              },
                              validator: (value) {
                                if (value == null || value == 0) {
                                  return 'Please select a position';
                                }
                                return null;
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Exam Title
                          const Text(
                            'Exam Title *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: titleController,
                            decoration: InputDecoration(
                              hintText: 'Enter exam title',
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
                                    BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter exam title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Paid/Free Toggle
                          Row(
                            children: [
                              const Text(
                                'Exam Type',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: isPaid,
                                onChanged: (value) {
                                  setDialogState(() {
                                    isPaid = value;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Text(
                                isPaid ? 'Paid' : 'Free',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isPaid
                                      ? AppColors.primary
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Price Field (only if paid)
                          if (isPaid) ...[
                            const Text(
                              'Price *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter price (e.g., 9.99)',
                                prefixText: '\$ ',
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
                                      BorderSide(color: AppColors.primary),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (isPaid &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Please enter price';
                                }
                                if (isPaid && double.tryParse(value!) == null) {
                                  return 'Please enter a valid price';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      try {
                                        final price = isPaid
                                            ? double.parse(priceController.text)
                                            : 0.0;
                                        await ExamsService.createExam(
                                          positionId: selectedPositionId,
                                          title: titleController.text.trim(),
                                          isPaid: isPaid,
                                          price: price,
                                        );
                                        Navigator.of(context).pop();
                                        _loadExams();
                                        NotificationService.showSuccess(
                                          context: context,
                                          message:
                                              'Exam created successfully! 📝',
                                        );
                                      } catch (e) {
                                        NotificationService.showError(
                                          context: context,
                                          message: 'Failed to create exam: $e',
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                  child: const Text(
                                    'Create Exam',
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

  void _showEditExamDialog(ExamModel exam) {
    final titleController = TextEditingController(text: exam.title);
    final priceController =
        TextEditingController(text: exam.isPaid ? exam.price.toString() : '');
    final formKey = GlobalKey<FormState>();
    int selectedPositionId = exam.positionId;
    bool isPaid = exam.isPaid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width *
                (MediaQuery.of(context).size.width < 768 ? 0.9 : 0.4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width < 768
                  ? double.infinity
                  : 500,
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
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Exam',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Update exam information',
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
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Position Selection
                          const Text(
                            'Position *',
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
                              value: selectedPositionId,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 16),
                              ),
                              items: _allPositions
                                  .map((position) => DropdownMenuItem<int>(
                                        value: position.id,
                                        child: Text(
                                          position.title,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedPositionId = value ?? 0;
                                });
                              },
                              validator: (value) {
                                if (value == null || value == 0) {
                                  return 'Please select a position';
                                }
                                return null;
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Exam Title
                          const Text(
                            'Exam Title *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: titleController,
                            decoration: InputDecoration(
                              hintText: 'Enter exam title',
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
                                    BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter exam title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Paid/Free Toggle
                          Row(
                            children: [
                              const Text(
                                'Exam Type',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: isPaid,
                                onChanged: (value) {
                                  setDialogState(() {
                                    isPaid = value;
                                    if (!value) {
                                      priceController.clear();
                                    }
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              Text(
                                isPaid ? 'Paid' : 'Free',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isPaid
                                      ? AppColors.primary
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Price Field (only if paid)
                          if (isPaid) ...[
                            const Text(
                              'Price *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter price (e.g., 9.99)',
                                prefixText: '\$ ',
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
                                      BorderSide(color: AppColors.primary),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (isPaid &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Please enter price';
                                }
                                if (isPaid && double.tryParse(value!) == null) {
                                  return 'Please enter a valid price';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      try {
                                        final price = isPaid
                                            ? double.parse(priceController.text)
                                            : 0.0;
                                        await ExamsService.updateExam(
                                          id: exam.id,
                                          positionId: selectedPositionId,
                                          title: titleController.text.trim(),
                                          isPaid: isPaid,
                                          price: price,
                                        );
                                        Navigator.of(context).pop();
                                        _loadExams();
                                        NotificationService.showSuccess(
                                          context: context,
                                          message:
                                              'Exam updated successfully! ✏️',
                                        );
                                      } catch (e) {
                                        NotificationService.showError(
                                          context: context,
                                          message: 'Failed to update exam: $e',
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                  child: const Text(
                                    'Update Exam',
                                    style: TextStyle(
                                      fontSize: 14,
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

  void _showDeleteExamDialog(ExamModel exam) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width *
              (MediaQuery.of(context).size.width < 768 ? 0.9 : 0.3),
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width < 768 ? double.infinity : 400,
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
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Exam',
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
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
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
                              'Are you sure you want to delete "${exam.title}"? This exam has ${exam.questionCount} questions that will also be deleted.',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await ExamsService.deleteExam(exam.id);
                                Navigator.of(context).pop();
                                _loadExams();
                                NotificationService.showSuccess(
                                  context: context,
                                  message: 'Exam deleted successfully! 🗑️',
                                );
                              } catch (e) {
                                NotificationService.showError(
                                  context: context,
                                  message: 'Failed to delete exam: $e',
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
                              'Delete Exam',
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

  // Exams methods
  Future<void> _loadAllPositions() async {
    try {
      final result = await PositionsService.getPositions(page: 1, limit: 1000);
      setState(() {
        _allPositions = result.positions;
      });
    } catch (e) {
      print('Error loading all positions: $e');
    }
  }

  Future<void> _loadExams({bool resetPage = false}) async {
    if (_selectedSection != 2)
      return; // Only load when exams section is selected

    if (resetPage) {
      _examCurrentPage = 1;
    }

    setState(() {
      _isLoadingExams = true;
    });

    try {
      final result = await ExamsService.getExams(
        page: _examCurrentPage,
        limit: _examsPerPage,
        search: _examSearchQuery,
        positionId: _selectedPositionFilter,
      );

      setState(() {
        _exams = result.exams;
        _examTotalPages = result.totalPages;
        _examTotalRecords = result.totalItems;
        _isLoadingExams = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingExams = false;
      });
      NotificationService.showError(
        context: context,
        message: 'Failed to load exams: $e',
      );
    }
  }

  void _onExamSearchChanged(String value) {
    _examSearchQuery = value;
    _examSearchDebounceTimer?.cancel();
    _examSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadExams(resetPage: true);
    });
  }

  void _clearExamSearch() {
    _examSearchQuery = '';
    _examSearchController.clear();
    _loadExams(resetPage: true);
  }

  void _onQuestionSearchChanged(String value) {
    _questionSearchQuery = value;
    _questionSearchDebounceTimer?.cancel();
    _questionSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {});
    });
  }

  void _clearQuestionSearch() {
    _questionSearchQuery = '';
    _questionSearchController.clear();
    setState(() {});
  }

  void _onPositionFilterChanged(int? positionId) {
    setState(() {
      _selectedPositionFilter = positionId ?? 0;
    });
    _loadExams(resetPage: true);
  }

  Widget _ExamsManagementContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 768;

            if (isSmallScreen) {
              // Mobile layout - stacked vertically
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exams Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _examSearchQuery.isNotEmpty || _selectedPositionFilter > 0
                        ? 'Filtered exams • $_examTotalRecords exams found'
                        : 'Manage exams and assessments • $_examTotalRecords total exams',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  // Position filter dropdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<int>(
                      value: _selectedPositionFilter == 0
                          ? null
                          : _selectedPositionFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Position',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('All Positions'),
                        ),
                        ..._allPositions
                            .map((position) => DropdownMenuItem<int>(
                                  value: position.id,
                                  child: Text(
                                    position.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                )),
                      ],
                      onChanged: _onPositionFilterChanged,
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_examSearchQuery.isNotEmpty ||
                          _selectedPositionFilter > 0) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _clearExamSearch();
                              _onPositionFilterChanged(null);
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
                          onPressed: () => _showAddExamDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exam'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Desktop layout - side by side
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exams Management',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _examSearchQuery.isNotEmpty ||
                                _selectedPositionFilter > 0
                            ? 'Filtered exams • $_examTotalRecords exams found'
                            : 'Manage exams and assessments • $_examTotalRecords total exams',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Position filter dropdown
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: _selectedPositionFilter == 0
                              ? null
                              : _selectedPositionFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Position',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('All Positions'),
                            ),
                            ..._allPositions
                                .map((position) => DropdownMenuItem<int>(
                                      value: position.id,
                                      child: Text(
                                        position.title,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    )),
                          ],
                          onChanged: _onPositionFilterChanged,
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_examSearchQuery.isNotEmpty ||
                          _selectedPositionFilter > 0)
                        OutlinedButton.icon(
                          onPressed: () {
                            _clearExamSearch();
                            _onPositionFilterChanged(null);
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
                      if (_examSearchQuery.isNotEmpty ||
                          _selectedPositionFilter > 0)
                        const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddExamDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
              );
            }
          },
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoadingExams
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading exams...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : _exams.isEmpty
                  ? _buildExamsEmptyState()
                  : Column(
                      children: [
                        Expanded(child: _buildExamsList()),
                        const SizedBox(height: 16),
                        _buildExamsPaginationControls(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildExamsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No exams found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first exam to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddExamDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Exam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList() {
    return ListView.builder(
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        return _buildExamCard(exam);
      },
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.quiz,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam.positionTitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditExamDialog(exam);
                      break;
                    case 'delete':
                      _showDeleteExamDialog(exam);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: exam.isPaid
                      ? AppColors.success.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exam.isPaid ? 'Paid' : 'Free',
                  style: TextStyle(
                    fontSize: 12,
                    color: exam.isPaid ? AppColors.success : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (exam.isPaid)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '\$${exam.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${exam.questionCount} questions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamsPaginationControls() {
    if (_examTotalPages <= 1) return const SizedBox.shrink();

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
            // Mobile layout - stacked vertically
            return Column(
              children: [
                Text(
                  'Showing ${_exams.length} of $_examTotalRecords exams',
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
                      onPressed: _examCurrentPage > 1
                          ? () {
                              setState(() {
                                _examCurrentPage--;
                              });
                              _loadExams();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: _examCurrentPage > 1
                          ? AppColors.warning
                          : Colors.grey[400],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_examCurrentPage / $_examTotalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _examCurrentPage < _examTotalPages
                          ? () {
                              setState(() {
                                _examCurrentPage++;
                              });
                              _loadExams();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: _examCurrentPage < _examTotalPages
                          ? AppColors.warning
                          : Colors.grey[400],
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Desktop layout - side by side
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_exams.length} of $_examTotalRecords exams',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _examCurrentPage > 1
                          ? () {
                              setState(() {
                                _examCurrentPage--;
                              });
                              _loadExams();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: _examCurrentPage > 1
                          ? AppColors.warning
                          : Colors.grey[400],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_examCurrentPage / $_examTotalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _examCurrentPage < _examTotalPages
                          ? () {
                              setState(() {
                                _examCurrentPage++;
                              });
                              _loadExams();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: _examCurrentPage < _examTotalPages
                          ? AppColors.warning
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

  Widget _buildExamsSection() {
    return _ExamsManagementContent();
  }

  Widget _buildQuestionsSection() {
    return QuestionsManagementWidget(
      externalSearchQuery: _questionSearchQuery,
      onSearchChanged: () {
        // This will be called when the widget's internal search changes
      },
    );
  }

  Widget _buildUsersSection() {
    return const Center(
      child: Text(
        'Users Management - Coming Soon!',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return const Center(
      child: Text(
        'Analytics Dashboard - Coming Soon!',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileSection() {
    return const ProfileManagementWidget();
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class PerformanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width, size.height * 0.1),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
