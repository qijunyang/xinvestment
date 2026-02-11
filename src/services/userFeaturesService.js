/**
 * User Features Service
 * Provides a list of available features for the user navigation
 */

class UserFeaturesService {
  /**
   * Get all available features
   * @returns {Array} List of features with id, title, and action
   */
  getAllFeatures() {
    return [
      {
        id: 'dashboard',
        title: 'Dashboard',
        icon: '🏠',
        action: 'dashboard',
        description: 'View your investment dashboard'
      },
      {
        id: 'todos',
        title: 'Todos',
        icon: '✓',
        action: 'todos',
        description: 'Manage your tasks and todos'
      },
      {
        id: 'health-check',
        title: 'Health Check',
        icon: '💚',
        action: 'health-check',
        description: 'Check server health status'
      }
    ];
  }

  /**
   * Get features for a specific user
   * In the future, this could be customized per user role/permissions
   * @param {string} userId - The user ID
   * @returns {Array} List of features available to the user
   */
  getUserFeatures(userId) {
    // For now, all users get all features
    // In the future, you could filter based on user role/permissions
    return this.getAllFeatures();
  }

  /**
   * Get a specific feature by ID
   * @param {string} featureId - The feature ID
   * @returns {Object} The feature object or null if not found
   */
  getFeatureById(featureId) {
    const features = this.getAllFeatures();
    return features.find(f => f.id === featureId) || null;
  }
}

module.exports = new UserFeaturesService();
