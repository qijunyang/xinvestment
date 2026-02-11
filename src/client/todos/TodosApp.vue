<template>
  <AppLayout>
    <div class="navbar">
      <h1>� Xinvestment</h1>
      <div class="user-info">
        <span>Welcome, <strong>{{ username }}</strong>!</span>
        <button class="btn btn-logout" @click="handleLogout">Logout</button>
      </div>
    </div>

    <div class="container">
      <div class="alert alert-info">
        ✓ You are successfully logged in. Session is active.
      </div>
      <p>Your todos will appear here when you implement the TODO endpoints.</p>
      <p><a href="/api/todos">View API</a></p>
    </div>
  </AppLayout>
</template>

<script>
import AppLayout from '../navigation/AppLayout.vue';

export default {
  name: 'TodosApp',
  components: {
    AppLayout
  },
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
        const response = await fetch('/api/auth/me', {
          credentials: 'include'
        });
        const data = await response.json();
        if (data.user) {
          this.username = data.user.username;
        }
      } catch (error) {
        console.error('Error fetching user:', error);
      }
    },
    async handleLogout() {
      try {
        await fetch('/api/auth/logout', {
          method: 'GET',
          credentials: 'include'
        });
        window.location.href = '/login/';
      } catch (error) {
        console.error('Logout error:', error);
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
}

.btn-logout {
  background: #667eea;
  color: white;
}

.btn-logout:hover {
  background: #764ba2;
}

.container {
  max-width: 1200px;
  margin: 20px auto;
  padding: 0 20px;
}

.alert {
  padding: 15px;
  border-radius: 4px;
  margin-bottom: 20px;
}

.alert-info {
  background: #e7f3ff;
  color: #0066cc;
  border: 1px solid #b3d9ff;
}

p {
  margin: 10px 0;
}

a {
  color: #667eea;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
</style>
