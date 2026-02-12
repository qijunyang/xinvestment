/** @jest-environment jsdom */

const mountMock = jest.fn();
const createAppMock = jest.fn(() => ({ mount: mountMock }));

jest.mock('vue', () => ({
  createApp: createAppMock
}));

describe('home entry', () => {
  beforeEach(() => {
    jest.resetModules();
    mountMock.mockClear();
    createAppMock.mockClear();
  });

  it('mounts the home app', () => {
    require('../../../src/client/home/home');

    expect(createAppMock).toHaveBeenCalled();
    expect(mountMock).toHaveBeenCalledWith('#app');
  });
});
