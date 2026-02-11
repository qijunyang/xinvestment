const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Public routes (no auth required)
router.post('/login', authController.login);
router.get('/logout', authController.logout);

// Protected routes (require authentication)
router.get('/me', (req, res, next) => {
  if (!req.session || !req.session.userId) {
    return res.status(401).json({ 
      error: 'Unauthorized', 
      message: 'Authentication required' 
    });
  }
  next();
}, authController.getCurrentUser);

module.exports = router;
