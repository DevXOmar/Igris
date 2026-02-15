import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain.dart';
import '../services/domain_service.dart';

/// State class for Domain management
/// Holds the list of domains and provides methods to manipulate them
class DomainState {
  final List<Domain> domains;
  final bool isLoading;
  
  DomainState({
    required this.domains,
    this.isLoading = false,
  });
  
  DomainState copyWith({
    List<Domain>? domains,
    bool? isLoading,
  }) {
    return DomainState(
      domains: domains ?? this.domains,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  /// Get all active domains
  List<Domain> get activeDomains => domains.where((d) => d.isActive).toList();
  
  /// Get domain by ID
  Domain? getDomainById(String id) {
    try {
      return domains.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Notifier for managing Domain state
/// Handles all domain-related operations and persists to Hive
/// Data flow: UI calls methods -> Notifier updates state -> Hive persists -> State rebuilt
class DomainNotifier extends Notifier<DomainState> {
  final DomainService _service = DomainService();
  
  @override
  DomainState build() {
    // Initialize state by loading domains from Hive
    final domains = _service.getAllDomains();
    return DomainState(domains: domains);
  }
  
  /// Reload domains from storage
  void loadDomains() {
    final domains = _service.getAllDomains();
    state = state.copyWith(domains: domains);
  }
  
  /// Add a new domain
  /// Persists to Hive and updates state
  Future<void> addDomain(Domain domain) async {
    await _service.addDomain(domain);
    loadDomains();
  }
  
  /// Update an existing domain
  /// Persists changes to Hive
  Future<void> updateDomain(Domain domain) async {
    await _service.updateDomain(domain);
    loadDomains();
  }
  
  /// Delete a domain
  Future<void> deleteDomain(String id) async {
    await _service.deleteDomain(id);
    loadDomains();
  }
  
  /// Toggle domain active/inactive status
  Future<void> toggleDomainActive(String id) async {
    await _service.toggleDomainActive(id);
    loadDomains();
  }
  
  /// Update domain strength value
  /// Used when tasks are completed or manually adjusted
  Future<void> updateDomainStrength(String id, int strength) async {
    await _service.updateDomainStrength(id, strength);
    loadDomains();
  }
  
  /// Increment domain strength (when task completed)
  Future<void> incrementDomainStrength(String domainId) async {
    final domain = state.getDomainById(domainId);
    if (domain != null) {
      await updateDomainStrength(domainId, domain.strength + 1);
    }
  }
  
  /// Decrement domain strength (when task completion removed)
  /// Strength cannot go below 0
  Future<void> decrementDomainStrength(String domainId) async {
    final domain = state.getDomainById(domainId);
    if (domain != null && domain.strength > 0) {
      await updateDomainStrength(domainId, domain.strength - 1);
    }
  }
}

/// Global provider for Domain state management
/// Access in UI with: ref.watch(domainProvider) or ref.read(domainProvider.notifier)
final domainProvider = NotifierProvider<DomainNotifier, DomainState>(() {
  return DomainNotifier();
});
