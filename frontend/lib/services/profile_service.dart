import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  static const String _profileKey = 'user_profile';
  static const String _currentProfileKey = 'current_profile_id';

  // Obtenir le profil actuel
  Future<UserProfile?> getCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentId = prefs.getString(_currentProfileKey);
      
      if (currentId == null) {
        return null;
      }

      final profile = await getProfile(currentId);
      return profile;
    } catch (e) {
      print('Erreur lors de la récupération du profil actuel: $e');
      return null;
    }
  }

  // Définir le profil actuel
  Future<bool> setCurrentProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_currentProfileKey, profileId);
    } catch (e) {
      print('Erreur lors de la définition du profil actuel: $e');
      return false;
    }
  }

  // Obtenir un profil par ID
  Future<UserProfile?> getProfile(String id) async {
    try {
      final profiles = await getAllProfiles();
      return profiles.firstWhere(
        (profile) => profile.id == id,
        orElse: () => throw Exception('Profil non trouvé'),
      );
    } catch (e) {
      return null;
    }
  }

  // Obtenir tous les profils
  Future<List<UserProfile>> getAllProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_profileKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des profils: $e');
      return [];
    }
  }

  // Sauvegarder tous les profils
  Future<bool> saveProfiles(List<UserProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(
        profiles.map((profile) => profile.toJson()).toList(),
      );
      return await prefs.setString(_profileKey, jsonString);
    } catch (e) {
      print('Erreur lors de la sauvegarde des profils: $e');
      return false;
    }
  }

  // Ajouter ou mettre à jour un profil
  Future<bool> saveProfile(UserProfile profile) async {
    try {
      final profiles = await getAllProfiles();
      final index = profiles.indexWhere((p) => p.id == profile.id);
      
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
        createdAt: index == -1 ? DateTime.now() : profile.createdAt,
      );

      if (index == -1) {
        profiles.add(updatedProfile);
      } else {
        profiles[index] = updatedProfile;
      }

      return await saveProfiles(profiles);
    } catch (e) {
      print('Erreur lors de la sauvegarde du profil: $e');
      return false;
    }
  }

  // Supprimer un profil
  Future<bool> deleteProfile(String id) async {
    try {
      final profiles = await getAllProfiles();
      profiles.removeWhere((profile) => profile.id == id);
      
      // Si c'était le profil actuel, le retirer
      final prefs = await SharedPreferences.getInstance();
      final currentId = prefs.getString(_currentProfileKey);
      if (currentId == id) {
        await prefs.remove(_currentProfileKey);
      }

      return await saveProfiles(profiles);
    } catch (e) {
      print('Erreur lors de la suppression du profil: $e');
      return false;
    }
  }

  // Créer un profil par défaut
  Future<UserProfile> createDefaultProfile() async {
    final defaultProfile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Famille',
      numberOfPeople: 2,
      createdAt: DateTime.now(),
    );
    
    await saveProfile(defaultProfile);
    await setCurrentProfile(defaultProfile.id);
    
    return defaultProfile;
  }
}

