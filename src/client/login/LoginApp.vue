<template>
  <div class="login-container">
    <div class="login-box">
      <h1>Xinvestment</h1>
      <p class="subtitle">Login to your investment account</p>
      
      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label for="username">Username</label>
          <input 
            type="text" 
            id="username" 
            v-model="form.username" 
            placeholder="Enter your username"
            required
          >
        </div>

        <div class="form-group">
          <label for="password">Password</label>
          <input 
            type="password" 
            id="password" 
            v-model="form.password" 
            placeholder="Enter your password"
            required
          >
        </div>

        <button type="submit" class="btn btn-primary" :disabled="isLoading">
          {{ isLoading ? 'Logging in...' : 'Login' }}
        </button>
      </form>

      <div v-if="error" class="alert alert-error">
        {{ error }}
      </div>

      <div v-if="success" class="alert alert-success">
        {{ success }}
      </div>

      <div class="demo-users">
        <p><strong>Demo Users (password: any):</strong></p>
        <ul>
          <li><code>john</code></li>
          <li><code>jane</code></li>
          <li><code>admin</code></li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LoginApp',
  data() {
    return {
      form: {
        username: '',
        password: ''
      },
      isLoading: false,
      error: '',
      success: ''
    };
  },
  mounted() {
    this.checkAuthentication();
  },
  methods: {
    async checkAuthentication() {
      try {
        const response = await fetch('/api/auth/me', {
          credentials: 'include'
        });

        // If authenticated, redirect to home
        if (response.ok) {
          window.location.href = '/home';
        }
      } catch (error) {
        // If there's an error, allow user to see login page
        console.error('Auth check error:', error);
      }
    },
    async handleLogin() {
      this.error = '';
      this.success = '';
      this.isLoading = true;

      try {
        const response = await fetch('/api/auth/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          credentials: 'include',
          body: JSON.stringify({
            userId: this.form.username,
            username: this.form.username,
            password: this.form.password
          })
        });

        const data = await response.json();

        if (response.ok) {
          this.success = 'Login successful! Redirecting...';
          setTimeout(() => {
            window.location.href = '/home';
          }, 1500);
        } else {
          this.error = data.message || 'Login failed';
        }
      } catch (err) {
        this.error = 'An error occurred. Please try again.';
        console.error('Login error:', err);
      } finally {
        this.isLoading = false;
      }
    }
  }
};
</script>

<style scoped>
form {
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  margin-bottom: 8px;
  color: #333;
  font-weight: 500;
  font-size: 14px;
}

input[type="text"],
input[type="password"] {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  transition: border-color 0.3s;
}

input[type="text"]:focus,
input[type="password"]:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.btn {
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.alert {
  padding: 12px;
  border-radius: 4px;
  margin-bottom: 15px;
  text-align: center;
  font-size: 14px;
}

.alert-error {
  background-color: #fee;
  color: #c33;
  border: 1px solid #fcc;
}

.alert-success {
  background-color: #efe;
  color: #3c3;
  border: 1px solid #cfc;
}

.demo-users {
  background-color: #f5f5f5;
  padding: 15px;
  border-radius: 4px;
  margin-top: 20px;
  font-size: 13px;
}

.demo-users p {
  color: #666;
  margin-bottom: 10px;
}

.demo-users ul {
  list-style: none;
  margin-left: 0;
}

.demo-users li {
  color: #333;
  margin-bottom: 5px;
}

.demo-users code {
  background-color: #e5e5e5;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: 'Courier New', monospace;
  color: #667eea;
}
</style>
