import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/ml_admin_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

/// Écran admin pour la gestion de l'IA de traduction
/// Accès réservé aux admins (dumb@delhomme.ovh, dev@delhomme.ovh)
class MLAdminScreen extends StatefulWidget {
  const MLAdminScreen({super.key});

  @override
  State<MLAdminScreen> createState() => _MLAdminScreenState();
}

class _MLAdminScreenState extends State<MLAdminScreen> {
  final MLAdminService _adminService = MLAdminService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isProcessing = false;
  
  // Rapports d'autocritique (web uniquement)
  List<dynamic> _critiques = [];
  Map<String, dynamic>? _latestCritique;
  bool _isLoadingCritiques = false;
  int _selectedTab = 0; // 0: Stats, 1: Rapports

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    setState(() => _isLoading = true);
    try {
      // Vérifier si l'utilisateur est admin
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      final adminEmails = ['dumb@delhomme.ovh', 'dev@delhomme.ovh'];
      final userEmail = user?.email?.toLowerCase().trim() ?? '';
      final isAdmin = user != null && adminEmails.contains(userEmail);
      
      // Debug: afficher l'email pour vérification
      print('🔍 Vérification admin - Email utilisateur: $userEmail');
      print('🔍 Liste admins: $adminEmails');
      print('🔍 Est admin: $isAdmin');
      
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });

      if (isAdmin) {
        await _loadStats();
        if (kIsWeb) {
          await _loadCritiques();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getStats();
      setState(() {
        _stats = stats['stats'] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCritiques() async {
    if (!kIsWeb) return;
    
    setState(() => _isLoadingCritiques = true);
    try {
      // Charger le dernier rapport
      final latestResponse = await _adminService.getCritiques(latest: true);
      if (latestResponse['critique'] != null) {
        setState(() {
          _latestCritique = latestResponse['critique'] as Map<String, dynamic>;
        });
      }

      // Charger la liste des rapports
      final listResponse = await _adminService.getCritiques(limit: 10);
      setState(() {
        _critiques = listResponse['critiques'] as List<dynamic>? ?? [];
        _isLoadingCritiques = false;
      });
    } catch (e) {
      setState(() => _isLoadingCritiques = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement rapports: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _approveAllFeedbacks() async {
    if (!mounted) return;
    
    // Confirmation avant action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmation requise'),
        content: const Text(
          'Êtes-vous sûr de vouloir approuver TOUS les feedbacks en attente ?\n\n'
          'Cette action est irréversible et entraînera le modèle ML.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Approuver tout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final result = await _adminService.approveAllFeedbacks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Feedbacks approuvés'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        await _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _retrainML() async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Réentraîner le modèle ML'),
        content: const Text(
          'Le réentraînement du modèle ML va démarrer en arrière-plan.\n\n'
          'Cela peut prendre quelques minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final result = await _adminService.retrainML();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Réentraînement démarré'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _retrainNeural() async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧠 Réentraîner le réseau de neurones'),
        content: const Text(
          'Le réentraînement du réseau de neurones va démarrer en arrière-plan.\n\n'
          'Cela peut prendre plusieurs minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final result = await _adminService.retrainNeural();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Réentraînement démarré'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestion IA - Admin'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestion IA - Admin'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Accès refusé',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Cette fonctionnalité est réservée aux administrateurs.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Gestion IA - Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStats();
              if (kIsWeb) _loadCritiques();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: kIsWeb ? TabBar(
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Statistiques'),
            Tab(icon: Icon(Icons.assessment), text: 'Rapports Autocritique'),
          ],
          onTap: (index) {
            setState(() => _selectedTab = index);
          },
        ) : null,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : kIsWeb && _selectedTab == 1
              ? _buildCritiquesTab()
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadStats();
                    if (kIsWeb) await _loadCritiques();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                  // Statistiques
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Statistiques',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_stats != null) ...[
                            final stats = _stats!;
                            _buildStatRow('Total feedbacks', '${stats['total'] ?? 0}'),
                            _buildStatRow('Feedbacks approuvés', '${stats['approved'] ?? 0}'),
                            _buildStatRow('Avec traduction', '${stats['withTranslation'] ?? 0}'),
                            if (stats['byType'] != null) ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const Text(
                                'Par type:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              ...(stats['byType'] as Map<String, dynamic>).entries.map(
                                (e) => _buildStatRow(e.key, '${e.value}', isSubItem: true),
                              ),
                            ],
                          ] else
                            const Text('Chargement...'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions rapides
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '⚡ Actions rapides',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _approveAllFeedbacks,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approuver tous les feedbacks'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _retrainML,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réentraîner le modèle ML'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _retrainNeural,
                            icon: const Icon(Icons.psychology),
                            label: const Text('Réentraîner le réseau de neurones'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Avertissement de sécurité
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '⚠️ Zone sécurisée',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Toutes les actions sont loggées et tracées.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isSubItem = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isSubItem ? 16 : 0, top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSubItem ? 14 : 16,
              fontWeight: isSubItem ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSubItem ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCritiquesTab() {
    if (_isLoadingCritiques) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadCritiques,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dernier rapport
          if (_latestCritique != null) ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assessment, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          '📊 Dernier Rapport d\'Autocritique',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCritiqueSummary(_latestCritique!),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showCritiqueDetails(_latestCritique!),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir le rapport complet'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Liste des rapports précédents
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Historique des Rapports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_critiques.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Aucun rapport disponible'),
                      ),
                    )
                  else
                    ..._critiques.map((critique) => _buildCritiqueListItem(critique)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCritiqueSummary(Map<String, dynamic> critique) {
    final overall = critique['overall'] as Map<String, dynamic>? ?? {};
    final accuracy = overall['accuracy'] as double? ?? 0.0;
    final comparison = critique['comparison'] as Map<String, dynamic>?;
    final trend = comparison?['trend'] as String? ?? 'unknown';
    final accuracyChange = comparison?['metrics']?['accuracy']?['change'] as double? ?? 0.0;

    Color trendColor;
    IconData trendIcon;
    String trendText;
    switch (trend) {
      case 'improving':
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        trendText = 'Amélioration';
        break;
      case 'degrading':
        trendColor = Colors.red;
        trendIcon = Icons.trending_down;
        trendText = 'Dégradation';
        break;
      default:
        trendColor = Colors.grey;
        trendIcon = Icons.trending_flat;
        trendText = 'Stable';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricCard('Précision', '${accuracy.toStringAsFixed(1)}%', Colors.blue),
            _buildMetricCard('Tests', '${overall['totalTests'] ?? 0}', Colors.orange),
            _buildMetricCard('Feedbacks', '${overall['totalFeedbacks'] ?? 0}', Colors.purple),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: trendColor),
          ),
          child: Row(
            children: [
              Icon(trendIcon, color: trendColor),
              const SizedBox(width: 8),
              Text(
                'Tendance: $trendText',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
              if (accuracyChange != 0) ...[
                const SizedBox(width: 8),
                Text(
                  '(${accuracyChange > 0 ? '+' : ''}${accuracyChange.toStringAsFixed(1)}%)',
                  style: TextStyle(color: trendColor),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSmallMetric('Points forts', '${critique['strengthsCount'] ?? 0}', Colors.green),
            _buildSmallMetric('Points faibles', '${critique['weaknessesCount'] ?? 0}', Colors.red),
            _buildSmallMetric('Défis', '${critique['challengesCount'] ?? 0}', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSmallMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCritiqueListItem(Map<String, dynamic> critique) {
    final timestamp = critique['timestamp'] as String?;
    final date = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(timestamp))
        : 'Date inconnue';
    final accuracy = (critique['overall'] as Map<String, dynamic>?)?['accuracy'] as double? ?? 0.0;
    final trend = critique['trend'] as String? ?? 'unknown';

    Color trendColor;
    IconData trendIcon;
    switch (trend) {
      case 'improving':
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        break;
      case 'degrading':
        trendColor = Colors.red;
        trendIcon = Icons.trending_down;
        break;
      default:
        trendColor = Colors.grey;
        trendIcon = Icons.trending_flat;
    }

    return ListTile(
      leading: Icon(trendIcon, color: trendColor),
      title: Text('Rapport du $date'),
      subtitle: Text('Précision: ${accuracy.toStringAsFixed(1)}%'),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () async {
          try {
            final fullCritique = await _adminService.getCritique(critique['id'] as String);
            if (mounted && fullCritique['critique'] != null) {
              _showCritiqueDetails(fullCritique['critique'] as Map<String, dynamic>);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showCritiqueDetails(Map<String, dynamic> critique) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: kIsWeb ? 800 : double.infinity,
          height: kIsWeb ? 600 : double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📊 Rapport d\'Autocritique Complet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCritiqueSection('✅ Points Forts', critique['strengths'] as List<dynamic>? ?? []),
                      _buildCritiqueSection('❌ Points Faibles', critique['weaknesses'] as List<dynamic>? ?? []),
                      _buildCritiqueSection('💡 Recommandations', critique['recommendations'] as List<dynamic>? ?? []),
                      _buildCritiqueSection('🎯 Défis', critique['challenges'] as List<dynamic>? ?? []),
                      if (critique['comparison'] != null)
                        _buildComparisonSection(critique['comparison'] as Map<String, dynamic>),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCritiqueSection(String title, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item['description'] ?? item['action'] ?? ''),
                  subtitle: item['evidence'] != null
                      ? Text(item['evidence'] as String)
                      : null,
                  isThreeLine: item['evidence'] != null,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(Map<String, dynamic> comparison) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Comparaison',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (comparison['improvements'] != null)
            ...(comparison['improvements'] as List<dynamic>).map((imp) => Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(imp['metric'] ?? ''),
                    subtitle: Text(imp['description'] ?? ''),
                  ),
                )),
          if (comparison['degradations'] != null)
            ...(comparison['degradations'] as List<dynamic>).map((deg) => Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(deg['metric'] ?? ''),
                    subtitle: Text(deg['description'] ?? ''),
                  ),
                )),
        ],
      ),
    );
  }
}

