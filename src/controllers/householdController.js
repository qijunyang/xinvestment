/**
 * Household Controller
 * Handles HTTP requests for household management
 */

const householdService = require('../services/householdService');

/**
 * Get all households
 * GET /api/households
 */
async function getAllHouseholds(req, res) {
  try {
    const households = await householdService.getAllHouseholds();
    res.status(200).json({
      success: true,
      data: households,
      count: households.length
    });
  } catch (error) {
    console.error('Error getting all households:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve households',
      message: error.message
    });
  }
}

/**
 * Get household by ID
 * GET /api/households/:id
 */
async function getHouseholdById(req, res) {
  try {
    const { id } = req.params;
    const household = await householdService.getHouseholdById(id);

    if (!household) {
      return res.status(404).json({
        success: false,
        error: 'Household not found',
        message: `No household found with ID: ${id}`
      });
    }

    res.status(200).json({
      success: true,
      data: household
    });
  } catch (error) {
    console.error('Error getting household by ID:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve household',
      message: error.message
    });
  }
}

/**
 * Get households by owner ID
 * GET /api/households/owner/:ownerId
 */
async function getHouseholdsByOwnerId(req, res) {
  try {
    const { ownerId } = req.params;
    const households = await householdService.getHouseholdsByOwnerId(ownerId);

    res.status(200).json({
      success: true,
      data: households,
      count: households.length
    });
  } catch (error) {
    console.error('Error getting households by owner:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve households',
      message: error.message
    });
  }
}

/**
 * Create new household
 * POST /api/households
 */
function createHousehold(req, res) {
  try {
    const { name, ownerId, ownerName } = req.body;

    if (!name || !ownerId || !ownerName) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'name, ownerId, and ownerName are required'
      });
    }

    const household = householdService.createHousehold({
      name,
      ownerId,
      ownerName
    });

    res.status(201).json({
      success: true,
      data: household,
      message: 'Household created successfully'
    });
  } catch (error) {
    console.error('Error creating household:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create household',
      message: error.message
    });
  }
}

/**
 * Update household
 * PUT /api/households/:id
 */
async function updateHousehold(req, res) {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const household = await householdService.updateHousehold(id, updateData);

    if (!household) {
      return res.status(404).json({
        success: false,
        error: 'Household not found',
        message: `No household found with ID: ${id}`
      });
    }

    res.status(200).json({
      success: true,
      data: household,
      message: 'Household updated successfully'
    });
  } catch (error) {
    console.error('Error updating household:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update household',
      message: error.message
    });
  }
}

/**
 * Delete household
 * DELETE /api/households/:id
 */
async function deleteHousehold(req, res) {
  try {
    const { id } = req.params;
    const deleted = await householdService.deleteHousehold(id);

    if (!deleted) {
      return res.status(404).json({
        success: false,
        error: 'Household not found',
        message: `No household found with ID: ${id}`
      });
    }

    res.status(200).json({
      success: true,
      message: 'Household deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting household:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete household',
      message: error.message
    });
  }
}

module.exports = {
  getAllHouseholds,
  getHouseholdById,
  getHouseholdsByOwnerId,
  createHousehold,
  updateHousehold,
  deleteHousehold
};
