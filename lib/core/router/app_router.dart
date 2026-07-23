import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/settings/pages/settings_page.dart';

import '../../features/debts/pages/add_debt_page.dart';
import '../../features/debts/pages/debt_details_page.dart';
import '../../features/debts/pages/edit_debt_page.dart';
import '../../features/debts/pages/edit_amount_page.dart';
import '../../features/debts/pages/paid_debts_page.dart';
import '../../features/debts/pages/paid_debt_details_page.dart';

import '../../../features/history/presentation/pages/history_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    // تمت إضافة refreshListenable حتى يعيد GoRouter تقييم redirect
    // في كل مرة تتغير فيها حالة تسجيل الدخول (بقاء الجلسة بعد إغلاق التطبيق).
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    // تمت إضافة redirect لحل مشكلة طلب تسجيل الدخول من جديد بعد إغلاق التطبيق.
    // إذا كان المستخدم مسجلاً دخوله بالفعل (currentUser != null) يذهب مباشرة
    // إلى /home، وإلا يبقى/يذهب إلى /login أو /register.
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final goingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn && !goingToAuth) {
        return '/login';
      }
      if (loggedIn && goingToAuth) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),

      GoRoute(
        path: '/add-debt',
        builder: (context, state) => const AddDebtPage(),
      ),

      GoRoute(
        path: '/debt/:id',
        builder: (context, state) => DebtDetailsPage(
          debtId: state.pathParameters["id"]!,
        ),
      ),

      GoRoute(
        path: '/edit-debt/:id',
        builder: (context, state) => EditDebtPage(
          debtId: state.pathParameters["id"]!,
        ),
      ),

      GoRoute(
        path: '/edit-amount/:id',
        builder: (context, state) => EditAmountPage(
          debtId: state.pathParameters["id"]!,
        ),
      ),

      GoRoute(
        path: '/paid-debts',
        builder: (context, state) => const PaidDebtsPage(),
      ),

      GoRoute(
        path: '/paid-debt/:id',
        builder: (context, state) => PaidDebtDetailsPage(
          debtId: state.pathParameters["id"]!,
        ),
      ),

      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
    ],
  );
}

// يجعل GoRouter يستمع لتغيّرات حالة تسجيل الدخول من Firebase
// ويعيد تقييم redirect تلقائياً (مطلوب لحل مشكلة تسجيل الدخول المتكرر).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}