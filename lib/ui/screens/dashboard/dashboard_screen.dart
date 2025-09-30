import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user.dart';

/// Main dashboard screen for both admin and staff users
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    
    if (!authState.isAuthenticated || authState.user == null) {
      // This shouldn't happen as app.dart handles auth routing
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user!;
    
    return Scaffold(
      appBar: _buildAppBar(user),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _DashboardOverview(user: user),
          _AttendanceScreen(),
          _StudentsScreen(),
          _SettingsScreen(user: user),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(user),
    );
  }

  PreferredSizeWidget _buildAppBar(User user) {
    final titles = user.role == UserRole.admin
        ? ['Dashboard', 'Schools', 'Users', 'Settings']
        : ['Dashboard', 'Attendance', 'Students', 'Settings'];

    return AppBar(
      title: Text(titles[_selectedIndex]),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Implement notifications
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              _handleLogout();
            } else if (value == 'profile') {
              _showProfile(user);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Profile'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(User user) {
    if (user.role == UserRole.admin) {
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Schools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      );
    } else {
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      );
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(authServiceProvider.notifier).logout();
    }
  }

  void _showProfile(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Name', user.name),
            _buildProfileItem('Email', user.email),
            _buildProfileItem('Role', user.role.name.toUpperCase()),
            if (user.schoolId != null)
              _buildProfileItem('School ID', user.schoolId!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Dashboard overview screen
class _DashboardOverview extends StatelessWidget {
  final User user;

  const _DashboardOverview({required this.user});

  @override
  Widget build(BuildContext context) {
    final dashboardData = DashboardService.getDashboardData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          _buildWelcomeCard(),
          
          const SizedBox(height: 20),
          
          // Key metrics
          _buildMetricsGrid(dashboardData),
          
          const SizedBox(height: 20),
          
          // Today's attendance summary
          _buildTodayAttendance(dashboardData),
          
          const SizedBox(height: 20),
          
          // Alerts (if any)
          if (dashboardData.hasAlerts) ...[
            _buildAlerts(dashboardData),
            const SizedBox(height: 20),
          ],
          
          // Recent activities
          _buildRecentActivities(dashboardData),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back,',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.role == UserRole.admin 
                  ? 'System Administrator'
                  : 'Staff Member',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(DashboardData data) {
    final metrics = user.role == UserRole.admin
        ? [
            _MetricItem('Schools', data.totalSchools.toString(), Icons.school),
            _MetricItem('Students', data.totalStudents.toString(), Icons.people),
            _MetricItem('Classes', data.totalClasses.toString(), Icons.class_),
            _MetricItem('Staff', data.totalStaff.toString(), Icons.person),
          ]
        : [
            _MetricItem('Students', data.totalStudents.toString(), Icons.people),
            _MetricItem('Classes', data.totalClasses.toString(), Icons.class_),
            _MetricItem('Present Today', data.todayPresent.toString(), Icons.check_circle),
            _MetricItem('Absent Today', data.todayAbsent.toString(), Icons.cancel),
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  metric.icon,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayAttendance(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceItem(
                    'Present',
                    data.todayPresent,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttendanceItem(
                    'Absent',
                    data.todayAbsent,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: data.todayTotal > 0 ? data.todayPresent / data.todayTotal : 0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendance Rate: ${data.attendanceRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAlerts(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Text(
                  'Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.alerts.take(3).map((alert) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: alert.severity == AlertSeverity.high 
                        ? Colors.red 
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (data.recentActivities.isEmpty)
              const Text(
                'No recent activities',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...data.recentActivities.take(5).map((activity) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      activity.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            activity.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(activity.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Placeholder screens for other tabs
class _AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'Attendance Screen',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'RFID attendance marking coming soon!',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StudentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'Students Screen',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Student management coming soon!',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  final User user;

  const _SettingsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: Text(user.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to profile screen
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Settings'),
            subtitle: const Text('Configure synchronization'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to sync settings
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show about dialog
            },
          ),
        ),
      ],
    );
  }
}

/// Metric item for dashboard grid
class _MetricItem {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem(this.label, this.value, this.icon);
}