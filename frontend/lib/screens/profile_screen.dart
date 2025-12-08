import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  UserProfile? _currentProfile;
  List<UserProfile> _profiles = [];
  bool _isLoading = true;
  User? _currentUser; // Utilisateur connecté (avec email)

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final profiles = await _profileService.getAllProfiles();
    final current = await _profileService.getCurrentProfile();
    
    // Si aucun profil n'existe, créer un profil par défaut
    if (profiles.isEmpty && current == null) {
      final defaultProfile = await _profileService.createDefaultProfile();
      setState(() {
        _profiles = [defaultProfile];
        _currentProfile = defaultProfile;
        _isLoading = false;
      });
    } else {
      setState(() {
        _profiles = profiles;
        _currentProfile = current;
        _isLoading = false;
      });
    }
  }

  Future<void> _setCurrentProfile(UserProfile profile) async {
    await _profileService.setCurrentProfile(profile.id);
    await _loadProfiles();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil "${profile.name}" sélectionné'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteProfile(UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le profil'),
        content: Text(
          'Voulez-vous supprimer le profil "${profile.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _profileService.deleteProfile(profile.id);
      await _loadProfiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil supprimé')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barre d'actions personnalisée
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddProfileDialog(),
                      tooltip: 'Ajouter un profil',
                    ),
                  ],
                ),
                if (_currentUser != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentUser!.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _profiles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Aucun profil',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Créez un profil pour adapter les recettes au nombre de personnes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _showAddProfileDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Créer un profil'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _profiles.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          final isCurrent = _currentProfile?.id == profile.id;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: isCurrent ? 4 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: isCurrent
                                  ? BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: InkWell(
                              onTap: () {
                                // Si ce n'est pas le profil actuel, le sélectionner
                                if (!isCurrent) {
                                  _setCurrentProfile(profile);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer
                                            .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    color: isCurrent
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                    size: 28,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                  Expanded(
                                    child: Text(
                                      profile.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isCurrent
                                            ? Theme.of(context).colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Actif',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${profile.numberOfPeople} ${profile.numberOfPeople > 1 ? 'personnes' : 'personne'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isCurrent)
                                    IconButton(
                                      icon: Icon(
                                        Icons.check_circle_outline,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      onPressed: () => _setCurrentProfile(profile),
                                      tooltip: 'Sélectionner',
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    onPressed: () => _showEditProfileDialog(profile),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () => _deleteProfile(profile),
                                    tooltip: 'Supprimer',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      // Appeler le callback de déconnexion pour mettre à jour l'état
      if (widget.onLogout != null) {
        widget.onLogout!();
      }
      // Rediriger vers la page de connexion
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }

  Future<void> _showAddProfileDialog([UserProfile? profile]) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: profile?.name ?? '',
    );
    int numberOfPeople = profile?.numberOfPeople ?? 2;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(profile == null ? 'Nouveau profil' : 'Modifier le profil'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du profil',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nombre de personnes: $numberOfPeople',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: numberOfPeople.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '$numberOfPeople',
                    onChanged: (value) {
                      setDialogState(() => numberOfPeople = value.toInt());
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final updatedProfile = (profile ?? UserProfile(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: '',
                    numberOfPeople: 2,
                  )).copyWith(
                    name: nameController.text.trim(),
                    numberOfPeople: numberOfPeople,
                  );
                  
                  Navigator.pop(context);
                  _saveProfile(updatedProfile);
                }
              },
              child: Text(profile == null ? 'Créer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(UserProfile profile) async {
    await _showAddProfileDialog(profile);
  }

  Future<void> _saveProfile(UserProfile profile) async {
    await _profileService.saveProfile(profile);
    await _loadProfiles();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil "${profile.name}" ${profile.id.contains(DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)) ? 'créé' : 'modifié'}'),
        ),
      );
    }
  }
}
