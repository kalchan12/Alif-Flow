import 'package:flutter/material.dart';
import 'package:alif_flow/theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  
  // Dummy data
  final List<Map<String, dynamic>> _reports = [
    {
      'seller': 'Ahmed Ali',
      'date': 'Oct 24 - Oct 31, 2023',
      'total': '12,500',
      'status': 'Pending',
    },
    {
      'seller': 'Sara Khan',
      'date': 'Oct 24 - Oct 31, 2023',
      'total': '8,200',
      'status': 'Approved',
    },
    {
      'seller': 'Omar Farooq',
      'date': 'Oct 17 - Oct 24, 2023',
      'total': '15,000',
      'status': 'Approved',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _reports.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Recent Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            );
          }

          final report = _reports[index - 1];
          final isPending = report['status'] == 'Pending';

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              title: Text(
                report['seller'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(report['date'], style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    'Total Sales: \$${report['total']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryCyan,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report['status'],
                      style: TextStyle(
                        color: isPending ? Colors.orange[800] : Colors.green[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: AppTheme.textGray),
                ],
              ),
              onTap: () {
                // Navigate to report detail
              },
            ),
          );
        },
      );
    } else {
      return Center(
        child: Text('Content for tab $_selectedIndex'),
      );
    }
  }
}
