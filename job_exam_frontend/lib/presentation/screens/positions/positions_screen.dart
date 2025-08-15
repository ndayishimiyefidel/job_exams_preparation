import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../exams/exams_screen.dart';

class PositionsScreen extends StatelessWidget {
  const PositionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Positions'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Positions',
              style: AppThemes.lightTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a position to start preparing for your dream job',
              style: AppThemes.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _positions.length,
                itemBuilder: (context, index) {
                  final position = _positions[index];
                  return _buildPositionCard(context, position);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionCard(
      BuildContext context, Map<String, dynamic> position) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ExamsScreen(positionTitle: position['title']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: position['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  position['icon'],
                  color: position['color'],
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                position['title'],
                style: AppThemes.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${position['examCount']} exams',
                style: AppThemes.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: position['hasFree']
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      position['hasFree'] ? 'Free' : 'Paid',
                      style: AppThemes.lightTheme.textTheme.bodySmall?.copyWith(
                        color: position['hasFree']
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _positions = [
    {
      'title': 'Software Developer',
      'examCount': 15,
      'hasFree': true,
      'color': AppColors.primary,
      'icon': Icons.computer,
    },
    {
      'title': 'Bank Teller',
      'examCount': 8,
      'hasFree': true,
      'color': AppColors.secondary,
      'icon': Icons.account_balance,
    },
    {
      'title': 'Customer Service',
      'examCount': 12,
      'hasFree': false,
      'color': AppColors.success,
      'icon': Icons.headset_mic,
    },
    {
      'title': 'Data Analyst',
      'examCount': 10,
      'hasFree': true,
      'color': AppColors.info,
      'icon': Icons.analytics,
    },
    {
      'title': 'Marketing Specialist',
      'examCount': 6,
      'hasFree': false,
      'color': AppColors.warning,
      'icon': Icons.campaign,
    },
    {
      'title': 'Human Resources',
      'examCount': 9,
      'hasFree': true,
      'color': AppColors.error,
      'icon': Icons.people,
    },
  ];
}
