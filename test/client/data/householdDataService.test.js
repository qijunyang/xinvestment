const axios = require('axios');

jest.mock('axios');

describe('householdDataService', () => {
  let householdDataService;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.resetModules();
    axios.get = jest.fn();
    axios.post = jest.fn();
    householdDataService = require('../../../src/client/data/householdDataService').default;
    householdDataService.clearCache();
  });

  it('loads households and caches them', async () => {
    axios.get.mockResolvedValueOnce({
      data: { success: true, data: [{ id: 'h1' }] }
    });

    const first = await householdDataService.getAllHouseholds();
    const second = await householdDataService.getAllHouseholds();

    expect(first).toEqual([{ id: 'h1' }]);
    expect(second).toEqual([{ id: 'h1' }]);
    expect(axios.get).toHaveBeenCalledTimes(1);
  });

  it('creates a household and updates cache', async () => {
    axios.post.mockResolvedValueOnce({
      data: { success: true, data: { id: 'h2' } }
    });

    const created = await householdDataService.createHousehold({ name: 'test' });
    const cached = await householdDataService.getAllHouseholds();

    expect(created).toEqual({ id: 'h2' });
    expect(cached).toEqual([{ id: 'h2' }]);
  });
});
