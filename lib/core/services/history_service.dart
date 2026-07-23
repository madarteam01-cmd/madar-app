import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  Future<void> addHistory({
    required String action,
    required String customerName,
    required double amount,
  }) async {
    await FirebaseFirestore.instance.collection('history').add({
      'action': action,
      'customerName': customerName,
      'amount': amount,
      'createdAt': Timestamp.now(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }
}