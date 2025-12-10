#!/usr/bin/env python3
"""
Exporte les données de feedback utilisateur pour l'entraînement du modèle de traduction
"""

import json
import sys
from pathlib import Path
from datetime import datetime

PROJECT_ROOT = Path(__file__).parent.parent

# Couleurs
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
RED = '\033[0;31m'
NC = '\033[0m'

def export_training_data():
    """Exporte les données de feedback pour l'entraînement"""
    print(f"{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{BLUE}📤 Export des données d'entraînement pour le modèle de traduction{NC}")
    print(f"{BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")
    
    # Note: Les données sont stockées dans SharedPreferences de Flutter
    # Pour l'instant, on crée un fichier d'exemple de format
    # L'export réel nécessiterait d'accéder aux données Flutter
    
    export_file = PROJECT_ROOT / 'training_data' / 'translation_feedbacks.json'
    export_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Format d'exemple pour l'entraînement
    training_data = {
        'metadata': {
            'exportDate': datetime.now().isoformat(),
            'format': 'translation_feedback',
            'version': '1.0.0',
        },
        'instructions': {
            'format': 'original_text -> target_language -> suggested_translation',
            'example': {
                'original': 'Heat the oil in a large pan',
                'current': 'Chauffer l\'huile dans une grande poêle',
                'suggested': 'Faites chauffer l\'huile dans une grande poêle',
                'language': 'fr',
                'confidence': 1.0,
            }
        },
        'ingredients': {
            'format': 'original_text -> target_language -> suggested_translation',
            'example': {
                'original': 'chicken',
                'current': 'Poulet',
                'suggested': 'Poulet',
                'language': 'fr',
                'confidence': 1.0,
            }
        },
        'recipe_names': {
            'format': 'original_text -> target_language -> suggested_translation',
            'example': {
                'original': 'Chicken Curry',
                'current': 'Curry de Poulet',
                'suggested': 'Curry au Poulet',
                'language': 'fr',
                'confidence': 1.0,
            }
        },
        'note': 'Les données réelles seront exportées depuis l\'application Flutter via TranslationFeedbackService.exportFeedbacksForTraining()',
    }
    
    with open(export_file, 'w', encoding='utf-8') as f:
        json.dump(training_data, f, ensure_ascii=False, indent=2)
    
    print(f"{GREEN}✅ Format d'export créé: {export_file}{NC}")
    print(f"\n{YELLOW}📝 Note:{NC}")
    print(f"   Pour exporter les données réelles depuis l'application Flutter,")
    print(f"   utilisez: TranslationFeedbackService.exportFeedbacksForTraining()")
    print(f"   dans l'application et copiez le résultat dans ce fichier.")
    print(f"\n{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")

if __name__ == '__main__':
    try:
        export_training_data()
    except KeyboardInterrupt:
        print(f"\n\n{GREEN}👋 Au revoir!{NC}\n")
        sys.exit(0)

