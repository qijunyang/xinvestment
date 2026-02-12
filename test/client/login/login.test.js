/** @jest-environment jsdom */

const mountMock = jest.fn();
const createAppMock = jest.fn(() => ({ mount: mountMock }));

jest.mock('vue', () => ({
  createApp: createAppMock
}));

describe('login entry', () => {
  beforeEach(() => {
    jest.resetModules();
    mountMock.mockClear();
    createAppMock.mockClear();
  });

  it('mounts the login app', () => {
    require('../../../src/client/login/login');

    expect(createAppMock).toHaveBeenCalled();
    expect(mountMock).toHaveBeenCalledWith('#app');
  });
});
