import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:madar/core/services/history_service.dart';

class EditDebtPage extends StatefulWidget {
  final String debtId;

  const EditDebtPage({
    super.key,
    required this.debtId,
  });

  @override
  State<EditDebtPage> createState() => _EditDebtPageState();
}

class _EditDebtPageState extends State<EditDebtPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool loading = true;
  bool saving = false;

  double amount = 0;

  static const Color _mainColor = Color(0xFF315052);

  @override
  void initState() {
    super.initState();
    loadDebt();
  }

  Future<void> loadDebt() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("debts")
          .doc(widget.debtId)
          .get();

      if (!doc.exists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("الدين غير موجود"),
          ),
        );

        context.pop();
        return;
      }

      final data = doc.data()!;

      nameController.text = data["customerName"] ?? "";
      phoneController.text = data["phone"] ?? "";
      notesController.text = data["notes"] ?? "";
      amount = (data["amount"] ?? 0).toDouble();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveChanges() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إدخال اسم العميل"),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("debts")
          .doc(widget.debtId)
          .update({
        "customerName": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "notes": notesController.text.trim(),
      });

      await HistoryService().addHistory(
        action: "تعديل بيانات العميل",
        customerName: nameController.text.trim(),
        amount: amount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم تعديل الدين بنجاح"),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() {
        saving = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _mainColor),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _mainColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل الدين"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "تعديل بيانات العميل",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _mainColor,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "يمكنك تعديل بيانات العميل ثم حفظ التغييرات.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: nameController,
                decoration: _fieldDecoration(
                  label: "اسم العميل",
                  icon: Icons.person_outline,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _fieldDecoration(
                  label: "رقم الهاتف",
                  icon: Icons.phone_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: _fieldDecoration(
                  label: "الملاحظات",
                  icon: Icons.notes_outlined,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: saving ? null : saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mainColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "حفظ التعديلات",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}