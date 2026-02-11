<template>
  <nav class="navigation">
    <div class="nav-header">
      <h3 v-if="!isCollapsed">Features</h3>
      <button 
        class="toggle-btn" 
        @click="$emit('toggle-collapse')"
        :title="isCollapsed ? 'Expand' : 'Collapse'"
      >
        {{ isCollapsed ? '»' : '«' }}
      </button>
    </div>
    <ul class="nav-list">
      <li v-if="isLoading" class="loading-item">
        <span class="loading-text">Loading...</span>
      </li>
      <li v-else-if="error" class="error-item">
        <span class="error-text">Failed to load</span>
      </li>
      <li 
        v-for="feature in features" 
        :key="feature.id"
        class="nav-item"
      >
        <a 
          href="javascript:void(0)"
          @click.prevent="navigateTo(feature.action)"
          :class="{ active: isActive(feature.action) }"
          class="nav-link"
          :title="isCollapsed ? feature.title : ''"
        >
          <span class="icon">{{ feature.icon }}</span>
          <span v-if="!isCollapsed" class="label">{{ feature.title }}</span>
        </a>
      </li>
    </ul>
  </nav>
</template>

<script>
import axios from 'axios';

export default {
  name: 'Navigation',
  props: {
    isCollapsed: {
      type: Boolean,
      default: false
    },
    currentPage: {
      type: String,
      default: 'dashboard'
    }
  },
  data() {
    return {
      features: [],
      isLoading: true,
      error: null
    };
  },
  mounted() {
    this.loadFeatures();
  },
  methods: {
    async loadFeatures() {
      try {
        this.isLoading = true;
        this.error = null;

        const response = await axios.get('/api/features', {
          withCredentials: true
        });

        if (response.data && response.data.data) {
          this.features = response.data.data;
        }
      } catch (error) {
        console.error('Error loading features:', error);
        this.error = error.message;
        
        // Fallback to default features if API fails
        this.features = [
          { id: 'dashboard', title: 'Dashboard', icon: '🏠', action: 'dashboard' },
          { id: 'todos', title: 'Todos', icon: '✓', action: 'todos' },
          { id: 'health-check', title: 'Health Check', icon: '💚', action: 'health-check' }
        ];
        this.error = null; // Clear error since we have fallback
      } finally {
        this.isLoading = false;
      }
    },
    navigateTo(action) {
      this.$emit('navigate', action);
    },
    isActive(action) {
      return this.currentPage === action;
    }
  }
};
</script>

<style scoped>
.navigation {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 20px 0;
  box-shadow: 2px 0 8px rgba(0, 0, 0, 0.15);
}

.nav-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px 30px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.2);
  gap: 10px;
  min-height: 50px;
}

.nav-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  letter-spacing: 0.5px;
  flex: 1;
  white-space: nowrap;
}

.toggle-btn {
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: white;
  font-size: 18px;
  font-weight: bold;
  padding: 6px 10px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.3s ease;
  flex-shrink: 0;
}

.toggle-btn:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.05);
}

.toggle-btn:active {
  transform: scale(0.95);
}

.nav-list {
  list-style: none;
  margin: 0;
  padding: 20px 0;
  flex: 1;
  overflow-y: auto;
}

.nav-item {
  margin: 0;
  padding: 0;
}

.loading-item,
.error-item {
  padding: 20px;
  text-align: center;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
}

.nav-link {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px 20px;
  color: rgba(255, 255, 255, 0.8);
  text-decoration: none;
  transition: all 0.3s ease;
  cursor: pointer;
}

.nav-link:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
  padding-left: 24px;
}

.nav-link.active {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border-left: 4px solid white;
  padding-left: 16px;
}

.icon {
  font-size: 18px;
  margin-right: 12px;
  min-width: 20px;
  text-align: center;
  flex-shrink: 0;
}

.label {
  font-size: 14px;
  font-weight: 500;
  white-space: nowrap;
}

/* Scrollbar styling */
.nav-list::-webkit-scrollbar {
  width: 6px;
}

.nav-list::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
}

.nav-list::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 3px;
}

.nav-list::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.5);
}
</style>
