import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Clock {
  late final String userId;

  late final String id;

  late final String environmentId;

  late final DateTime begin;

  DateTime? end, createdAt;

  late final DocumentReference ref;

  bool registered = false;

  Clock(this.userId, this.environmentId, [DateTime? begin, DateTime? end]) {
    begin ??= DateTime.now();
    begin.toUtc();
    id = DateFormat(idFormat).format(begin);
    ref = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("environments")
        .doc(environmentId)
        .collection("clocks")
        .doc(id);
  }

  static String idFormat = "yyyy-MM-ddTkk:mm:ss";

  static String ymdFormat = "yyyy/MM/dd";

  String get ymdFormated => DateFormat(ymdFormat).format(begin);

  static String completeFormat = "yyyy/MM/dd - kk:mm";

  String get bCompleteFormated => DateFormat(completeFormat).format(begin);

  String? get eCompleteFormated =>
      end == null ? null : DateFormat(completeFormat).format(end!);

  static String completeFormatInverse = "kk:mm yyyy/MM/dd";

  String get completeFormatedInverse =>
      DateFormat(completeFormatInverse).format(begin);

  String get day => DateFormat("yyyy/MM/dd").format(begin);

  String get bHour => DateFormat("kk:mm").format(begin);

  String get eHour => end == null ? "--:--" : DateFormat("kk:mm").format(end!);

  String diffenrenceText() {
    if (end == null) return "--:--";
    final diff = end!.difference(begin);
    final hours = diff.inHours;
    return "${hours.toString().padLeft(2, "0")}:${(diff.inMinutes - (hours * 60)).toString().padLeft(2, "0")}";
  }

  Clock.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    ref = doc.reference;
    userId = doc.get("user_id");
    id = doc.id;
    begin = DateTime.parse(id);
    end =
        doc.get("end") == null ? null : (doc.get("end") as Timestamp).toDate();
    createdAt = doc.get("created_at") == null
        ? null
        : (doc.get("created_at") as Timestamp).toDate();
    registered = true;
  }

  Map<String, dynamic> toFirestore() => {
        "id": id,
        "user_id": userId,
        "end": end,
      };

  Future<String> punch() async {
    return await ref.set({
      "id": id,
      "user_id": userId,
      "created_at": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
      "end": end == null ? null : Timestamp.fromDate(end!),
    }).then((value) {
      registered = true;
      return "Clock punched successfully. ;D";
    }).catchError((e) {
      registered = false;
      return "Sorry, we couldn't punch your clock. '-'";
    });
  }

  Future<String> punchEnd(DateTime newEnd) async {
    // if (end == null) {
    //   return "The date wasn't defined for update.";
    // }
    return await ref.update({
      "end": Timestamp.fromDate(newEnd),
      "updated_at": FieldValue.serverTimestamp()
    }).then((val) {
      return "End clock punched successfully. ;D";
    }).catchError((e) {
      return "Sorry, we couldn't punch your clock. '-'";
    });
  }

  Future<String> update(DateTime date) async {
    try {
      if (date != begin) await ref.delete();
      final newClock = Clock(userId, environmentId, date, end);
      await newClock.punch();
      return "From $id to ${newClock.id}";
    } catch (e) {
      return "Erro: $e";
    }
  }

  Future<String> updateLocalData() async {
    try {
      if (registered && createdAt != null) {
        return "Don't need update";
      }

      if (registered) {
        final doc = await ref.get();

        createdAt = (doc.get("created_at") as Timestamp).toDate();

        return "Data updated successfully.";
      } else {
        throw Exception("Can't update data without clock registered.");
      }
    } on FormatException catch (error) {
      return error.message;
    }
  }

  Future<String> delete() async => await ref.delete().then((value) {
        registered = false;
        return "Clock $id was deleted successfully. ;)";
      }).catchError((error) => "Error: $error.");

  @override
  String toString() => id;
}
