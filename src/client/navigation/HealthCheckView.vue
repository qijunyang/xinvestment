<template>
  <div class="navbar">
    <h1>🎯 Xinvestment</h1>
    <div class="user-info">
      <span>Welcome, <strong>{{ username }}</strong>!</span>
      <button class="btn btn-logout" @click="handleLogout">Logout</button>
    </div>
  </div>

  <div class="container">
    <div class="health-card">
      <h2>Server Health Check</h2>
      
      <div v-if="isLoading" class="loading-state">
        <p>Checking server health...</p>
      </div>

      <div v-else-if="healthData" class="health-status">
        <div class="status-item">
          <span class="label">Status:</span>
          <span class="value">
            <span class="status-badge" :class="healthData.status === 'OK' ? 'ok' : 'error'">
              {{ healthData.status }}
            </span>
          </span>
        </div>
        <div class="status-item">
          <span class="label">Message:</span>
          <span class="value">{{ healthData.message }}</span>
        </div>
        <div class="status-item">
          <span class="label">Environment:</span>
          <span class="value"><code>{{ healthData.env }}</code></span>
        </div>
      </div>

      <div v-else-if="error" class="error-state">
        <div class="alert alert-error">
          <strong>Error:</strong> {{ error }}
        </div>
      </div>

      <button class="btn btn-refresh" @click="checkHealth">
        {{ isLoading ? 'Checking...' : 'Refresh' }}
      </button>
    </div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'HealthCheckView',
  data() {
    return {
      username: 'User',
      healthData: null,
      isLoading: true,
      error: null
    };
  },
  mounted() {
    this.checkHealth();
  },
  methods: {
    async checkHealth() {
      this.isLoading = true;
      this.error = null;
      this.healthData = null;

      try {
        const response = await axios.get('/api/health', {
          withCredentials: true
        });
        this.healthData = response.data;
      } catch (error) {
        this.error = error.message || 'Failed to check server health';
        console.error('Health check error:', error);
      } finally {
        this.isLoading = false;
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

.btn-refresh {
  background: #667eea;
  color: white;
  margin-top: 20px;
}

.btn-refresh:hover {
  background: #764ba2;
}

.container {
  max-width: 1200px;
  margin: 40px auto;
  padding: 0 20px;
}

.health-card {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.health-card h2 {
  color: #333;
  margin-top: 0;
  margin-bottom: 30px;
}

.loading-state,
.error-state {
  padding: 20px;
  text-align: center;
  color: #666;
}

.health-status {
  display: grid;
  gap: 20px;
  margin-bottom: 20px;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 15px;
  background: #f9f9f9;
  border-radius: 4px;
}

.status-item .label {
  font-weight: 600;
  color: #333;
  min-width: 120px;
}

.status-item .value {
  color: #666;
  font-size: 15px;
}

.status-badge {
  display: inline-block;
  padding: 6px 12px;
  border-radius: 4px;
  font-weight: 600;
  font-size: 14px;
}

.status-badge.ok {
  background: #d4edda;
  color: #155724;
}

.status-badge.error {
  background: #f8d7da;
  color: #721c24;
}

code {
  background: #e5e5e5;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: 'Courier New', monospace;
  color: #667eea;
}

.alert {
  padding: 15px;
  border-radius: 4px;
  margin-bottom: 20px;
}

.alert-error {
  background: #fee;
  color: #c33;
  border: 1px solid #fcc;
}
</style>
