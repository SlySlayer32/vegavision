import 'dart:convert';
import 'package:hive/hive.dart';

class CacheService {
  final Box _box;
  final Duration defaultExpiry;

  CacheService(this._box, {this.defaultExpiry = const Duration(days: 1)});

  Future<void> put(String key, dynamic value, {Duration? expiry}) async {
    final expiryTime = DateTime.now().add(expiry ?? defaultExpiry);
    await _box.put(
      key,
      json.encode({'value': value, 'expiry': expiryTime.toIso8601String()}),
    );
  }

  T? get<T>(String key) {
    final data = _box.get(key);
    if (data == null) return null;

    final decoded = json.decode(data);
    final expiry = DateTime.parse(decoded['expiry']);

    if (DateTime.now().isAfter(expiry)) {
      _box.delete(key);
      return null;
    }

    return decoded['value'] as T;
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  bool hasValid(String key) {
    final data = _box.get(key);
    if (data == null) return false;

    final decoded = json.decode(data);
    final expiry = DateTime.parse(decoded['expiry']);
    return DateTime.now().isBefore(expiry);
  }

  Future<void> clearExpired() async {
    final keys = _box.keys.toList();
    for (final key in keys) {
      final data = _box.get(key);
      if (data == null) continue;

      final decoded = json.decode(data);
      final expiry = DateTime.parse(decoded['expiry']);
      if (DateTime.now().isAfter(expiry)) {
        await _box.delete(key);
      }
    }
  }
}
