/**
 * Test suite for user features service
 * Tests feature list management
 */

const userFeaturesService = require('../src/services/userFeaturesService');

describe('UserFeaturesService', () => {
  describe('getAllFeatures', () => {
    it('should return array of features', () => {
      const features = userFeaturesService.getAllFeatures();
      
      expect(Array.isArray(features)).toBe(true);
      expect(features.length).toBeGreaterThan(0);
    });

    it('should return features with required properties', () => {
      const features = userFeaturesService.getAllFeatures();
      
      features.forEach(feature => {
        expect(feature).toHaveProperty('id');
        expect(feature).toHaveProperty('title');
        expect(feature).toHaveProperty('icon');
        expect(feature).toHaveProperty('action');
        expect(feature).toHaveProperty('description');
      });
    });

    it('should return features with valid properties', () => {
      const features = userFeaturesService.getAllFeatures();
      
      features.forEach(feature => {
        expect(typeof feature.id).toBe('string');
        expect(typeof feature.title).toBe('string');
        expect(typeof feature.icon).toBe('string');
        expect(typeof feature.action).toBe('string');
        expect(typeof feature.description).toBe('string');
        
        expect(feature.id.length).toBeGreaterThan(0);
        expect(feature.title.length).toBeGreaterThan(0);
      });
    });
  });

  describe('getUserFeatures', () => {
    it('should return user features for valid userId', () => {
      const userId = 'john';
      const features = userFeaturesService.getUserFeatures(userId);
      
      expect(Array.isArray(features)).toBe(true);
      expect(features.length).toBeGreaterThan(0);
    });

    it('should return features with all properties', () => {
      const userId = 'john';
      const features = userFeaturesService.getUserFeatures(userId);
      
      features.forEach(feature => {
        expect(feature).toHaveProperty('id');
        expect(feature).toHaveProperty('title');
        expect(feature).toHaveProperty('icon');
        expect(feature).toHaveProperty('action');
        expect(feature).toHaveProperty('description');
      });
    });

    it('should return similar features for all users', () => {
      const user1Features = userFeaturesService.getUserFeatures('user1');
      const user2Features = userFeaturesService.getUserFeatures('user2');
      
      expect(user1Features.length).toBe(user2Features.length);
    });
  });

  describe('getFeatureById', () => {
    it('should return feature by ID', () => {
      const features = userFeaturesService.getAllFeatures();
      const firstFeatureId = features[0].id;
      
      const feature = userFeaturesService.getFeatureById(firstFeatureId);
      
      expect(feature).toBeDefined();
      expect(feature.id).toBe(firstFeatureId);
    });

    it('should return null for non-existent feature', () => {
      const feature = userFeaturesService.getFeatureById('non-existent-id');
      
      expect(feature).toBeNull();
    });

    it('should return feature with complete data', () => {
      const features = userFeaturesService.getAllFeatures();
      const feature = userFeaturesService.getFeatureById(features[0].id);
      
      expect(feature).toHaveProperty('id');
      expect(feature).toHaveProperty('title');
      expect(feature).toHaveProperty('icon');
      expect(feature).toHaveProperty('action');
      expect(feature).toHaveProperty('description');
    });
  });
});
