import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/firebase_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseService _service = FirebaseService();
  bool _showWeekly = true;

  final List<Color> _pieColors = [
    const Color(0xFF6C63FF),
    const Color(0xFF48C9B0),
    const Color(0xFFFF6B6B),
    const Color(0xFFFFA726),
    const Color(0xFF42A5F5),
    const Color(0xFFAB47BC),
    const Color(0xFF26A69A),
    const Color(0xFFEF5350),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Analytics")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No data yet",
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 16)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final now = DateTime.now();

          // ── Bar chart data ─────────────────────────
          final int days = _showWeekly ? 7 : 30;
          final Map<int, double> dailyTotals = {};
          for (int i = 0; i < days; i++) {
            dailyTotals[i] = 0;
          }
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final diff = now.difference(date).inDays;
            if (diff < days) {
              dailyTotals[diff] = (dailyTotals[diff] ?? 0) +
                  (data['amount'] ?? 0).toDouble();
            }
          }

          final barGroups = List.generate(days, (i) {
            final dayIndex = days - 1 - i;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyTotals[dayIndex] ?? 0,
                  color: const Color(0xFF6C63FF),
                  width: _showWeekly ? 18 : 8,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          });

          // ── Pie chart data ─────────────────────────
          final Map<String, double> categoryTotals = {};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final cat = data['category'] ?? 'Other';
            categoryTotals[cat] = (categoryTotals[cat] ?? 0) +
                (data['amount'] ?? 0).toDouble();
          }
          final pieEntries = categoryTotals.entries.toList();
          final totalAll =
              pieEntries.fold<double>(0, (s, e) => s + e.value);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle
                Row(
                  children: [
                    const Text("Spending Trend",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D))),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _toggleBtn("7D", _showWeekly,
                              () => setState(() => _showWeekly = true)),
                          _toggleBtn("30D", !_showWeekly,
                              () => setState(() => _showWeekly = false)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bar chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                if (!_showWeekly) {
                                  if (val.toInt() % 5 != 0) {
                                    return const SizedBox();
                                  }
                                }
                                final daysAgo =
                                    days - 1 - val.toInt();
                                final date = now.subtract(
                                    Duration(days: daysAgo));
                                return Text(
                                  _showWeekly
                                      ? _weekDay(date.weekday)
                                      : "${date.day}",
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text("Category Breakdown",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D))),
                const SizedBox(height: 16),

                // Pie chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sections: List.generate(
                              pieEntries.length,
                              (i) => PieChartSectionData(
                                value: pieEntries[i].value,
                                color: _pieColors[
                                    i % _pieColors.length],
                                radius: 80,
                                title:
                                    "${(pieEntries[i].value / totalAll * 100).toStringAsFixed(1)}%",
                                titleStyle: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: List.generate(
                          pieEntries.length,
                          (i) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _pieColors[
                                      i % _pieColors.length],
                                  borderRadius:
                                      BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${pieEntries[i].key} ₹${pieEntries[i].value.toStringAsFixed(0)}",
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2D2D2D)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              active ? const Color(0xFF6C63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  String _weekDay(int weekday) {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return days[weekday - 1];
  }
}