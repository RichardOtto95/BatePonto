import 'package:cloud_firestore/cloud_firestore.dart';

class Services {
  Future<bool> hitTimeSpot(DateTime date) async {
    String userId = "";
    final docRef =
        FirebaseFirestore.instance.collection("USERS/$userId/SPOTS").doc();
    return await docRef
        .set({
          "date": date,
          "user_id": userId,
          "id": docRef.id,
        })
        .onError((error, stackTrace) => false)
        .then((val) => true);
  }

  Future<bool> hitSpot() async => await hitTimeSpot(DateTime.now());
}
