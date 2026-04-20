import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Function(String, double, String) onAdd; // ✅ 3 params

  const AddExpenseScreen({super.key, required this.onAdd});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final FirebaseService _service = FirebaseService();

  final List<String> _defaultCategories = [
    'Food', 'Travel', 'Shopping', 'Bills', 'Health', 'Entertainment',
  ];
  String _selectedCategory = 'Food';
  List<String> _customCategories = [];

  @override
  void initState() {
    super.initState();
    _service.getCustomCategories().listen((snapshot) {
      setState(() {
        _customCategories =
            snapshot.docs.map((d) => d['name'] as String).toList();
      });
    });
  }

  List<String> get _allCategories =>
      [..._defaultCategories, ..._customCategories];

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Category name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await _service.addCategory(name);
                setState(() => _selectedCategory = name);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty || amount == null) return;
    widget.onAdd(title, amount, _selectedCategory); // ✅ 3 args passed
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Add Expense")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text("Expense Details",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D))),
            const SizedBox(height: 6),
            Text("Fill in the details below to log your expense",
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 28),

            // Title
            _buildInputField(
              controller: _titleController,
              label: "Title",
              hint: "e.g. Groceries, Rent, Netflix",
              icon: Icons.label_outline,
            ),
            const SizedBox(height: 16),

            // Amount
            _buildInputField(
              controller: _amountController,
              label: "Amount",
              hint: "e.g. 499.00",
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Category
            const Text("Category",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D))),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _service.getCustomCategories(),
              builder: (context, snapshot) {
                final customCats = snapshot.hasData
                    ? snapshot.data!.docs
                        .map((d) => d['name'] as String)
                        .toList()
                    : <String>[];
                final allCats = [
                  ..._defaultCategories,
                  ...customCats
                ];
                if (!allCats.contains(_selectedCategory)) {
                  _selectedCategory = allCats.first;
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...allCats.map((cat) => _categoryChip(cat)),
                    GestureDetector(
                      onTap: _showAddCategoryDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF6C63FF),
                              style: BorderStyle.solid),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 16, color: Color(0xFF6C63FF)),
                            SizedBox(width: 4),
                            Text("Other+",
                                style: TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                child: const Text("Save Expense",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    final selected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6C63FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 13)),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
              color: Color(0xFF6C63FF), fontSize: 13),
        ),
      ),
    );
  }
}