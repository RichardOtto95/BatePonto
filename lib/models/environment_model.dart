import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Environment {
  DateTime? createdAt;
  String? id;
  final int timeAmount;
  final String title;

  Environment(this.title) : timeAmount = 0;

  Future<String> setUp() async {
    try {
      final envRef = FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("environments")
          .doc();
      await envRef.set({
        "created_at": FieldValue.serverTimestamp(),
        "id": envRef.id,
        "time_amount": 0,
        "title": title,
      });
      final envDoc = await envRef.get();
      createdAt = envDoc.get("created_at");
      id = envRef.id;
      return "Environment created successfully! ;)";
    } catch (e) {
      return "Something get wrong. $e";
    }
  }

  bool get setedUp => id != null;

  static Future<List<Environment>> getEnvironments(String userId) async {
    final qryEnv = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("environments")
        .withConverter<Environment>(
            fromFirestore: Environment.fromFirestore,
            toFirestore: Environment.toFirestore)
        .get();
    final envs = [for (final env in qryEnv.docs) env.data()];
    return envs;
  }

  Environment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? opt,
  )   : createdAt = (doc.get("created_at") as Timestamp).toDate(),
        id = doc.get("id"),
        timeAmount = doc.get("time_amount"),
        title = doc.get("title");

  static Map<String, Object?> toFirestore(
    Environment env,
    SetOptions? opt,
  ) =>
      {
        "created_at": env.createdAt,
        "id": env.id,
        "time_amount": env.timeAmount,
        "title": env.title,
      };
}
