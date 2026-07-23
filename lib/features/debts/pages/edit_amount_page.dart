import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:madar/core/services/history_service.dart';

class EditAmountPage extends StatefulWidget {
  final String debtId;

  const EditAmountPage({
    super.key,
    required this.debtId,
  });

  @override
  State<EditAmountPage> createState() => _EditAmountPageState();
}

class _EditAmountPageState extends State<EditAmountPage> {
  final amountController = TextEditingController();

  bool isPayment = false;
  bool loading = false;

  static const Color _mainColor = Color(0xFF315052);

  Future<void> saveAmount() async {
    if (amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("أدخل المبلغ"),
        ),
      );
      return;
    }

    final enteredAmount = double.tryParse(amountController.text);

    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("أدخل مبلغًا صحيحًا"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final doc = await FirebaseFirestore.instance
        .collection("debts")
        .doc(widget.debtId)
        .get();

    final data = doc.data()!;

    double currentAmount = (data["amount"] as num).toDouble();
    String customerName = data["customerName"] ?? "";

    double newAmount;

    if (isPayment) {
      newAmount = currentAmount - enteredAmount;

      if (newAmount < 0) {
        newAmount = 0;
      }
    } else {
      newAmount = currentAmount + enteredAmount;
    }

    await FirebaseFirestore.instance
        .collection("debts")
        .doc(widget.debtId)
        .update({
      "amount": newAmount,
    });

    await HistoryService().addHistory(
      action: "تعديل مبلغ الدين",
      customerName: customerName,
      amount: newAmount,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newAmount == 0
              ? "تم تسديد الدين بالكامل"
              : "تم تحديث مبلغ الدين",
        ),
      ),
    );

    context.pop();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل مبلغ الدين"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "تعديل مبلغ الدين",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _mainColor,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "يمكنك تعديل مبلغ الدين ثم حفظ التغييرات.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: const Text("إضافة مبلغ"),
                      value: false,
                      groupValue: isPayment,
                      activeColor: _mainColor,
                      onChanged: (value) {
                        setState(() {
                          isPayment = value!;
                        });
                      },
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    RadioListTile<bool>(
                      title: const Text("تسجيل دفعة"),
                      value: true,
                      groupValue: isPayment,
                      activeColor: _mainColor,
                      onChanged: (value) {
                        setState(() {
                          isPayment = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "المبلغ",
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    color: _mainColor,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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
                    borderSide:
                        const BorderSide(color: _mainColor, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : saveAmount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mainColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
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