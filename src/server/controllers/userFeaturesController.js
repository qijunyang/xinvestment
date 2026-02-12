/**
 * User Features Controller
 * Handles requests for user features/navigation items
 */

const userFeaturesService = require('../services/userFeaturesService');
const { logger } = require('../log/logger');

exports.getAllFeatures = async (req, res) => {
  try {
    const features = userFeaturesService.getAllFeatures();
    
    res.status(200).json({
      success: true,
      data: features,
      message: 'Features retrieved successfully'
    });
  } catch (error) {
    logger.error('Error retrieving features:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve features',
      error: error.message
    });
  }
};

exports.getUserFeatures = async (req, res) => {
  try {
    const userId = req.user?.userId || req.session?.userId;

    const features = userFeaturesService.getUserFeatures(userId);
    
    res.status(200).json({
      success: true,
      data: features,
      userId: userId,
      message: 'User features retrieved successfully'
    });
  } catch (error) {
    logger.error('Error retrieving user features:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve user features',
      error: error.message
    });
  }
};

exports.getFeatureById = async (req, res) => {
  try {
    const { featureId } = req.params;

    if (!featureId) {
      return res.status(400).json({
        success: false,
        message: 'Feature ID is required'
      });
    }

    const feature = userFeaturesService.getFeatureById(featureId);

    if (!feature) {
      return res.status(404).json({
        success: false,
        message: 'Feature not found'
      });
    }

    res.status(200).json({
      success: true,
      data: feature,
      message: 'Feature retrieved successfully'
    });
  } catch (error) {
    logger.error('Error retrieving feature:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve feature',
      error: error.message
    });
  }
};
