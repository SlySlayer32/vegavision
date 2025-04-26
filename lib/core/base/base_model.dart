/// Base class for all models to ensure consistent serialization behavior
abstract class BaseModel {
  /// Convert model to JSON representation
  Map<String, dynamic> toJson();

  /// Create a copy of the model with updated fields
  BaseModel copyWith();

  /// Compare model with another instance
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseModel &&
        other.runtimeType == runtimeType &&
        other.toJson().toString() == toJson().toString();
  }

  /// Generate hashcode based on JSON representation
  @override
  int get hashCode => toJson().toString().hashCode;

  /// String representation of the model
  @override
  String toString() {
    return '${runtimeType.toString()}(${toJson()})';
  }
}
