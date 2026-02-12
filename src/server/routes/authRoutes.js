const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Protected routes (authentication handled by middleware)
router.get('/logout', authController.logout);
router.get('/me', authController.getCurrentUser);

module.exports = router;
