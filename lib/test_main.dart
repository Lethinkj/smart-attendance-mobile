import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

/// Simple test app to verify the basic Flutter setup works
void main() {
  runApp(
    const ProviderScope(
      child: TestApp(),
    ),
  );
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance Test',
      theme: AppTheme.lightTheme,
      home: const TestHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestHomeScreen extends StatefulWidget {
  const TestHomeScreen({super.key});

  @override
  State<TestHomeScreen> createState() => _TestHomeScreenState();
}

class _TestHomeScreenState extends State<TestHomeScreen> {
  int _counter = 0;
  String _testStatus = 'Ready to test';

  void _incrementCounter() {
    setState(() {
      _counter++;
      _testStatus = 'Button pressed $_counter times';
    });
  }

  void _runTests() {
    setState(() {
      _testStatus = 'Running tests...';
    });

    // Simulate test running
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _testStatus = 'All basic tests passed! ✅';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Attendance Test'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Smart Attendance System',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Test Environment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Test status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Status:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testStatus,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _testStatus.contains('✅') 
                            ? Colors.green[700] 
                            : AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Counter display
              Text(
                'Test Counter:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Test buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _incrementCounter,
                    child: const Text('Test Button'),
                  ),
                  OutlinedButton(
                    onPressed: _runTests,
                    child: const Text('Run Tests'),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // System info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Flutter Framework', 'Active ✅'),
                      _buildInfoRow('Material Design', 'Active ✅'),
                      _buildInfoRow('Riverpod State Management', 'Active ✅'),
                      _buildInfoRow('Custom Theme', 'Applied ✅'),
                      _buildInfoRow('Test Environment', 'Ready ✅'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: value.contains('✅') ? Colors.green[700] : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}