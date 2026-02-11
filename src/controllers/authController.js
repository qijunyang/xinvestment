/**
 * Login user and create session
 * Body params: { userId, username, password }
 * Session is automatically managed by express-session middleware
 */
function login(req, res) {
  try {
    const { userId, username, password } = req.body;
    
    if (!userId || !username) {
      return res.status(400).json({ 
        error: 'Bad Request', 
        message: 'userId and username are required' 
      });
    }

    // Simple password validation (in production, use bcrypt and hash stored passwords)
    if (!password || password.length < 1) {
      return res.status(400).json({ 
        error: 'Bad Request', 
        message: 'Password is required' 
      });
    }

    // Store user data directly in session
    // express-session automatically saves to store
    req.session.userId = userId;
    req.session.username = username;
    req.session.loginTime = new Date();

    // Send success response
    // express-session will automatically call store.set() before sending response
    res.status(200).json({ 
      message: 'Login successful',
      user: {
        userId,
        username,
        loginTime: new Date()
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

/**
 * Logout user and destroy session
 * Session is automatically managed by express-session middleware
 */
function logout(req, res) {
  try {
    // Destroy the session
    if (req.session) {
      req.session.destroy(() => {
        // Clear the session cookie(s)
        res.clearCookie('xinvestment-session-dev');
        res.clearCookie('xinvestment-session-prod');
        res.clearCookie('xinvestment-session-qa');
        res.clearCookie('connect.sid'); // Default express-session cookie
        
        res.status(200).json({ message: 'Logout successful' });
      });
    } else {
      res.status(200).json({ message: 'Logout successful' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

/**
 * Get current user info from session
 */
function getCurrentUser(req, res) {
  if (!req.session || !req.session.userId) {
    return res.status(401).json({ 
      error: 'Unauthorized', 
      message: 'Not authenticated' 
    });
  }

  res.status(200).json({ 
    user: {
      userId: req.session.userId,
      username: req.session.username,
      loginTime: req.session.loginTime
    }
  });
}

module.exports = {
  login,
  logout,
  getCurrentUser
};

