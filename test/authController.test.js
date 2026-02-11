/**
 * Test suite for auth controller
 * Tests authentication logic
 */

const authController = require('../src/controllers/authController');

describe('AuthController', () => {
  let mockReq, mockRes;

  beforeEach(() => {
    // Mock request object
    mockReq = {
      body: {},
      session: {}
    };

    // Mock response object
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      clearCookie: jest.fn().mockReturnThis()
    };
  });

  describe('login', () => {
    it('should require userId and username', () => {
      mockReq.body = { password: 'test' };
      
      authController.login(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Bad Request',
          message: expect.stringContaining('required')
        })
      );
    });

    it('should require password', () => {
      mockReq.body = { userId: 'john', username: 'john' };
      
      authController.login(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Bad Request',
          message: expect.stringContaining('Password')
        })
      );
    });

    it('should login successfully with valid credentials', () => {
      mockReq.body = {
        userId: 'john',
        username: 'john',
        password: 'test123'
      };

      authController.login(mockReq, mockRes);
      
      // Should set session data
      expect(mockReq.session.userId).toBe('john');
      expect(mockReq.session.username).toBe('john');
      expect(mockReq.session.loginTime).toBeDefined();
      
      // Should return 200 with success message
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Login successful',
          user: expect.objectContaining({
            userId: 'john',
            username: 'john'
          })
        })
      );
    });

    it('should set loginTime in session', () => {
      const beforeLogin = new Date();
      mockReq.body = {
        userId: 'jane',
        username: 'jane',
        password: 'test'
      };

      authController.login(mockReq, mockRes);

      const loginTime = mockReq.session.loginTime;
      expect(loginTime).toBeDefined();
      expect(loginTime.getTime()).toBeGreaterThanOrEqual(beforeLogin.getTime());
    });
  });

  describe('getCurrentUser', () => {
    it('should return 401 if not authenticated', () => {
      mockReq.session = {};
      
      authController.getCurrentUser(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(401);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Unauthorized'
        })
      );
    });

    it('should return 401 if session is null', () => {
      mockReq.session = null;
      
      authController.getCurrentUser(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(401);
    });

    it('should return user info if authenticated', () => {
      mockReq.session = {
        userId: 'john',
        username: 'john',
        loginTime: new Date()
      };

      authController.getCurrentUser(mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          user: expect.objectContaining({
            userId: 'john',
            username: 'john'
          })
        })
      );
    });
  });

  describe('logout', () => {
    it('should destroy session', () => {
      mockReq.session = {
        userId: 'john',
        destroy: jest.fn((callback) => callback())
      };

      authController.logout(mockReq, mockRes);

      expect(mockReq.session.destroy).toHaveBeenCalled();
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Logout successful'
        })
      );
    });

    it('should clear session cookies on logout', () => {
      mockReq.session = {
        destroy: jest.fn((callback) => callback())
      };

      authController.logout(mockReq, mockRes);

      expect(mockRes.clearCookie).toHaveBeenCalled();
    });

    it('should handle logout when no session exists', () => {
      mockReq.session = null;

      authController.logout(mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Logout successful'
        })
      );
    });
  });
});
