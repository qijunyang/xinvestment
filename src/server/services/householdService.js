/**
 * Household Service
 * Manages household data and operations
 */

class HouseholdService {
  /**
   * Get all households
   * @returns {Promise<Array>} Promise that resolves to list of households
   */
  getAllHouseholds() {
    // Simulate API delay of 3 seconds
    return new Promise((resolve) => {
      setTimeout(() => {
        // Hardcoded household data for now
        const households = [
          {
            id: 'hh-001',
            name: 'Smith Family',
            createTime: '2024-01-15T10:30:00Z',
            updateTime: '2025-12-20T14:25:00Z',
            ownerId: 'user-001',
            ownerName: 'John Smith',
            email: 'john.smith@example.com',
            phone: '555-123-4567'
          },
          {
            id: 'hh-002',
            name: 'Johnson Household',
            createTime: '2024-03-22T08:15:00Z',
            updateTime: '2026-01-05T16:45:00Z',
            ownerId: 'user-002',
            ownerName: 'Jane Johnson',
            email: 'jane.johnson@example.com',
            phone: '555-234-5678'
          },
          {
            id: 'hh-003',
            name: 'Williams Estate',
            createTime: '2023-11-10T12:00:00Z',
            updateTime: '2025-11-30T09:30:00Z',
            ownerId: 'user-003',
            ownerName: 'Robert Williams',
            email: 'robert.williams@example.com',
            phone: '555-345-6789'
          },
          {
            id: 'hh-004',
            name: 'Brown Family Trust',
            createTime: '2024-06-05T14:20:00Z',
            updateTime: '2026-02-01T11:15:00Z',
            ownerId: 'user-004',
            ownerName: 'Emily Brown',
            email: 'emily.brown@example.com',
            phone: '555-456-7890'
          },
          {
            id: 'hh-005',
            name: 'Davis Household',
            createTime: '2024-09-18T16:45:00Z',
            updateTime: '2026-02-08T13:50:00Z',
            ownerId: 'user-005',
            ownerName: 'Michael Davis',
            email: 'michael.davis@example.com',
            phone: '555-567-8901'
          }
        ];
        resolve(households);
      }, 3000); // 3 second delay
    });
  }

  /**
   * Get household by ID
   * @param {string} householdId - The household ID
   * @returns {Promise<Object|null>} Promise that resolves to household object or null if not found
   */
  async getHouseholdById(householdId) {
    const households = await this.getAllHouseholds();
    return households.find(h => h.id === householdId) || null;
  }

  /**
   * Get households by owner ID
   * @param {string} ownerId - The owner user ID
   * @returns {Promise<Array>} Promise that resolves to list of households owned by the user
   */
  async getHouseholdsByOwnerId(ownerId) {
    const households = await this.getAllHouseholds();
    return households.filter(h => h.ownerId === ownerId);
  }

  /**
   * Create a new household
   * @param {Object} householdData - Household data
   * @returns {Object} Created household
   */
  createHousehold(householdData) {
    // In a real implementation, this would save to database
    const newHousehold = {
      id: `hh-${Date.now()}`,
      name: householdData.name,
      createTime: new Date().toISOString(),
      updateTime: new Date().toISOString(),
      ownerId: householdData.ownerId,
      ownerName: householdData.ownerName,
      email: householdData.email,
      phone: householdData.phone
    };
    return newHousehold;
  }

  /**
   * Update household
   * @param {string} householdId - The household ID
   * @param {Object} updateData - Data to update
   * @returns {Promise<Object|null>} Promise that resolves to updated household or null if not found
   */
  async updateHousehold(householdId, updateData) {
    const household = await this.getHouseholdById(householdId);
    if (!household) {
      return null;
    }

    // In a real implementation, this would update in database
    return {
      ...household,
      ...updateData,
      updateTime: new Date().toISOString()
    };
  }

  /**
   * Delete household
   * @param {string} householdId - The household ID
   * @returns {Promise<boolean>} Promise that resolves to true if deleted, false if not found
   */
  async deleteHousehold(householdId) {
    const household = await this.getHouseholdById(householdId);
    return household !== null;
  }
}

module.exports = new HouseholdService();
