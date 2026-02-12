<template>
  <div v-if="isLoading" class="loading">
    <p>Loading...</p>
  </div>
  <AppLayout v-else @page-change="onPageChange">
    <component :is="currentComponent" @navigate="navigateTo" />
  </AppLayout>
</template>

<script>
import authService from '../data/authService';
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
  methods: {
    onPageChange(page) {
      this.currentPage = page;
    },
    navigateTo(page) {
      this.currentPage = page;
    },
    async checkAuthStatus() {
      const isAuthenticated = await authService.ensureAuthenticated('/login');
      if (isAuthenticated) {
        this.isLoading = false;
      }
    }
  },
  async beforeMount() {
    await this.checkAuthStatus();
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
