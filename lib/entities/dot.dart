import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Dot {
  late final String userId;

  late final String id;

  late final DateTime date;

  late final DocumentReference ref;

  DateTime? createdAt;

  bool registered = false;

  Dot(this.userId, [DateTime? dateId]) {
    date = dateId ?? DateTime.now();
    date.toUtc();
    id = DateFormat(idFormat).format(date);
    ref = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("dots")
        .doc(id);
  }

  static String idFormat = "yyyy-MM-ddTkk:mm:ss";

  static String ymdFormat = "yyyy/MM/dd";

  String get ymdFormated => DateFormat(ymdFormat).format(date);

  static String completeFormat = "yyyy/MM/dd - kk:mm";

  String get completeFormated => DateFormat(completeFormat).format(date);

  static String completeFormatInverse = "kk:mm yyyy/MM/dd";

  String get completeFormatedInverse =>
      DateFormat(completeFormatInverse).format(date);

  String get day => DateFormat("yyyy/MM/dd").format(date);

  String get hour => DateFormat("kk:mm").format(date);

  Dot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    ref = doc.reference;
    userId = doc.get("user_id");
    id = doc.id;
    date = DateTime.parse(id);
    createdAt =
        ((doc.get("created_at") ?? Timestamp.now()) as Timestamp).toDate();
    registered = true;
  }

  Map<String, dynamic> toFirestore() => {"id": id, "user_id": userId};

  Future<String> register() async => await ref.set({
        "id": id,
        "user_id": userId,
        "created_at": FieldValue.serverTimestamp(),
      }).then((value) {
        registered = true;
        return "Dot registered successfully. ;D";
      }).catchError((e) {
        registered = false;
        return "Sorry, we couldn't register your dot '-'.";
      });

  Future<String> update(DateTime date) async {
    try {
      await ref.delete();
      final newDot = Dot(userId, date);
      await newDot.register();
      return "From $id to ${newDot.id}";
    } catch (e) {
      return "Erro: $e";
    }
  }

  Future<String> updateData() async {
    try {
      if (registered && createdAt != null) {
        return "Don't need update";
      }

      if (registered) {
        final doc = await ref.get();

        createdAt = (doc.get("created_at") as Timestamp).toDate();

        return "Data updated successfully.";
      } else {
        throw Exception("Can't update data without dot registered.");
      }
    } on FormatException catch (error) {
      return error.message;
    }
  }

  Future<String> delete() async => await ref.delete().then((value) {
        registered = false;
        return "Dot $id was deleted successfully. ;)";
      }).catchError((error) => "Error: $error.");

  @override
  String toString() => id;
}
