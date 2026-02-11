import axios from 'axios';

let householdCache = null;
let householdCacheTimestamp = 0;
const CACHE_TTL_MS = 5 * 60 * 1000;

const ensureSuccess = (response, fallbackMessage) => {
  if (!response || !response.data || !response.data.success) {
    const message = response?.data?.message || fallbackMessage;
    throw new Error(message);
  }
};

const isCacheFresh = () => {
  if (!Array.isArray(householdCache)) {
    return false;
  }
  return Date.now() - householdCacheTimestamp < CACHE_TTL_MS;
};

const setCache = (households) => {
  householdCache = households;
  householdCacheTimestamp = Date.now();
};

const householdDataService = {
  async getAllHouseholds(options = {}) {
    const { forceRefresh = false } = options;

    if (!forceRefresh && isCacheFresh()) {
      return householdCache;
    }

    const response = await axios.get('/api/households', {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to load households');

    const households = response.data.data || [];
    setCache(households);
    return households;
  },

  async getHouseholdById(id, options = {}) {
    const { forceRefresh = false } = options;

    if (!forceRefresh && isCacheFresh()) {
      const cached = householdCache.find((household) => household.id === id);
      if (cached) {
        return cached;
      }
    }

    const response = await axios.get(`/api/households/${id}` , {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to load household');

    const household = response.data.data || null;
    if (household) {
      if (!Array.isArray(householdCache)) {
        setCache([household]);
      } else {
        const index = householdCache.findIndex((item) => item.id === household.id);
        if (index === -1) {
          householdCache.unshift(household);
        } else {
          householdCache[index] = household;
        }
        householdCacheTimestamp = Date.now();
      }
    }

    return household;
  },

  async getHouseholdsByOwnerId(ownerId, options = {}) {
    const { forceRefresh = false } = options;

    if (!forceRefresh && isCacheFresh()) {
      return householdCache.filter((household) => household.ownerId === ownerId);
    }

    const response = await axios.get(`/api/households/owner/${ownerId}` , {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to load households');

    const households = response.data.data || [];
    setCache(households);
    return households;
  },

  async refreshHouseholds() {
    return this.getAllHouseholds({ forceRefresh: true });
  },

  async createHousehold(payload) {
    const response = await axios.post('/api/households', payload, {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to create household');

    const household = response.data.data;
    if (!Array.isArray(householdCache)) {
      setCache([household]);
    } else {
      householdCache.unshift(household);
      householdCacheTimestamp = Date.now();
    }

    return household;
  },

  async updateHousehold(id, payload) {
    const response = await axios.put(`/api/households/${id}` , payload, {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to update household');

    const household = response.data.data;
    if (Array.isArray(householdCache)) {
      const index = householdCache.findIndex((item) => item.id === household.id);
      if (index === -1) {
        householdCache.unshift(household);
      } else {
        householdCache[index] = household;
      }
      householdCacheTimestamp = Date.now();
    } else {
      setCache([household]);
    }

    return household;
  },

  async deleteHousehold(id) {
    const response = await axios.delete(`/api/households/${id}` , {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to delete household');

    if (Array.isArray(householdCache)) {
      householdCache = householdCache.filter((household) => household.id !== id);
      householdCacheTimestamp = Date.now();
    }

    return true;
  },

  clearCache() {
    householdCache = null;
    householdCacheTimestamp = 0;
  }
};

export default householdDataService;
