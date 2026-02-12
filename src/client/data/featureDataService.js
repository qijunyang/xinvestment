import axios from 'axios';

let featureCache = null;
let featureCacheTimestamp = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

const ensureSuccess = (response, fallbackMessage) => {
  if (!response || !response.data || !response.data.success) {
    const message = response?.data?.message || fallbackMessage;
    throw new Error(message);
  }
};

const isCacheFresh = () => {
  if (!Array.isArray(featureCache)) {
    return false;
  }
  return Date.now() - featureCacheTimestamp < CACHE_TTL_MS;
};

const setCache = (features) => {
  featureCache = features;
  featureCacheTimestamp = Date.now();
};

const featureDataService = {
  /**
   * Get all features
   * @param {Object} options - Options object
   * @param {boolean} options.forceRefresh - Force refresh from server
   * @returns {Promise<Array>} List of features
   */
  async getAllFeatures(options = {}) {
    const { forceRefresh = false } = options;

    if (!forceRefresh && isCacheFresh()) {
      return featureCache;
    }

    const response = await axios.get('/api/features', {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to load features');

    const features = response.data.data || [];
    setCache(features);
    return features;
  },

  /**
   * Get features for the current user
   * @param {Object} options - Options object
   * @param {boolean} options.forceRefresh - Force refresh from server
   * @returns {Promise<Array>} List of user-specific features
   */
  async getUserFeatures(options = {}) {
    const { forceRefresh = false } = options;

    if (!forceRefresh && isCacheFresh()) {
      return featureCache;
    }

    const response = await axios.get('/api/features/my-features', {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to load user features');

    const features = response.data.data || [];
    setCache(features);
    return features;
  },

  /**
   * Get a specific feature by ID
   * @param {string} featureId - Feature ID
   * @param {Object} options - Options object
   * @param {boolean} options.forceRefresh - Force refresh from server
   * @returns {Promise<Object|null>} Feature object or null
   */
  async getFeatureById(featureId, options = {}) {
    const { forceRefresh = false } = options;

    if (!forceRefresh && isCacheFresh()) {
      const cached = featureCache.find((feature) => feature.id === featureId);
      if (cached) {
        return cached;
      }
    }

    const response = await axios.get(`/api/features/${featureId}`, {
      withCredentials: true
    });

    ensureSuccess(response, 'Failed to load feature');

    const feature = response.data.data || null;
    
    // Update cache with the single feature
    if (feature && isCacheFresh()) {
      const index = featureCache.findIndex((item) => item.id === feature.id);
      if (index === -1) {
        featureCache.push(feature);
      } else {
        featureCache[index] = feature;
      }
      featureCacheTimestamp = Date.now();
    }

    return feature;
  },

  /**
   * Refresh features from server
   * @returns {Promise<Array>} Fresh list of features
   */
  async refreshFeatures() {
    return this.getAllFeatures({ forceRefresh: true });
  },

  /**
   * Clear feature cache
   */
  clearCache() {
    featureCache = null;
    featureCacheTimestamp = 0;
  }
};

export default featureDataService;
