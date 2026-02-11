<template>
  <div v-if="isLoading" class="loading">
    <p>Loading...</p>
  </div>
  <AppLayout v-else @page-change="onPageChange">
    <component :is="currentComponent" @navigate="navigateTo" />
  </AppLayout>
</template>

<script>
import axios from 'axios';
import AppLayout from '../navigation/AppLayout.vue';
import DashboardView from '../navigation/DashboardView.vue';
import HealthCheckView from '../navigation/HealthCheckView.vue';
import HouseholdView from '../navigation/HouseholdView.vue';

export default {
  name: 'HomeApp',
  components: {
    AppLayout,
    DashboardView,
    HealthCheckView,
    HouseholdView
  },
  data() {
    return {
      isLoading: true,
      currentPage: 'dashboard'
    };
  },
  computed: {
    currentComponent() {
      const components = {
        dashboard: 'DashboardView',
        household: 'HouseholdView',
        'health-check': 'HealthCheckView'
      };
      return components[this.currentPage] || 'DashboardView';
    }
  },
  mounted() {
    this.checkAuthentication();
  },
  methods: {
    async checkAuthentication() {
      try {
        const response = await axios.get('/api/auth/me', {
          withCredentials: true
        });

        if (!response.ok && response.status !== 200) {
          window.location.href = '/login';
          return;
        }
      } catch (error) {
        console.error('Error checking authentication:', error);
        window.location.href = '/login';
      } finally {
        this.isLoading = false;
      }
    },
    onPageChange(page) {
      this.currentPage = page;
    },
    navigateTo(page) {
      this.currentPage = page;
    }
  }
};
</script>

<style>
body, html {
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

.loading {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  font-size: 18px;
  color: #666;
}
</style>
