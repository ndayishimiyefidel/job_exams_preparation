import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/positions_service.dart';
import '../../../data/models/position_model.dart';
import '../exams/exams_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _featuredImageController;
  late AnimationController _floatingElementsController;
  late Animation<double> _featuredImageAnimation;
  late Animation<double> _floatingElementsAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isMenuOpen = false;

  // Data state
  List<PositionModel> _positions = [];
  bool _isLoadingPositions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _featuredImageController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _floatingElementsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _featuredImageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _featuredImageController,
      curve: Curves.easeInOut,
    ));

    _floatingElementsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingElementsController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _featuredImageController,
      curve: Curves.easeOutBack,
    ));

    _featuredImageController.forward();
    _floatingElementsController.repeat(reverse: true);

    // Load positions data
    _loadPositions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _featuredImageController.dispose();
    _floatingElementsController.dispose();
    super.dispose();
  }

  Future<void> _loadPositions() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPositions = true;
      _errorMessage = null;
    });

    try {
      final response = await PositionsService.getPublicPositions(limit: 6);
      if (mounted) {
        setState(() {
          _positions = response.positions;
          _isLoadingPositions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingPositions = false;
        });
      }
    }
  }

  void _scrollToSection(String section) {
    switch (section) {
      case 'home':
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        break;
      case 'positions':
        _scrollController.animateTo(
          800,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        break;
      case 'why-choose':
        _scrollController.animateTo(
          1200,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        break;
      case 'how-it-works':
        _scrollController.animateTo(
          1600,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        break;
      case 'impact':
        _scrollController.animateTo(
          2000,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        break;
      case 'contact':
        _scrollController.animateTo(
          2400,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Navigation Bar
            _buildNavigationBar(context),

            // Hero Section with Featured Image
            _buildHeroSection(context),

            // Popular Jobs Section
            _buildPopularJobsSection(context),

            // Why You Choose Section
            _buildWhyChooseSection(context),

            // How It Works Section
            _buildHowItWorksSection(context),

            // Our Impact Section
            _buildOurImpactSection(context),

            // Get in Touch Section
            _buildGetInTouchSection(context),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? _buildMobileNavigation(context)
          : _buildDesktopNavigation(context),
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return Column(
      children: [
        // Logo and Action Buttons Row
        Row(
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.work,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'JobExam',
                  style: AppThemes.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Hamburger Menu Button
            IconButton(
              onPressed: () {
                setState(() {
                  _isMenuOpen = !_isMenuOpen;
                });
              },
              icon: Icon(
                _isMenuOpen ? Icons.close : Icons.menu,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ],
        ),

        // Mobile Menu (Conditional)
        if (_isMenuOpen)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Navigation Links
                _buildMobileNavLink('Home', () {
                  _scrollToSection('home');
                  setState(() => _isMenuOpen = false);
                }),
                _buildMobileNavLink('Positions', () {
                  _scrollToSection('positions');
                  setState(() => _isMenuOpen = false);
                }),
                _buildMobileNavLink('Why Choose', () {
                  _scrollToSection('why-choose');
                  setState(() => _isMenuOpen = false);
                }),
                _buildMobileNavLink('How It Works', () {
                  _scrollToSection('how-it-works');
                  setState(() => _isMenuOpen = false);
                }),
                _buildMobileNavLink('Impact', () {
                  _scrollToSection('impact');
                  setState(() => _isMenuOpen = false);
                }),
                _buildMobileNavLink('Contact', () {
                  _scrollToSection('contact');
                  setState(() => _isMenuOpen = false);
                }),

                const Divider(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/login');
                          setState(() => _isMenuOpen = false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/register');
                          setState(() => _isMenuOpen = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopNavigation(BuildContext context) {
    return Row(
      children: [
        // Logo
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.work,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'JobExam',
              style: AppThemes.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Navigation Links
        Row(
          children: [
            _buildNavLink('Home', () => _scrollToSection('home')),
            _buildNavLink('Positions', () => _scrollToSection('positions')),
            _buildNavLink('Why Choose', () => _scrollToSection('why-choose')),
            _buildNavLink(
                'How It Works', () => _scrollToSection('how-it-works')),
            _buildNavLink('Impact', () => _scrollToSection('impact')),
            _buildNavLink('Contact', () => _scrollToSection('contact')),
          ],
        ),
        const SizedBox(width: 20),

        // Action Buttons
        Row(
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Login'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavLink(String text, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavLink(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * (isMobile ? 0.9 : 0.8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: isMobile
          ? _buildMobileHeroContent(context)
          : _buildDesktopHeroContent(context, isTablet),
    );
  }

  Widget _buildMobileHeroContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Animated Featured Image for Mobile
            AnimatedBuilder(
              animation: _featuredImageAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _featuredImageAnimation.value,
                  child: Container(
                    width: 250,
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Phone mockup
                        Positioned(
                          top: 30,
                          left: 40,
                          child: AnimatedBuilder(
                            animation: _slideAnimation,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _slideAnimation,
                                child: Container(
                                  width: 100,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: AppColors.black,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            AppColors.white.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.8),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.work,
                                          color: AppColors.white,
                                          size: 30,
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'JobExam',
                                                  style: AppThemes.lightTheme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Prep',
                                                  style: AppThemes.lightTheme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: AppColors.white
                                                        .withOpacity(0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Floating elements
                        Positioned(
                          top: 60,
                          right: 40,
                          child: AnimatedBuilder(
                            animation: _floatingElementsAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    0, 5 * _floatingElementsAnimation.value),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.quiz,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Positioned(
                          bottom: 80,
                          right: 30,
                          child: AnimatedBuilder(
                            animation: _floatingElementsAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    0, -5 * _floatingElementsAnimation.value),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.trending_up,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Central text
                        Positioned(
                          bottom: 30,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Text(
                                'Your Success',
                                style: AppThemes.lightTheme.textTheme.titleLarge
                                    ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Starts Here',
                                style: AppThemes
                                    .lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color: AppColors.white.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Content for Mobile
            Text(
              'Prepare for Your Dream Job',
              style: AppThemes.lightTheme.textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Master job exams with our comprehensive preparation platform. Practice with real questions, track your progress, and land your dream career.',
              style: AppThemes.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppColors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Buttons for Mobile
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _scrollToSection('positions');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Start Preparing',
                      style:
                          AppThemes.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _scrollToSection('how-it-works');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Learn More',
                      style:
                          AppThemes.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeroContent(BuildContext context, bool isTablet) {
    return Row(
      children: [
        // Left side - Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 40 : 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Prepare for Your Dream Job',
                  style: AppThemes.lightTheme.textTheme.displayLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Master job exams with our comprehensive preparation platform. Practice with real questions, track your progress, and land your dream career.',
                  style: AppThemes.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                    height: 1.5,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _scrollToSection('positions');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Start Preparing',
                        style: AppThemes.lightTheme.textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () {
                        _scrollToSection('how-it-works');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.white),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Learn More',
                        style: AppThemes.lightTheme.textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Right side - Animated Featured Image
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 40),
            child: Stack(
              children: [
                // Background decorative elements
                Positioned(
                  top: 20,
                  right: 20,
                  child: AnimatedBuilder(
                    animation: _floatingElementsAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _floatingElementsAnimation.value * 0.1,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: AnimatedBuilder(
                    animation: _floatingElementsAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_floatingElementsAnimation.value * 0.1,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Main featured image container
                Center(
                  child: AnimatedBuilder(
                    animation: _featuredImageAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _featuredImageAnimation.value,
                        child: Container(
                          width: isTablet ? 250 : 300,
                          height: isTablet ? 350 : 400,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.white.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Phone mockup
                              Positioned(
                                top: 40,
                                left: isTablet ? 40 : 50,
                                child: AnimatedBuilder(
                                  animation: _slideAnimation,
                                  builder: (context, child) {
                                    return SlideTransition(
                                      position: _slideAnimation,
                                      child: Container(
                                        width: isTablet ? 100 : 120,
                                        height: isTablet ? 160 : 200,
                                        decoration: BoxDecoration(
                                          color: AppColors.black,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                              color: AppColors.white
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: isTablet ? 100 : 120,
                                              height: isTablet ? 120 : 160,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.8),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(15),
                                                  topRight: Radius.circular(15),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.work,
                                                color: AppColors.white,
                                                size: isTablet ? 30 : 40,
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'JobExam',
                                                        style: AppThemes
                                                            .lightTheme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                          color:
                                                              AppColors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Prep',
                                                        style: AppThemes
                                                            .lightTheme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                          color: AppColors.white
                                                              .withOpacity(0.8),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Floating elements
                              Positioned(
                                top: 80,
                                right: isTablet ? 50 : 60,
                                child: AnimatedBuilder(
                                  animation: _floatingElementsAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0,
                                          8 * _floatingElementsAnimation.value),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.black
                                                  .withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.quiz,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              Positioned(
                                bottom: 120,
                                right: isTablet ? 30 : 40,
                                child: AnimatedBuilder(
                                  animation: _floatingElementsAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                          0,
                                          -8 *
                                              _floatingElementsAnimation.value),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.black
                                                  .withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.trending_up,
                                          color: AppColors.success,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Central text
                              Positioned(
                                bottom: 40,
                                left: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    Text(
                                      'Your Success',
                                      style: AppThemes
                                          .lightTheme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Starts Here',
                                      style: AppThemes
                                          .lightTheme.textTheme.titleLarge
                                          ?.copyWith(
                                        color: AppColors.white.withOpacity(0.9),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularJobsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Popular Job Positions',
            style: AppThemes.lightTheme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Explore the most sought-after job positions and start your preparation journey',
            style: AppThemes.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _isLoadingPositions
              ? _buildLoadingGrid()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _positions.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width < 768
                                    ? 2
                                    : MediaQuery.of(context).size.width < 1024
                                        ? 4
                                        : 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio:
                                MediaQuery.of(context).size.width < 768
                                    ? 0.8
                                    : 0.9,
                          ),
                          itemCount: _positions.length,
                          itemBuilder: (context, index) {
                            final position = _positions[index];
                            return _buildJobCard(context, position);
                          },
                        ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, PositionModel position) {
    // Get icon and color based on position title
    final iconData = _getPositionIcon(position.title);
    final color = _getPositionColor(position.title);
    final hasFreeExams = position.freeExamCount > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExamsScreen(
                positionId: position.id,
                positionTitle: position.title,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconData,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                position.title,
                style: AppThemes.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${position.examCount} exams',
                style: AppThemes.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasFreeExams
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasFreeExams ? 'Free' : 'Paid',
                  style: AppThemes.lightTheme.textTheme.bodySmall?.copyWith(
                    color: hasFreeExams ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 768 ? 2 : 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: MediaQuery.of(context).size.width < 768 ? 0.8 : 0.9,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load positions',
            style: AppThemes.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An error occurred while loading positions',
            style: AppThemes.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPositions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No positions available',
            style: AppThemes.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new job positions',
            style: AppThemes.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getPositionIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('software') || lowerTitle.contains('developer')) {
      return Icons.computer;
    } else if (lowerTitle.contains('bank') || lowerTitle.contains('teller')) {
      return Icons.account_balance;
    } else if (lowerTitle.contains('customer') ||
        lowerTitle.contains('service')) {
      return Icons.headset_mic;
    } else if (lowerTitle.contains('data') || lowerTitle.contains('analyst')) {
      return Icons.analytics;
    } else if (lowerTitle.contains('marketing')) {
      return Icons.campaign;
    } else if (lowerTitle.contains('human') || lowerTitle.contains('hr')) {
      return Icons.people;
    } else {
      return Icons.work;
    }
  }

  Color _getPositionColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('software') || lowerTitle.contains('developer')) {
      return AppColors.primary;
    } else if (lowerTitle.contains('bank') || lowerTitle.contains('teller')) {
      return AppColors.secondary;
    } else if (lowerTitle.contains('customer') ||
        lowerTitle.contains('service')) {
      return AppColors.success;
    } else if (lowerTitle.contains('data') || lowerTitle.contains('analyst')) {
      return AppColors.info;
    } else if (lowerTitle.contains('marketing')) {
      return AppColors.warning;
    } else if (lowerTitle.contains('human') || lowerTitle.contains('hr')) {
      return AppColors.error;
    } else {
      return AppColors.primary;
    }
  }

  Widget _buildWhyChooseSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      color: AppColors.greyLight,
      child: Column(
        children: [
          Text(
            'Why Choose JobExam?',
            style: AppThemes.lightTheme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Discover what makes us the preferred choice for job exam preparation',
            style: AppThemes.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          MediaQuery.of(context).size.width < 768
              ? Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.verified,
                      title: 'Expert Content',
                      description:
                          'Questions designed by industry experts and HR professionals',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      icon: Icons.analytics,
                      title: 'Progress Tracking',
                      description:
                          'Monitor your performance with detailed analytics and insights',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      icon: Icons.mobile_friendly,
                      title: 'Mobile First',
                      description:
                          'Study anywhere, anytime with our mobile-optimized platform',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      icon: Icons.security,
                      title: 'Secure Platform',
                      description:
                          'Your data is protected with enterprise-grade security',
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.verified,
                        title: 'Expert Content',
                        description:
                            'Questions designed by industry experts and HR professionals',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.analytics,
                        title: 'Progress Tracking',
                        description:
                            'Monitor your performance with detailed analytics and insights',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.mobile_friendly,
                        title: 'Mobile First',
                        description:
                            'Study anywhere, anytime with our mobile-optimized platform',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.security,
                        title: 'Secure Platform',
                        description:
                            'Your data is protected with enterprise-grade security',
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppThemes.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppThemes.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          Text(
            'How It Works',
            style: AppThemes.lightTheme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Get started in three simple steps',
            style: AppThemes.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          MediaQuery.of(context).size.width < 768
              ? Column(
                  children: [
                    _buildStepCard(
                      number: '1',
                      title: 'Choose Position',
                      description:
                          'Browse and select the job position you want to prepare for',
                      icon: Icons.work,
                    ),
                    const SizedBox(height: 40),
                    _buildStepCard(
                      number: '2',
                      title: 'Take Exams',
                      description:
                          'Practice with comprehensive exam questions and scenarios',
                      icon: Icons.quiz,
                    ),
                    const SizedBox(height: 40),
                    _buildStepCard(
                      number: '3',
                      title: 'Track Progress',
                      description:
                          'Monitor your performance and focus on areas for improvement',
                      icon: Icons.trending_up,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildStepCard(
                        number: '1',
                        title: 'Choose Position',
                        description:
                            'Browse and select the job position you want to prepare for',
                        icon: Icons.work,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStepCard(
                        number: '2',
                        title: 'Take Exams',
                        description:
                            'Practice with comprehensive exam questions and scenarios',
                        icon: Icons.quiz,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStepCard(
                        number: '3',
                        title: 'Track Progress',
                        description:
                            'Monitor your performance and focus on areas for improvement',
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(
              number,
              style: AppThemes.lightTheme.textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Icon(
          icon,
          size: 40,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: AppThemes.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: AppThemes.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOurImpactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      color: AppColors.greyLight,
      child: Column(
        children: [
          Text(
            'Our Impact',
            style: AppThemes.lightTheme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Join thousands of successful job seekers',
            style: AppThemes.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          MediaQuery.of(context).size.width < 768
              ? Column(
                  children: [
                    _buildStatCard(
                      number: '10,000+',
                      label: 'Job Seekers',
                      icon: Icons.people,
                    ),
                    const SizedBox(height: 20),
                    _buildStatCard(
                      number: '500+',
                      label: 'Practice Exams',
                      icon: Icons.quiz,
                    ),
                    const SizedBox(height: 20),
                    _buildStatCard(
                      number: '95%',
                      label: 'Success Rate',
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: 20),
                    _buildStatCard(
                      number: '50+',
                      label: 'Job Positions',
                      icon: Icons.work,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        number: '10,000+',
                        label: 'Job Seekers',
                        icon: Icons.people,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        number: '500+',
                        label: 'Practice Exams',
                        icon: Icons.quiz,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        number: '95%',
                        label: 'Success Rate',
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        number: '50+',
                        label: 'Job Positions',
                        icon: Icons.work,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String number,
    required String label,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              number,
              style: AppThemes.lightTheme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppThemes.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGetInTouchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Get in Touch',
            style: AppThemes.lightTheme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Have questions? We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.',
            style: AppThemes.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          MediaQuery.of(context).size.width < 768
              ? Column(
                  children: [
                    // Contact Information
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: AppThemes.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildContactItem(
                          icon: Icons.location_on,
                          title: 'Address',
                          subtitle: 'Kigali, Rwanda\nEast Africa',
                        ),
                        const SizedBox(height: 24),
                        _buildContactItem(
                          icon: Icons.phone,
                          title: 'Phone',
                          subtitle: '+250 788 123 456\n+250 789 123 456',
                        ),
                        const SizedBox(height: 24),
                        _buildContactItem(
                          icon: Icons.email,
                          title: 'Email',
                          subtitle: 'info@jobexam.rw\nsupport@jobexam.rw',
                        ),
                        const SizedBox(height: 24),
                        _buildContactItem(
                          icon: Icons.access_time,
                          title: 'Working Hours',
                          subtitle:
                              'Monday - Friday: 8:00 AM - 6:00 PM\nSaturday: 9:00 AM - 3:00 PM',
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Contact Form
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send us a Message',
                              style: AppThemes
                                  .lightTheme.textTheme.headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildFormField('Full Name', Icons.person),
                            const SizedBox(height: 16),
                            _buildFormField('Email Address', Icons.email),
                            const SizedBox(height: 16),
                            _buildFormField('Phone Number', Icons.phone),
                            const SizedBox(height: 16),
                            _buildFormField('Message', Icons.message,
                                maxLines: 4),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle form submission
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Send Message',
                                  style: AppThemes
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Contact Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Information',
                            style: AppThemes.lightTheme.textTheme.headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildContactItem(
                            icon: Icons.location_on,
                            title: 'Address',
                            subtitle: 'Kigali, Rwanda\nEast Africa',
                          ),
                          const SizedBox(height: 24),
                          _buildContactItem(
                            icon: Icons.phone,
                            title: 'Phone',
                            subtitle: '+250 788 123 456\n+250 789 123 456',
                          ),
                          const SizedBox(height: 24),
                          _buildContactItem(
                            icon: Icons.email,
                            title: 'Email',
                            subtitle: 'info@jobexam.rw\nsupport@jobexam.rw',
                          ),
                          const SizedBox(height: 24),
                          _buildContactItem(
                            icon: Icons.access_time,
                            title: 'Working Hours',
                            subtitle:
                                'Monday - Friday: 8:00 AM - 6:00 PM\nSaturday: 9:00 AM - 3:00 PM',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 60),

                    // Contact Form
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Send us a Message',
                                style: AppThemes
                                    .lightTheme.textTheme.headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildFormField('Full Name', Icons.person),
                              const SizedBox(height: 16),
                              _buildFormField('Email Address', Icons.email),
                              const SizedBox(height: 16),
                              _buildFormField('Phone Number', Icons.phone),
                              const SizedBox(height: 16),
                              _buildFormField('Message', Icons.message,
                                  maxLines: 4),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle form submission
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Send Message',
                                    style: AppThemes
                                        .lightTheme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppThemes.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppThemes.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(String label, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppThemes.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.greyLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: Column(
        children: [
          isMobile
              ? Column(
                  children: [
                    // Company Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.work,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'JobExam',
                              style: AppThemes.lightTheme.textTheme.titleLarge
                                  ?.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You prepare. We deliver success.',
                          style: AppThemes.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppColors.black.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Join Us On',
                          style: AppThemes.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildSocialIcon(Icons.facebook),
                            const SizedBox(width: 12),
                            _buildSocialIcon(Icons.camera_alt),
                            const SizedBox(width: 12),
                            _buildSocialIcon(Icons.flutter_dash),
                            const SizedBox(width: 12),
                            _buildSocialIcon(Icons.link),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Trusted by Job Seekers',
                              style: AppThemes.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Payment Methods
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Methods',
                          style: AppThemes.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildPaymentLogo('MoMo', AppColors.warning),
                            _buildPaymentLogo('MTN', AppColors.examPaid),
                            _buildPaymentLogo('Airtel', AppColors.error),
                            _buildPaymentLogo('VISA', AppColors.info),
                            _buildPaymentLogo('Mastercard', AppColors.warning),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // User Links
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Links',
                          style: AppThemes.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFooterLink('About Us'),
                        _buildFooterLink('Contact Us'),
                        _buildFooterLink('FAQs'),
                        _buildFooterLink('Privacy Policy'),
                        _buildFooterLink('Terms & Conditions'),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Downloads
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Downloads',
                          style: AppThemes.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Get our mobile app for the best experience',
                          style: AppThemes.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppColors.black.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAppStoreBadge(
                            'Download on the\nApp Store', Icons.apple),
                        const SizedBox(height: 12),
                        _buildAppStoreBadge(
                            'GET IT ON\nGoogle Play', Icons.play_arrow),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.work,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'JobExam',
                                style: AppThemes.lightTheme.textTheme.titleLarge
                                    ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You prepare. We deliver success.',
                            style: AppThemes.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppColors.black.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Join Us On',
                            style: AppThemes.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSocialIcon(Icons.facebook),
                              const SizedBox(width: 12),
                              _buildSocialIcon(Icons.camera_alt),
                              const SizedBox(width: 12),
                              _buildSocialIcon(Icons.flutter_dash),
                              const SizedBox(width: 12),
                              _buildSocialIcon(Icons.link),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.verified,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Trusted by Job Seekers',
                                style: AppThemes.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Payment Methods
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Methods',
                            style: AppThemes.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildPaymentLogo('MoMo', AppColors.warning),
                              _buildPaymentLogo('MTN', AppColors.examPaid),
                              _buildPaymentLogo('Airtel', AppColors.error),
                              _buildPaymentLogo('VISA', AppColors.info),
                              _buildPaymentLogo(
                                  'Mastercard', AppColors.warning),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // User Links
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Links',
                            style: AppThemes.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFooterLink('About Us'),
                          _buildFooterLink('Contact Us'),
                          _buildFooterLink('FAQs'),
                          _buildFooterLink('Privacy Policy'),
                          _buildFooterLink('Terms & Conditions'),
                        ],
                      ),
                    ),

                    // Downloads
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Downloads',
                            style: AppThemes.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Get our mobile app for the best experience',
                            style: AppThemes.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppColors.black.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildAppStoreBadge(
                              'Download on the\nApp Store', Icons.apple),
                          const SizedBox(height: 12),
                          _buildAppStoreBadge(
                              'GET IT ON\nGoogle Play', Icons.play_arrow),
                        ],
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.black, height: 0.5),
          const SizedBox(height: 10),

          // Copyright
          Text(
            '© 2020 - 2025. JobExam Africa LTD. All rights reserved.',
            style: AppThemes.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppColors.black.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: AppColors.white,
        size: 18,
      ),
    );
  }

  Widget _buildPaymentLogo(String name, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          name,
          style: AppThemes.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextButton(
        onPressed: () {
          // TODO: Add link
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: AppThemes.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppColors.black.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildAppStoreBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppThemes.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _popularJobs = [
    {
      'title': 'Software Developer',
      'examCount': 15,
      'isFree': true,
      'color': AppColors.primary,
      'icon': Icons.computer,
    },
    {
      'title': 'Bank Teller',
      'examCount': 8,
      'isFree': true,
      'color': AppColors.secondary,
      'icon': Icons.account_balance,
    },
    {
      'title': 'Customer Service',
      'examCount': 12,
      'isFree': false,
      'color': AppColors.success,
      'icon': Icons.headset_mic,
    },
    {
      'title': 'Data Analyst',
      'examCount': 10,
      'isFree': true,
      'color': AppColors.info,
      'icon': Icons.analytics,
    },
    {
      'title': 'Marketing Specialist',
      'examCount': 6,
      'isFree': false,
      'color': AppColors.warning,
      'icon': Icons.campaign,
    },
    {
      'title': 'Human Resources',
      'examCount': 9,
      'isFree': true,
      'color': AppColors.error,
      'icon': Icons.people,
    },
  ];
}
