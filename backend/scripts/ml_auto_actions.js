/**
 * Système d'actions automatiques basé sur les défis de l'autocritique
 * Exécute automatiquement des actions pour améliorer le système ML
 * Usage: node backend/scripts/ml_auto_actions.js
 */

const mlTranslationEngine = require('../src/services/ml_translation_engine');
const { getDatabase } = require('../src/database/db');
const fs = require('fs');
const path = require('path');
const mlAutoValidator = require('./ml_auto_validator');
const mlContinuousLearning = require('./ml_continuous_learning');

class MLAutoActions {
  constructor() {
    this.db = getDatabase();
    this.critiqueDir = path.join(__dirname, '../data/ml_critiques');
    this.logsDir = path.join(__dirname, '../logs');
    this.actionsHistoryFile = path.join(this.critiqueDir, 'actions_history.json');
    
    // Créer les dossiers nécessaires
    if (!fs.existsSync(this.critiqueDir)) {
      fs.mkdirSync(this.critiqueDir, { recursive: true });
    }
    if (!fs.existsSync(this.logsDir)) {
      fs.mkdirSync(this.logsDir, { recursive: true });
    }
    
    // Charger l'historique des actions
    this.actionsHistory = this.loadActionsHistory();
  }

  /**
   * Charge l'historique des actions
   */
  loadActionsHistory() {
    try {
      if (fs.existsSync(this.actionsHistoryFile)) {
        const content = fs.readFileSync(this.actionsHistoryFile, 'utf8');
        return JSON.parse(content);
      }
    } catch (error) {
      console.warn('⚠️ Erreur chargement historique actions:', error.message);
    }
    return [];
  }

  /**
   * Sauvegarde l'historique des actions
   */
  saveActionsHistory() {
    try {
      fs.writeFileSync(this.actionsHistoryFile, JSON.stringify(this.actionsHistory, null, 2), 'utf8');
    } catch (error) {
      console.warn('⚠️ Erreur sauvegarde historique actions:', error.message);
    }
  }

  /**
   * Enregistre une action dans l'historique
   */
  logAction(action, result) {
    const actionLog = {
      timestamp: new Date().toISOString(),
      action,
      result,
    };
    this.actionsHistory.push(actionLog);
    
    // Garder seulement les 100 dernières actions
    if (this.actionsHistory.length > 100) {
      this.actionsHistory = this.actionsHistory.slice(-100);
    }
    
    this.saveActionsHistory();
    console.log(`✅ Action exécutée: ${action.type} - ${result.success ? 'Succès' : 'Échec'}`);
  }

  /**
   * Charge le dernier rapport d'autocritique
   */
  loadLatestCritique() {
    const latestFile = path.join(this.critiqueDir, 'latest_self_critique.json');
    try {
      if (fs.existsSync(latestFile)) {
        const content = fs.readFileSync(latestFile, 'utf8');
        return JSON.parse(content);
      }
    } catch (error) {
      console.warn('⚠️ Erreur chargement rapport autocritique:', error.message);
    }
    return null;
  }

  /**
   * Exécute les actions automatiques basées sur les défis
   */
  async executeAutoActions() {
    console.log('🤖 ========================================');
    console.log('🤖 ACTIONS AUTOMATIQUES BASÉES SUR L\'AUTOCRITIQUE');
    console.log('🤖 ========================================');
    console.log('');

    const critique = this.loadLatestCritique();
    if (!critique || !critique.challenges || critique.challenges.length === 0) {
      console.log('ℹ️  Aucun défi à traiter pour le moment.');
      return { executed: 0, results: [] };
    }

    console.log(`📋 ${critique.challenges.length} défi(s) détecté(s)\n`);

    const results = [];
    let executedCount = 0;

    for (const challenge of critique.challenges) {
      console.log(`\n🎯 Traitement du défi: ${challenge.title}`);
      console.log(`   Description: ${challenge.description}`);
      console.log(`   Priorité: ${challenge.priority}`);

      try {
        const result = await this.executeChallenge(challenge);
        results.push({
          challengeId: challenge.id,
          challengeTitle: challenge.title,
          success: result.success,
          message: result.message,
          actionsExecuted: result.actionsExecuted || [],
        });

        if (result.success) {
          executedCount++;
          this.logAction({ type: challenge.id, challenge }, result);
        }
      } catch (error) {
        console.error(`❌ Erreur lors du traitement du défi ${challenge.id}:`, error.message);
        results.push({
          challengeId: challenge.id,
          challengeTitle: challenge.title,
          success: false,
          error: error.message,
        });
      }
    }

    console.log('\n📊 ========================================');
    console.log('📊 RÉSUMÉ DES ACTIONS');
    console.log('📊 ========================================');
    console.log(`✅ Actions exécutées avec succès: ${executedCount}`);
    console.log(`❌ Actions échouées: ${results.length - executedCount}`);
    console.log('');

    return { executed: executedCount, results };
  }

  /**
   * Exécute une action spécifique basée sur un défi
   */
  async executeChallenge(challenge) {
    const actionsExecuted = [];
    let success = false;
    let message = '';

    switch (challenge.id) {
      case 'fix_persistent_errors':
        // Corriger les erreurs persistantes
        const fixResult = await this.fixPersistentErrors(challenge);
        actionsExecuted.push(...fixResult.actions);
        success = fixResult.success;
        message = fixResult.message;
        break;

      case 'approve_pending_feedbacks':
      case 'validate_pending':
        // Valider les feedbacks en attente
        const approveResult = await this.approvePendingFeedbacks(challenge);
        actionsExecuted.push(...approveResult.actions);
        success = approveResult.success;
        message = approveResult.message;
        break;

      case 'improve_accuracy':
        // Améliorer la précision
        const improveResult = await this.improveAccuracy(challenge);
        actionsExecuted.push(...improveResult.actions);
        success = improveResult.success;
        message = improveResult.message;
        break;

      case 'reduce_weaknesses':
        // Réduire les points faibles
        const reduceResult = await this.reduceWeaknesses(challenge);
        actionsExecuted.push(...reduceResult.actions);
        success = reduceResult.success;
        message = reduceResult.message;
        break;

      case 'recover_performance':
      case 'trend_recovery':
        // Récupérer la performance
        const recoverResult = await this.recoverPerformance(challenge);
        actionsExecuted.push(...recoverResult.actions);
        success = recoverResult.success;
        message = recoverResult.message;
        break;

      case 'maintain_improvement':
        // Maintenir l'amélioration
        const maintainResult = await this.maintainImprovement(challenge);
        actionsExecuted.push(...maintainResult.actions);
        success = maintainResult.success;
        message = maintainResult.message;
        break;

      case 'reach_70_accuracy':
        // Atteindre 70% de précision
        const reachResult = await this.reach70Accuracy(challenge);
        actionsExecuted.push(...reachResult.actions);
        success = reachResult.success;
        message = reachResult.message;
        break;

      default:
        message = `Type de défi non reconnu: ${challenge.id}`;
        success = false;
    }

    return { success, message, actionsExecuted };
  }

  /**
   * Corrige les erreurs persistantes
   */
  async fixPersistentErrors(challenge) {
    const actions = [];
    let success = false;
    let message = '';

    try {
      // 1. Valider automatiquement les feedbacks qui corrigent ces erreurs
      console.log('   → Validation automatique des feedbacks pertinents...');
      const validationResult = await mlAutoValidator.validatePendingFeedbacks();
      actions.push('Validation automatique des feedbacks');
      
      if (validationResult.approved > 0) {
        // 2. Réentraîner le modèle avec les nouvelles données
        console.log('   → Réentraînement du modèle...');
        await mlTranslationEngine.retrain();
        actions.push('Réentraînement du modèle');
        success = true;
        message = `${validationResult.approved} feedback(s) validé(s) et modèle réentraîné`;
      } else {
        message = 'Aucun feedback pertinent trouvé pour correction automatique';
      }
    } catch (error) {
      message = `Erreur lors de la correction: ${error.message}`;
    }

    return { success, message, actions };
  }

  /**
   * Approuve les feedbacks en attente
   */
  async approvePendingFeedbacks(challenge) {
    const actions = [];
    let success = false;
    let message = '';

    try {
      console.log('   → Validation automatique des feedbacks en attente...');
      const validationResult = await mlAutoValidator.validatePendingFeedbacks();
      actions.push('Validation automatique des feedbacks');
      
      if (validationResult.approved > 0) {
        // Réentraîner après validation
        console.log('   → Réentraînement du modèle...');
        await mlTranslationEngine.retrain();
        actions.push('Réentraînement du modèle');
        success = true;
        message = `${validationResult.approved} feedback(s) approuvé(s) et modèle réentraîné`;
      } else {
        message = 'Aucun feedback validable automatiquement';
      }
    } catch (error) {
      message = `Erreur lors de l'approbation: ${error.message}`;
    }

    return { success, message, actions };
  }

  /**
   * Améliore la précision
   */
  async improveAccuracy(challenge) {
    const actions = [];
    let success = false;
    let message = '';

    try {
      // 1. Valider les feedbacks en attente
      console.log('   → Validation des feedbacks...');
      const validationResult = await mlAutoValidator.validatePendingFeedbacks();
      actions.push('Validation automatique des feedbacks');
      
      // 2. Réentraîner le modèle
      console.log('   → Réentraînement du modèle...');
      await mlTranslationEngine.retrain();
      actions.push('Réentraînement du modèle');
      
      // 3. Apprentissage continu
      console.log('   → Apprentissage continu...');
      await mlContinuousLearning.processNewFeedbacks();
      actions.push('Apprentissage continu');
      
      success = true;
      message = `Modèle amélioré avec ${validationResult.approved} nouveau(x) feedback(s)`;
    } catch (error) {
      message = `Erreur lors de l'amélioration: ${error.message}`;
    }

    return { success, message, actions };
  }

  /**
   * Réduit les points faibles
   */
  async reduceWeaknesses(challenge) {
    const actions = [];
    let success = false;
    let message = '';

    try {
      // Traiter les recommandations prioritaires
      console.log('   → Traitement des recommandations prioritaires...');
      
      // 1. Valider les feedbacks
      const validationResult = await mlAutoValidator.validatePendingFeedbacks();
      actions.push('Validation automatique des feedbacks');
      
      // 2. Réentraîner
      await mlTranslationEngine.retrain();
      actions.push('Réentraînement du modèle');
      
      success = true;
      message = `Actions exécutées pour réduire les points faibles`;
    } catch (error) {
      message = `Erreur lors de la réduction des points faibles: ${error.message}`;
    }

    return { success, message, actions };
  }

  /**
   * Récupère la performance
   */
  async recoverPerformance(challenge) {
    const actions = [];
    let success = false;
    let message = '';

    try {
      // Actions de récupération
      console.log('   → Actions de récupération de performance...');
      
      // 1. Valider tous les feedbacks possibles
      const validationResult = await mlAutoValidator.validatePendingFeedbacks();
      actions.push('Validation automatique des feedbacks');
      
      // 2. Réentraîner complètement
      await mlTranslationEngine.retrain();
      actions.push('Réentraînement complet du modèle');
      
      // 3. Apprentissage continu
      await mlContinuousLearning.processNewFeedbacks();
      actions.push('Apprentissage continu');
      
      success = true;
      message = `Actions de récupération exécutées`;
    } catch (error) {
      message = `Erreur lors de la récupération: ${error.message}`;
    }

    return { success, message, actions };
  }

  /**
   * Maintient l'amélioration
   */
  async maintainImprovement(challenge) {
    const actions = [];
    let success = false;
    let message = '';

    try {
      // Actions de maintenance
      console.log('   → Actions de maintenance...');
      
      // 1. Validation continue
      const validationResult = await mlAutoValidator.validatePendingFeedbacks();
      actions.push('Validation automatique des feedbacks');
      
      // 2. Apprentissage continu
      await mlContinuousLearning.processNewFeedbacks();
      actions.push('Apprentissage continu');
      
      success = true;
      message = `Maintenance effectuée`;
    } catch (error) {
      message = `Erreur lors de la maintenance: ${error.message}`;
    }

    return { success, message, actions };
  }

  /**
   * Atteint 70% de précision
   */
  async reach70Accuracy(challenge) {
    const actions = [];
    let success = false;
    let message = '';

    try {
      // Actions pour atteindre l'objectif
      console.log('   → Actions pour atteindre 70% de précision...');
      
      // 1. Valider tous les feedbacks possibles
      const validationResult = await mlAutoValidator.validatePendingFeedbacks();
      actions.push('Validation automatique des feedbacks');
      
      // 2. Réentraîner
      await mlTranslationEngine.retrain();
      actions.push('Réentraînement du modèle');
      
      // 3. Apprentissage continu
      await mlContinuousLearning.processNewFeedbacks();
      actions.push('Apprentissage continu');
      
      success = true;
      message = `Actions exécutées pour améliorer la précision`;
    } catch (error) {
      message = `Erreur lors de l'amélioration: ${error.message}`;
    }

    return { success, message, actions };
  }

  /**
   * Obtient l'historique des actions
   */
  getActionsHistory(limit = 20) {
    return this.actionsHistory.slice(-limit);
  }
}

// Si exécuté directement
if (require.main === module) {
  const autoActions = new MLAutoActions();
  
  autoActions.executeAutoActions()
    .then((result) => {
      console.log('\n✅ Actions automatiques terminées');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Erreur lors de l\'exécution des actions:', error);
      process.exit(1);
    });
}

module.exports = new MLAutoActions();

