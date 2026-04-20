import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/expense_model.dart';
import '../../widgets/expense_card.dart';
import '../add_expense/add_expense_screen.dart';
import '../analytics/analytics_screen.dart';
import '../calendar/calendar_screen.dart';
import '../../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService firebaseService = FirebaseService();
  int _currentIndex = 0;

  void addExpense(String title, double amount, String category) {
    firebaseService.addExpense(title, amount, category);
  }

  void openAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(onAdd: addExpense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const CalendarScreen(),
          const AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF6C63FF).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF6C63FF)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon:
                Icon(Icons.calendar_month, color: Color(0xFF6C63FF)),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF6C63FF)),
            label: 'Analytics',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: openAddExpense,
              icon: const Icon(Icons.add),
              label: const Text("Add Expense"),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Expense Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => firebaseService.logout(),
            tooltip: "Logout",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firebaseService.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          final docs = snapshot.hasData ? snapshot.data!.docs : [];
          final total = docs.fold<double>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['amount'] ?? 0).toDouble();
          });

          return Column(
            children: [
              // Summary card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                    vertical: 28, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF48C9B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Spent",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text("₹${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                        "${docs.length} transaction${docs.length == 1 ? '' : 's'}",
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Text("Recent Transactions",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D))),
                    const Spacer(),
                    Text("${docs.length} items",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("No expenses yet",
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            Text("Tap + to add your first expense",
                                style: TextStyle(
                                    color: Colors.grey.shade300,
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: docs.length,
                        itemBuilder: (_, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final expense = Expense(
                            id: doc.id,
                            title: data['title'] ?? '',
                            amount: (data['amount'] ?? 0).toDouble(),
                            date:
                                (data['date'] as Timestamp).toDate(),
                            category: data['category'] ?? 'Other',
                          );
                          return ExpenseCard(
                            expense: expense,
                            onDelete: () =>
                                firebaseService.deleteExpense(doc.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}