const axios = require('axios');

jest.mock('axios');

describe('featureDataService', () => {
  let featureDataService;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.resetModules();
    axios.get = jest.fn();
    featureDataService = require('../../../src/client/data/featureDataService').default;
    featureDataService.clearCache();
  });

  it('loads features and caches them', async () => {
    axios.get.mockResolvedValueOnce({
      data: { success: true, data: [{ id: 'f1' }] }
    });

    const first = await featureDataService.getAllFeatures();
    const second = await featureDataService.getAllFeatures();

    expect(first).toEqual([{ id: 'f1' }]);
    expect(second).toEqual([{ id: 'f1' }]);
    expect(axios.get).toHaveBeenCalledTimes(1);
  });

  it('throws when API returns failure', async () => {
    axios.get.mockResolvedValueOnce({
      data: { success: false, message: 'Boom' }
    });

    await expect(featureDataService.getAllFeatures()).rejects.toThrow('Boom');
  });
});
