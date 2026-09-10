import 'package:hive/hive.dart';

/// A single expense record.
class Expense {
  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.dateTime,
    this.note,
  });

  final String id;
  final double amount;
  final String category;
  final DateTime dateTime;
  final String? note;

  Expense copyWith({
    double? amount,
    String? category,
    DateTime? dateTime,
    String? note,
  }) {
    return Expense(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'dateTime': dateTime.toIso8601String(),
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      note: json['note'] as String?,
    );
  }

  /// Generates a unique id for a new expense.
  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

/// Hand-written Hive adapter (no code generation needed).
class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    return Expense(
      id: reader.readString(),
      amount: reader.readDouble(),
      category: reader.readString(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      note: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.category);
    writer.writeInt(obj.dateTime.millisecondsSinceEpoch);
    final hasNote = obj.note != null && obj.note!.isNotEmpty;
    writer.writeBool(hasNote);
    if (hasNote) {
      writer.writeString(obj.note!);
    }
  }
}
