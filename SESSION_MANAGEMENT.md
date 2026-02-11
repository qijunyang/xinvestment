# Session Management Documentation

## Overview
The application uses **express-session** for secure session management with signed and encrypted cookies.

## Features

### Security Features
- **Signed Cookies**: Cookies are signed with a secret key to prevent tampering
- **HTTPOnly Flag**: Prevents JavaScript access to session cookies (protects against XSS attacks)
- **Secure Flag**: Enables HTTPS-only cookies in production
- **SameSite**: Strict mode to prevent CSRF attacks
- **Session Regeneration**: Session ID is regenerated after login for additional security
- **Automatic Cleanup**: Expired sessions are automatically cleaned up every 10 minutes

### Session Configuration
- **Session Timeout**: 24 hours (configurable via `maxAge`)
- **Rolling Sessions**: Expiration time resets on each request
- **Store**: In-memory store (can be upgraded to Redis or database for production)
- **Cookie Name**: `xinvestment-session-{env}` (e.g., `xinvestment-session-dev`)

## Setup

### Environment Variables
Set the `SESSION_SECRET` environment variable for cookie signing:

```bash
# Development
export SESSION_SECRET="your-dev-secret-key"

# Production (use a strong random string)
export SESSION_SECRET=$(openssl rand -hex 32)
```

### Default Secret
If `SESSION_SECRET` is not set, the application uses a default secret from the config. **Change this in production!**

```javascript
// src/config/config-default.js
sessionSecret: process.env.SESSION_SECRET || 'xinvestment-session-secret-key-change-in-production'
```

## How It Works

### Login Flow
1. User submits login credentials
2. `POST /api/auth/login` creates a new session
3. Session data is stored in the memory store
4. Express-session automatically creates and signs the cookie
5. Browser receives the signed, HTTPOnly cookie

### Session Access
1. User makes a request with the cookie
2. Express-session automatically validates and decrypts the cookie
3. Session data is available via `req.session`
4. `req.user` is populated for backward compatibility

### Logout Flow
1. User clicks logout
2. `GET /api/auth/logout` destroys the session
3. Session store entry is deleted
4. Cookie is cleared

## API Endpoints

### Authentication
- `POST /api/auth/login` - Create a session
  - Body: `{ userId, username, password }`
  
- `GET /api/auth/logout` - Destroy the session
  
- `GET /api/auth/me` - Get current user (requires session)
  - Returns: `{ user: { userId, username, loginTime } }`

## Session Store

### In-Memory Store (Current)
```javascript
// src/middleware/sessionStore.js
class MemorySessionStore extends session.Store
```

**Pros:**
- Simple setup
- No external dependencies
- Good for development

**Cons:**
- Sessions lost on server restart
- Not suitable for multi-server deployments
- Memory usage grows with session count

### Production Recommendations
For production, upgrade to a persistent store:
- **Redis**: `npm install connect-redis`
- **MongoDB**: `npm install connect-mongo`
- **PostgreSQL**: `npm install connect-pg-simple`

Example with Redis:
```javascript
const RedisStore = require('connect-redis').default;
const { createClient } = require('redis');

const redisClient = createClient();
store: new RedisStore({ client: redisClient })
```

## Cookie Inspection

### Browser DevTools
1. Open DevTools (F12)
2. Go to Application → Cookies
3. Find `xinvestment-session-{env}`
4. Note: The cookie value is signed/encrypted and cannot be manually decoded

### Example Cookie Properties
```
Name: xinvestment-session-dev
Value: [encrypted-signed-value]
Domain: localhost
Path: /
Secure: false (dev) / true (production)
HttpOnly: true
SameSite: Strict
Max-Age: 86400 (24 hours)
```

## Backward Compatibility

The middleware includes a compatibility layer that maps session data to `req.user`:

```javascript
// Session
req.session.userId  → req.user.userId
req.session.username → req.user.username
req.session.loginTime → req.user.loginTime
```

This allows existing code to work with both `req.session` and `req.user`.

## Troubleshooting

### Sessions Not Persisting
- **Check**: Browser cookie settings (might be blocking cookies)
- **Check**: `Secure` flag in production (requires HTTPS)
- **Check**: `SameSite` attribute compatibility

### "Session expired" Errors
- Sessions expire after 24 hours by default
- Change `maxAge` in sessionMiddleware if needed
- Sessions reset on each request (rolling sessions)

### Cookie Not Being Set
- Check `httpOnly` is not preventing cookie access
- Verify `sameSite` setting doesn't conflict with CORS
- Check frontend is sending credentials: `withCredentials: true`

## Frontend Usage

### Axios Configuration
The frontend uses axios with credentials enabled:

```javascript
axios.get('/api/auth/me', {
  withCredentials: true  // Important! Sends cookies
})
```

Without `withCredentials: true`, the browser won't send the session cookie.

## Security Best Practices

1. **Change Default Secret**: Always set `SESSION_SECRET` in production
2. **Use HTTPS**: Set `secure: true` in cookie settings for production
3. **Upgrade Store**: Use Redis or database in production, not memory
4. **Regenerate on Login**: Session ID changes after login
5. **HTTPOnly Cookies**: Prevents JavaScript access to session data
6. **SameSite Strict**: Protects against CSRF attacks
7. **Monitor Sessions**: Implement session auditing in production

## Performance Considerations

- **Memory Store**: Fine for ~10k concurrent sessions
- **Cleanup Interval**: Every 10 minutes (adjustable)
- **Max Session Size**: ~100 properties recommended per session
- **Scaling**: Use Redis for horizontal scaling

## References

- [Express Session Documentation](https://github.com/expressjs/session)
- [OWASP Session Security](https://owasp.org/www-community/attacks/Session_fixation)
- [Cookie Security](https://owasp.org/www-community/controls/Cookie_Security)
