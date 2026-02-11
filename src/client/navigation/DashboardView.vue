<template>
  <div class="navbar">
    <h1>🎯 Xinvestment</h1>
    <div class="user-info">
      <span>Welcome, <strong>{{ username }}</strong>!</span>
      <button class="btn btn-logout" @click="handleLogout">Logout</button>
    </div>
  </div>

  <div class="container">
    <div class="welcome-card">
      <h2>Welcome to Xinvestment</h2>
      <p>You are successfully logged in to your investment dashboard!</p>
      <p>Session is active and you are authenticated.</p>
    </div>

    <div class="info-card">
      <h3>Quick Links</h3>
      <ul>
        <li><a href="javascript:void(0)" @click.prevent="$emit('navigate', 'dashboard')">Dashboard</a></li>
        <li><a href="javascript:void(0)" @click.prevent="$emit('navigate', 'todos')">Todos</a></li>
        <li><a href="/api/health" target="_blank">Check Server Health</a></li>
      </ul>
    </div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'DashboardView',
  data() {
    return {
      username: 'User'
    };
  },
  mounted() {
    this.fetchCurrentUser();
  },
  methods: {
    async fetchCurrentUser() {
      try {
        const response = await axios.get('/api/auth/me', {
          withCredentials: true
        });
        const data = response.data;
        if (data.user) {
          this.username = data.user.username;
        }
      } catch (error) {
        console.error('Error fetching user:', error);
      }
    },
    async handleLogout() {
      try {
        await axios.get('/api/auth/logout', {
          withCredentials: true
        });
        window.location.href = '/login';
      } catch (error) {
        console.error('Logout error:', error);
        window.location.href = '/login';
      }
    }
  }
};
</script>

<style scoped>
.navbar {
  background: white;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  padding: 15px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.navbar h1 {
  color: #333;
  margin: 0;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 15px;
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s;
}

.btn-logout {
  background: #667eea;
  color: white;
}

.btn-logout:hover {
  background: #764ba2;
  transform: translateY(-2px);
}

.container {
  max-width: 1200px;
  margin: 40px auto;
  padding: 0 20px;
}

.welcome-card,
.info-card {
  background: white;
  border-radius: 8px;
  padding: 30px;
  margin-bottom: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.welcome-card h2 {
  color: #333;
  margin-bottom: 15px;
}

.welcome-card p {
  color: #666;
  margin: 10px 0;
  line-height: 1.6;
}

.info-card h3 {
  color: #333;
  margin-bottom: 15px;
}

.info-card ul {
  list-style: none;
  padding: 0;
}

.info-card li {
  margin: 10px 0;
}

.info-card a {
  color: #667eea;
  text-decoration: none;
  font-weight: 500;
  cursor: pointer;
}

.info-card a:hover {
  color: #764ba2;
  text-decoration: underline;
}

@media (max-width: 768px) {
  .navbar {
    flex-direction: column;
    gap: 10px;
    align-items: flex-start;
  }

  .user-info {
    width: 100%;
    justify-content: space-between;
  }

  .welcome-card,
  .info-card {
    padding: 20px;
  }
}
</style>
