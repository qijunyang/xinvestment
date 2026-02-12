/**
 * Authentication middleware
 * Checks if user is authenticated (req.user exists)
 * Returns 401 Unauthorized if user is not authenticated
 */
function authMiddleware(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ 
      error: 'Unauthorized', 
      message: 'Authentication required. Please log in.' 
    });
  }
  next();
}

module.exports = authMiddleware;
