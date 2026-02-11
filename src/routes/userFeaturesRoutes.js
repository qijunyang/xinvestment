/**
 * User Features Routes
 * API endpoints for user features/navigation items
 */

const express = require('express');
const router = express.Router();
const userFeaturesController = require('../controllers/userFeaturesController');

/**
 * GET /api/features
 * Get all available features
 * No authentication required - features are public
 */
router.get('/', userFeaturesController.getAllFeatures);

/**
 * GET /api/features/my-features
 * Get features for the authenticated user
 * Note: This could be customized based on user role/permissions
 */
router.get('/my-features', userFeaturesController.getUserFeatures);

/**
 * GET /api/features/:featureId
 * Get a specific feature by ID
 */
router.get('/:featureId', userFeaturesController.getFeatureById);

module.exports = router;
