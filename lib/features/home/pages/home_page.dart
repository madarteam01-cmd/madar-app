import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SortType {
  newest,
  oldest,
  highestAmount,
  lowestAmount,
  nameAZ,
  nameZA,
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  final ValueNotifier<String> search = ValueNotifier("");

  SortType currentSort = SortType.newest;

  static const Color _primaryColor = Color(0xff2E7D32);
  static const Color _brandColor = Color(0xFF315052);

  @override
  void dispose() {
    searchController.dispose();
    search.dispose();
    super.dispose();
  }

  String _sortLabel(SortType type) {
    switch (type) {
      case SortType.newest:
        return "الأحدث";
      case SortType.oldest:
        return "الأقدم";
      case SortType.highestAmount:
        return "الأعلى مبلغًا";
      case SortType.lowestAmount:
        return "الأقل مبلغًا";
      case SortType.nameAZ:
        return "الاسم (أ → ي)";
      case SortType.nameZA:
        return "الاسم (ي → أ)";
    }
  }

  IconData _sortIcon(SortType type) {
    switch (type) {
      case SortType.newest:
        return Icons.arrow_downward;
      case SortType.oldest:
        return Icons.arrow_upward;
      case SortType.highestAmount:
        return Icons.trending_up;
      case SortType.lowestAmount:
        return Icons.trending_down;
      case SortType.nameAZ:
        return Icons.sort_by_alpha;
      case SortType.nameZA:
        return Icons.sort_by_alpha;
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "ترتيب حسب",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...SortType.values.map((type) {
                  final isSelected = currentSort == type;
                  return ListTile(
                    leading: Icon(
                      _sortIcon(type),
                      color: isSelected ? _primaryColor : Colors.grey,
                    ),
                    title: Text(
                      _sortLabel(type),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? _primaryColor : Colors.black,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: _primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        currentSort = type;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // بطاقة إحصائية واحدة داخل الـ Grid
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "مدار | Madar",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              context.push('/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              context.push('/history');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("debts")
            .where(
              "userId",
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("حدث خطأ أثناء تحميل البيانات"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final debts = snapshot.data?.docs ?? [];

          double total = 0;

          for (var debt in debts) {
            total += (debt["amount"] as num).toDouble();
          }

          // ===== حساب الإحصائيات (بدون أي طلب إضافي من Firestore) =====

          // عدد العملاء المختلفين (بدون تكرار)
          final Set<String> uniqueCustomers = {};
          for (var debt in debts) {
            final data = debt.data() as Map<String, dynamic>;
            final name = (data["customerName"] ?? "").toString().trim();
            if (name.isNotEmpty) {
              uniqueCustomers.add(name);
            }
          }
          final int customersCount = uniqueCustomers.length;

          // عدد الديون
          final int debtsCount = debts.length;

          // متوسط الدين
          final double averageDebt =
              debtsCount == 0 ? 0 : total / debtsCount;

          // أكبر دين
          double maxDebt = 0;
          for (var debt in debts) {
            final amount = (debt["amount"] as num?)?.toDouble() ?? 0;
            if (amount > maxDebt) {
              maxDebt = amount;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "تطبيق مدار هو تطبيق جزائري لإدارة ديون المتجرات بسهولة.",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 28),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _brandColor,
                        _brandColor.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _brandColor.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 24,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "إجمالي الديون",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "${total.toStringAsFixed(0)} دج",
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ===== بطاقة الإحصائيات الاحترافية =====
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  children: [
                    _buildStatCard(
                      icon: Icons.people,
                      value: "$customersCount",
                      label: "عدد العملاء",
                      color: _primaryColor,
                    ),
                    _buildStatCard(
                      icon: Icons.receipt_long,
                      value: "$debtsCount",
                      label: "عدد الديون",
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      icon: Icons.bar_chart,
                      value: debtsCount == 0
                          ? "0 دج"
                          : "${averageDebt.toStringAsFixed(0)} دج",
                      label: "متوسط الدين",
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      icon: Icons.trending_up,
                      value: debtsCount == 0
                          ? "0 دج"
                          : "${maxDebt.toStringAsFixed(0)} دج",
                      label: "أكبر دين",
                      color: Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/add-debt');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "إضافة دين",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            context.push('/paid-debts');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "الديون المسددة",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _showSortSheet,
                          icon: const Icon(Icons.sort, size: 18),
                          label: Text(
                            _sortLabel(currentSort),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // TextField ثابت خارج أي rebuild خاص بالبحث نفسه
                // حتى لا يفقد التركيز أثناء الكتابة.
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      // تحديث القيمة فقط، بدون setState،
                      // فقط الودجت اللي بتستمع لـ ValueListenableBuilder
                      // هي اللي بتُعاد بناؤها.
                      search.value = value;
                    },
                    decoration: InputDecoration(
                      hintText: "ابحث عن عميل أو رقم هاتف",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "آخر الديون",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // فقط هذا الجزء يُعاد بناؤه عند الكتابة في البحث،
                // بفضل ValueListenableBuilder، دون التأثير على TextField.
                ValueListenableBuilder<String>(
                  valueListenable: search,
                  builder: (context, searchValue, _) {
                    final query = searchValue.trim().toLowerCase();

                    final filteredDebts = debts.where((debt) {
                      final data = debt.data() as Map<String, dynamic>;

                      final name = (data["customerName"] ?? "")
                          .toString()
                          .toLowerCase();

                      final phone =
                          (data["phone"] ?? "").toString().toLowerCase();

                      return name.contains(query) || phone.contains(query);
                    }).toList();

                    // نسخ القائمة بعد الفلترة ثم فرزها محليًا
                    // بدون الاعتماد على Firestore للترتيب.
                    final sortedDebts = List.from(filteredDebts);

                    sortedDebts.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;

                      switch (currentSort) {
                        case SortType.newest:
                          final tsA = dataA["createdAt"] as Timestamp?;
                          final tsB = dataB["createdAt"] as Timestamp?;
                          if (tsA == null || tsB == null) return 0;
                          return tsB.compareTo(tsA);

                        case SortType.oldest:
                          final tsA = dataA["createdAt"] as Timestamp?;
                          final tsB = dataB["createdAt"] as Timestamp?;
                          if (tsA == null || tsB == null) return 0;
                          return tsA.compareTo(tsB);

                        case SortType.highestAmount:
                          final amountA = (dataA["amount"] as num?) ?? 0;
                          final amountB = (dataB["amount"] as num?) ?? 0;
                          return amountB.compareTo(amountA);

                        case SortType.lowestAmount:
                          final amountA = (dataA["amount"] as num?) ?? 0;
                          final amountB = (dataB["amount"] as num?) ?? 0;
                          return amountA.compareTo(amountB);

                        case SortType.nameAZ:
                          final nameA =
                              (dataA["customerName"] ?? "").toString();
                          final nameB =
                              (dataB["customerName"] ?? "").toString();
                          return nameA.compareTo(nameB);

                        case SortType.nameZA:
                          final nameA =
                              (dataA["customerName"] ?? "").toString();
                          final nameB =
                              (dataB["customerName"] ?? "").toString();
                          return nameB.compareTo(nameA);
                      }
                    });

                    if (sortedDebts.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
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
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "لا توجد نتائج",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedDebts.length,
                      itemBuilder: (context, index) {
                        final debt = sortedDebts[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                context.push('/debt/${debt.id}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            debt["customerName"].toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            debt["phone"].toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${debt["amount"]} دج",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}