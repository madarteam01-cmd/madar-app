import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:madar/core/services/history_service.dart';

class DebtDetailsPage extends StatelessWidget {
  final String debtId;

  const DebtDetailsPage({
    super.key,
    required this.debtId,
  });

  static const Color _mainColor = Color(0xFF315052);

  Future<void> markAsPaid(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    final doc =
        await firestore.collection("debts").doc(debtId).get();

    if (!doc.exists) return;

    final data = doc.data()!;

    data["paidAt"] = Timestamp.now();

    await firestore.collection("paidDebts").add(data);

    await HistoryService().addHistory(
      action: "تسديد الدين",
      customerName: data["customerName"],
      amount: (data["amount"] as num).toDouble(),
    );

    await firestore.collection("debts").doc(debtId).delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم تسديد الدين بنجاح"),
      ),
    );

    context.go("/home");
  }

  Future<void> deleteDebt(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    final doc =
        await firestore.collection("debts").doc(debtId).get();

    final debt = doc.data()!;

    await HistoryService().addHistory(
      action: "حذف الدين",
      customerName: debt["customerName"],
      amount: (debt["amount"] as num).toDouble(),
    );

    await firestore.collection("debts").doc(debtId).delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم حذف الدين"),
      ),
    );

    context.go("/home");
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _mainColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _mainColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt is! Timestamp) return "-";
    final date = createdAt.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return "$day/$month/$year";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        backgroundColor: _mainColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "تفاصيل الدين",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("debts")
            .doc(debtId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final debt =
              snapshot.data!.data() as Map<String, dynamic>;

          final phone = debt["phone"].toString().isEmpty
              ? "-"
              : debt["phone"].toString();

          final notes = debt["notes"].toString().isEmpty
              ? "لا توجد ملاحظات"
              : debt["notes"].toString();

          final createdAtText = _formatDate(debt["createdAt"]);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة معلومات العميل
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: _mainColor,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                debt["customerName"],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _infoRow(
                          icon: Icons.phone_outlined,
                          label: "رقم الهاتف",
                          value: phone,
                        ),

                        const SizedBox(height: 16),

                        _infoRow(
                          icon: Icons.calendar_today_outlined,
                          label: "تاريخ إنشاء الدين",
                          value: createdAtText,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // بطاقة المبلغ المميزة
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _mainColor,
                          _mainColor.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _mainColor.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              color: Colors.white.withOpacity(0.9),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "مبلغ الدين",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${debt["amount"]} دج",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // بطاقة الملاحظات
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes_outlined,
                                color: Colors.grey.shade600, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "الملاحظات",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notes,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  _actionButton(
                    label: "تغيير معلومات العميل",
                    icon: Icons.edit,
                    color: _mainColor,
                    onPressed: () {
                      context.push('/edit-debt/$debtId');
                    },
                  ),

                  const SizedBox(height: 12),

                  _actionButton(
                    label: "تعديل مبلغ الدين",
                    icon: Icons.attach_money,
                    color: _mainColor,
                    onPressed: () {
                      context.push('/edit-amount/$debtId');
                    },
                  ),

                  const SizedBox(height: 12),

                  _actionButton(
                    label: "تم تسديد الدين",
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("تأكيد"),
                            content: const Text(
                              "هل أنت متأكد أن العميل قام بتسديد الدين بالكامل؟",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Text("إلغاء"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text("تم التسديد"),
                              ),
                            ],
                          );
                        },
                      );

                      if (result == true) {
                        if (!context.mounted) return;
                        await markAsPaid(context);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  _actionButton(
                    label: "حذف الدين",
                    icon: Icons.delete,
                    color: Colors.red,
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("حذف الدين"),
                            content: const Text(
                              "هل أنت متأكد من حذف هذا الدين؟ لا يمكن التراجع.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Text("إلغاء"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text("حذف"),
                              ),
                            ],
                          );
                        },
                      );

                      if (result == true) {
                        if (!context.mounted) return;
                        await deleteDebt(context);
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}