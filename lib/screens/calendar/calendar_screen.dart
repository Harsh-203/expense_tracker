import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/firebase_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirebaseService _service = FirebaseService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Calendar")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF)));
          }

          final docs =
              snapshot.hasData ? snapshot.data!.docs : [];

          // Build map: date → total amount
          final Map<DateTime, double> dailyTotals = {};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date =
                _normalize((data['date'] as Timestamp).toDate());
            dailyTotals[date] =
                (dailyTotals[date] ?? 0) +
                    (data['amount'] ?? 0).toDouble();
          }

          // Selected day expenses
          final selected = _selectedDay != null
              ? _normalize(_selectedDay!)
              : _normalize(DateTime.now());
          final selectedDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date =
                _normalize((data['date'] as Timestamp).toDate());
            return date == selected;
          }).toList();

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
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
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF48C9B0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final key = _normalize(day);
                      if (dailyTotals.containsKey(key)) {
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF48C9B0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "₹${dailyTotals[key]!.toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),

              // Selected day detail
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      selectedDocs.isEmpty
                          ? "No expenses on this day"
                          : "Expenses on ${selected.day}/${selected.month}/${selected.year}",
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D)),
                    ),
                    const Spacer(),
                    if (dailyTotals[selected] != null)
                      Text(
                        "₹${dailyTotals[selected]!.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: selectedDocs.isEmpty
                    ? Center(
                        child: Text("No expenses recorded",
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14)))
                    : ListView.builder(
                        padding:
                            const EdgeInsets.only(bottom: 80),
                        itemCount: selectedDocs.length,
                        itemBuilder: (_, i) {
                          final data = selectedDocs[i].data()
                              as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF)
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.receipt_outlined,
                                      color: Color(0xFF6C63FF),
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(data['title'] ?? '',
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w600,
                                              fontSize: 14)),
                                      Text(
                                          data['category'] ??
                                              'Other',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors
                                                  .grey.shade500)),
                                    ],
                                  ),
                                ),
                                Text(
                                  "₹${(data['amount'] ?? 0).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF6C63FF)),
                                ),
                              ],
                            ),
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