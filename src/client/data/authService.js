import axios from 'axios';

const authService = {
  async getAuthStatus() {
    const response = await axios.get('/api/auth/status', {
      withCredentials: true
    });

    return {
      authenticated: Boolean(response?.data?.authenticated),
      user: response?.data?.user || null
    };
  },
  async ensureAuthenticated(redirectUrl = '/login') {
    try {
      const { authenticated } = await authService.getAuthStatus();
      if (!authenticated) {
        window.location.href = redirectUrl;
        return false;
      }
      return true;
    } catch (error) {
      window.location.href = redirectUrl;
      return false;
    }
  }
};

export default authService;
