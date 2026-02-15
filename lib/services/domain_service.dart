import 'package:hive/hive.dart';
import '../models/domain.dart';

/// Service for managing Domain data in Hive
class DomainService {
  static const String _boxName = 'domainsBox';
  
  /// Get the domains box
  Box<Domain> get _box => Hive.box<Domain>(_boxName);
  
  /// Get all domains
  List<Domain> getAllDomains() {
    return _box.values.toList();
  }
  
  /// Get all active domains
  List<Domain> getActiveDomains() {
    return _box.values.where((domain) => domain.isActive).toList();
  }
  
  /// Get a domain by ID
  Domain? getDomainById(String id) {
    return _box.values.firstWhere(
      (domain) => domain.id == id,
      orElse: () => throw Exception('Domain not found'),
    );
  }
  
  /// Add a new domain
  Future<void> addDomain(Domain domain) async {
    await _box.put(domain.id, domain);
  }
  
  /// Update a domain
  Future<void> updateDomain(Domain domain) async {
    await _box.put(domain.id, domain);
  }
  
  /// Delete a domain
  Future<void> deleteDomain(String id) async {
    await _box.delete(id);
  }
  
  /// Toggle domain active status
  Future<void> toggleDomainActive(String id) async {
    final domain = getDomainById(id);
    if (domain != null) {
      final updated = domain.copyWith(isActive: !domain.isActive);
      await updateDomain(updated);
    }
  }
  
  /// Update domain strength
  Future<void> updateDomainStrength(String id, int strength) async {
    final domain = getDomainById(id);
    if (domain != null) {
      final updated = domain.copyWith(strength: strength);
      await updateDomain(updated);
    }
  }
  
  /// Clear all domains (for testing/reset)
  Future<void> clearAll() async {
    await _box.clear();
  }
}
