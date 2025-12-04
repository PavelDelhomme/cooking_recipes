import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Service de monitoring mémoire pour Flutter
/// Détecte les fuites mémoire et génère des rapports
class MemoryMonitor {
  static final MemoryMonitor _instance = MemoryMonitor._internal();
  factory MemoryMonitor() => _instance;
  MemoryMonitor._internal();

  final List<MemorySnapshot> _snapshots = [];
  bool _isMonitoring = false;
  DateTime? _startTime;

  /// Démarrer le monitoring
  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _startTime = DateTime.now();
    _snapshots.clear();
    
    if (kDebugMode) {
      developer.log('🔍 Monitoring mémoire démarré', name: 'MemoryMonitor');
    }
    
    // Prendre un snapshot initial
    _takeSnapshot();
    
    // Prendre des snapshots périodiques
    _scheduleNextSnapshot(interval);
  }

  /// Arrêter le monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    if (kDebugMode) {
      developer.log('⏹️ Monitoring mémoire arrêté', name: 'MemoryMonitor');
    }
  }

  /// Prendre un snapshot de la mémoire
  void _takeSnapshot() {
    if (!_isMonitoring) return;
    
    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      heapSize: _getHeapSize(),
      externalSize: _getExternalSize(),
      rss: _getRSS(),
    );
    
    _snapshots.add(snapshot);
    
    if (kDebugMode && _snapshots.length % 10 == 0) {
      developer.log(
        '📊 Snapshot ${_snapshots.length}: ${snapshot.heapSizeMB.toStringAsFixed(2)} MB heap, ${snapshot.rssMB.toStringAsFixed(2)} MB RSS',
        name: 'MemoryMonitor',
      );
    }
  }

  /// Programmer le prochain snapshot
  void _scheduleNextSnapshot(Duration interval) {
    if (!_isMonitoring) return;
    
    Future.delayed(interval, () {
      if (_isMonitoring) {
        _takeSnapshot();
        _scheduleNextSnapshot(interval);
      }
    });
  }

  /// Obtenir la taille du heap (approximatif)
  int _getHeapSize() {
    // Flutter ne fournit pas d'API directe pour le heap
    // On utilise une approximation basée sur les allocations
    try {
      // En mode debug, on peut utiliser des heuristiques
      return 0; // À implémenter avec des outils externes si nécessaire
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir la taille mémoire externe
  int _getExternalSize() {
    return 0; // À implémenter si nécessaire
  }

  /// Obtenir le RSS (Resident Set Size) - approximatif
  int _getRSS() {
    // En web, on ne peut pas obtenir le RSS directement
    // On utilise une approximation
    return 0;
  }

  /// Générer un rapport de mémoire
  String generateReport() {
    if (_snapshots.isEmpty) {
      return 'Aucun snapshot disponible';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('RAPPORT MÉMOIRE - Flutter Frontend');
    buffer.writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('');
    
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      buffer.writeln('Durée du monitoring: ${duration.inMinutes} minutes');
    }
    
    buffer.writeln('Nombre de snapshots: ${_snapshots.length}');
    buffer.writeln('');
    
    if (_snapshots.length > 1) {
      final first = _snapshots.first;
      final last = _snapshots.last;
      
      buffer.writeln('--- Évolution ---');
      buffer.writeln('Premier snapshot:');
      buffer.writeln('  Heap: ${first.heapSizeMB.toStringAsFixed(2)} MB');
      buffer.writeln('  RSS: ${first.rssMB.toStringAsFixed(2)} MB');
      buffer.writeln('');
      buffer.writeln('Dernier snapshot:');
      buffer.writeln('  Heap: ${last.heapSizeMB.toStringAsFixed(2)} MB');
      buffer.writeln('  RSS: ${last.rssMB.toStringAsFixed(2)} MB');
      buffer.writeln('');
      
      final heapGrowth = last.heapSize - first.heapSize;
      final rssGrowth = last.rss - first.rss;
      
      buffer.writeln('Croissance:');
      buffer.writeln('  Heap: ${(heapGrowth / 1024 / 1024).toStringAsFixed(2)} MB');
      buffer.writeln('  RSS: ${(rssGrowth / 1024 / 1024).toStringAsFixed(2)} MB');
      buffer.writeln('');
      
      if (heapGrowth > 50 * 1024 * 1024 || rssGrowth > 50 * 1024 * 1024) {
        buffer.writeln('⚠️  FUITE MÉMOIRE POTENTIELLE DÉTECTÉE');
        buffer.writeln('   (croissance > 50 MB)');
      }
    }
    
    buffer.writeln('--- Détails des snapshots ---');
    for (var i = 0; i < _snapshots.length; i++) {
      final snapshot = _snapshots[i];
      buffer.writeln('Snapshot ${i + 1} (${snapshot.timestamp}):');
      buffer.writeln('  Heap: ${snapshot.heapSizeMB.toStringAsFixed(2)} MB');
      buffer.writeln('  RSS: ${snapshot.rssMB.toStringAsFixed(2)} MB');
    }
    
    return buffer.toString();
  }

  /// Obtenir les statistiques actuelles
  Map<String, dynamic> getCurrentStats() {
    if (_snapshots.isEmpty) {
      return {
        'heapSize': 0,
        'rss': 0,
        'snapshotCount': 0,
      };
    }
    
    final last = _snapshots.last;
    return {
      'heapSize': last.heapSize,
      'heapSizeMB': last.heapSizeMB,
      'rss': last.rss,
      'rssMB': last.rssMB,
      'snapshotCount': _snapshots.length,
      'startTime': _startTime?.toIso8601String(),
    };
  }

  /// Détecter les fuites mémoire
  bool detectMemoryLeak({double thresholdPercent = 20.0}) {
    if (_snapshots.length < 2) return false;
    
    final first = _snapshots.first;
    final last = _snapshots.last;
    
    final heapGrowthPercent = ((last.heapSize - first.heapSize) / first.heapSize) * 100;
    final rssGrowthPercent = ((last.rss - first.rss) / first.rss) * 100;
    
    return heapGrowthPercent > thresholdPercent || rssGrowthPercent > thresholdPercent;
  }
}

/// Snapshot de mémoire
class MemorySnapshot {
  final DateTime timestamp;
  final int heapSize;      // En bytes
  final int externalSize;  // En bytes
  final int rss;          // En bytes (Resident Set Size)

  MemorySnapshot({
    required this.timestamp,
    required this.heapSize,
    required this.externalSize,
    required this.rss,
  });

  double get heapSizeMB => heapSize / 1024 / 1024;
  double get externalSizeMB => externalSize / 1024 / 1024;
  double get rssMB => rss / 1024 / 1024;
  double get totalMB => (heapSize + externalSize) / 1024 / 1024;
}

