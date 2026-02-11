/**
 * Household Routes
 * Routes for household management
 */

const express = require('express');
const router = express.Router();
const householdController = require('../controllers/householdController');

// Get all households
router.get('/', householdController.getAllHouseholds);

// Get households by owner ID
router.get('/owner/:ownerId', householdController.getHouseholdsByOwnerId);

// Get household by ID
router.get('/:id', householdController.getHouseholdById);

// Create new household
router.post('/', householdController.createHousehold);

// Update household
router.put('/:id', householdController.updateHousehold);

// Delete household
router.delete('/:id', householdController.deleteHousehold);

module.exports = router;
