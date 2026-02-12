<template>
  <div class="navbar">
    <h1>🎯 Xinvestment</h1>
    <div class="user-info">
      <span>Welcome, <strong>{{ username }}</strong>!</span>
      <button class="btn btn-logout" @click="handleLogout">Logout</button>
      <button class="btn btn-history" @click="toggleHistory" :title="showHistory ? 'Hide notification history' : 'Show notification history'">
        📋 History ({{ notificationHistory.length }})
      </button>
    </div>
  </div>

  <!-- Notification Panel - positioned below navbar -->
  <div class="notification-panel">
    <div 
      v-for="notification in activeNotifications" 
      :key="notification.id"
      class="notification"
      :class="`notification-${notification.type}`"
    >
      <span class="notification-content">{{ notification.message }}</span>
      <button class="notification-close" @click="dismissNotification(notification.id)">×</button>
    </div>
  </div>

  <!-- Notification History Panel -->
  <div v-if="showHistory" class="notification-history-panel">
    <div class="history-header">
      <h3>📋 Notification History</h3>
      <div class="history-actions">
        <button class="btn-clear-history" @click="clearHistory" v-if="notificationHistory.length > 0">Clear All</button>
        <button class="btn-close-history" @click="toggleHistory">×</button>
      </div>
    </div>
    <div class="history-content">
      <div v-if="notificationHistory.length === 0" class="history-empty">
        No notification history
      </div>
      <div 
        v-for="notification in notificationHistory" 
        :key="notification.id"
        class="history-item"
        :class="`history-item-${notification.type}`"
      >
        <div class="history-item-header">
          <span class="history-item-time">{{ formatNotificationTime(notification.timestamp) }}</span>
        </div>
        <div class="history-item-message">{{ notification.message }}</div>
      </div>
    </div>
  </div>

  <div class="container">
    <div class="household-header">
      <h2>👨‍👩‍👧‍👦 Household Management</h2>
      <p>View and manage household information</p>
    </div>

    <!-- Action Toolbar -->
    <div class="action-toolbar">
      <button class="btn btn-create" @click="handleCreate">+ Create Household</button>
      <button class="btn btn-refresh" @click="handleRefresh" :disabled="isLoading">
        🔄 Refresh
      </button>
      <button 
        class="btn btn-delete-selected" 
        @click="handleDeleteSelected"
        :disabled="selectedHouseholds.length === 0"
        :title="selectedHouseholds.length === 0 ? 'Select households to delete' : `Delete ${selectedHouseholds.length} selected`"
      >
        🗑️ Delete Selected ({{ selectedHouseholds.length }})
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="loading-state">
      <div class="spinner"></div>
      <p>Loading households...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="alert alert-error">
      <strong>Error:</strong> {{ error }}
      <button class="btn btn-retry" @click="fetchHouseholds">Retry</button>
    </div>

    <!-- Household List -->
    <div v-else class="household-list">
      <div v-if="households.length === 0" class="alert alert-info">
        No households found.
      </div>

      <div v-else>
        <div class="table-wrapper">
          <table class="households-table">
            <thead>
              <tr>
                <th class="checkbox-col">
                  <input 
                    type="checkbox" 
                    v-model="selectAll"
                    @change="toggleSelectAll"
                    class="checkbox-header"
                    title="Select/Deselect all"
                  >
                </th>
                <th>Name</th>
                <th>Owner</th>
                <th>Email</th>
                <th>Created</th>
                <th>Updated</th>
                <th>Phone</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="household in households" 
                :key="household.id"
                class="household-row"
                :class="{ 'row-selected': selectedHouseholds.includes(household.id) }"
              >
                <td class="checkbox-col">
                  <input 
                    type="checkbox" 
                    v-model="selectedHouseholds"
                    :value="household.id"
                    @change="updateSelectAllCheckbox"
                    class="checkbox-row"
                  >
                </td>
                <td class="name-col">{{ household.name }}</td>
                <td class="owner-col">{{ household.ownerName }}</td>
                <td class="email-col">
                  <span class="masked-text" :title="household.email">{{ maskEmail(household.email) }}</span>
                  <button class="copy-btn" @click="copyToClipboard(household.email, 'copy')" title="Copy email">
                    📋
                  </button>
                </td>
                <td class="date-col">{{ formatDate(household.createTime) }}</td>
                <td class="date-col">{{ formatDate(household.updateTime) }}</td>
                <td class="phone-col">
                  <span class="masked-text" :title="household.phone">{{ maskPhone(household.phone) }}</span>
                  <button class="copy-btn" @click="copyToClipboard(household.phone, 'copy')" title="Copy phone">
                    📋
                  </button>
                </td>
                <td class="actions-col">
                  <button class="btn btn-sm btn-edit" @click="handleEdit(household)">Edit</button>
                  <button class="btn btn-sm btn-delete" @click="handleDelete(household.id)">Delete</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="household-stats">
          <p><strong>Total Households:</strong> {{ households.length }} | <strong>Selected:</strong> {{ selectedHouseholds.length }}</p>
        </div>
      </div>
    </div>
  </div>

  <!-- Modal for Create/Update Household -->
  <div v-if="showModal" class="modal-overlay" @click="closeModal">
    <div class="modal" @click.stop>
      <div class="modal-header">
        <h3>{{ isEditMode ? 'Edit Household' : 'Create Household' }}</h3>
        <button class="modal-close" @click="closeModal">&times;</button>
      </div>
      <div class="modal-body">
        <form @submit.prevent="submitForm">
          <div class="form-group">
            <label for="household-name">Household Name *</label>
            <input 
              id="household-name"
              v-model="formData.name" 
              type="text" 
              placeholder="Enter household name"
              required
            >
          </div>
          <div class="form-group">
            <label for="household-owner">Owner Name *</label>
            <input 
              id="household-owner"
              v-model="formData.ownerName" 
              type="text" 
              placeholder="Enter owner name"
              required
            >
          </div>
          <div class="form-group">
            <label for="household-email">Email *</label>
            <input 
              id="household-email"
              v-model="formData.email" 
              type="email" 
              placeholder="Enter email address"
              required
            >
          </div>
          <div class="form-group">
            <label for="household-phone">Phone *</label>
            <input 
              id="household-phone"
              v-model="formData.phone" 
              type="tel" 
              placeholder="Enter phone number"
              required
            >
          </div>
          <div v-if="isEditMode" class="form-group readonly">
            <label>Household ID</label>
            <input 
              v-model="formData.id" 
              type="text" 
              readonly
            >
          </div>
          <div v-if="isEditMode" class="form-group readonly">
            <label>Owner ID</label>
            <input 
              v-model="formData.ownerId" 
              type="text" 
              readonly
            >
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" @click="closeModal">Cancel</button>
        <button class="btn btn-primary" @click="submitForm">{{ isEditMode ? 'Update' : 'Create' }}</button>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios';
import householdDataService from '../data/householdDataService';

export default {
  name: 'HouseholdView',
  data() {
    return {
      username: 'User',
      currentUserId: '',
      households: [],
      isLoading: true,
      error: null,
      selectedHouseholds: [],
      selectAll: false,
      showModal: false,
      isEditMode: false,
      formData: {
        id: '',
        name: '',
        ownerName: '',
        email: '',
        phone: '',
        ownerId: ''
      },
      activeNotifications: [],
      notificationHistory: [],
      showHistory: false
    };
  },
  mounted() {
    this.fetchCurrentUser();
    this.fetchHouseholds();
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
          this.currentUserId = data.user.userId || '';
        }
      } catch (error) {
        console.error('Error fetching user:', error);
      }
    },
    async fetchHouseholds() {
      this.isLoading = true;
      this.error = null;

      try {
        this.households = await householdDataService.getAllHouseholds();
      } catch (error) {
        console.error('Error fetching households:', error);
        this.error = error.message || 'Failed to load households';
      } finally {
        this.isLoading = false;
      }
    },
    async handleRefresh() {
      this.isLoading = true;
      this.error = null;

      try {
        this.households = await householdDataService.refreshHouseholds();
        this.updateSelectAllCheckbox();
        this.addNotification('Household list refreshed', 'info');
      } catch (error) {
        console.error('Error refreshing households:', error);
        this.error = error.message || 'Failed to refresh households';
        this.addNotification(this.error, 'error');
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
    },
    toggleSelectAll() {
      if (this.selectAll) {
        this.selectedHouseholds = this.households.map(h => h.id);
      } else {
        this.selectedHouseholds = [];
      }
    },
    updateSelectAllCheckbox() {
      this.selectAll = this.selectedHouseholds.length === this.households.length && this.households.length > 0;
    },
    formatDate(dateString) {
      const date = new Date(dateString);
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    },
    maskEmail(email) {
      if (!email) return '';
      const [localPart, domain] = email.split('@');
      if (!domain) return email;
      const maskedLocal = localPart.substring(0, Math.ceil(localPart.length / 2)).replace(/./g, '*') + 
                          localPart.substring(Math.ceil(localPart.length / 2));
      return maskedLocal + '@' + domain;
    },
    maskPhone(phone) {
      if (!phone) return '';
      const halfLength = Math.ceil(phone.length / 2);
      return phone.substring(0, halfLength).replace(/./g, '*') + phone.substring(halfLength);
    },
    handleCreate() {
      this.isEditMode = false;
      this.formData = {
        id: '',
        name: '',
        ownerName: '',
        email: '',
        phone: '',
        ownerId: ''
      };
      this.showModal = true;
    },
    handleEdit(household) {
      this.isEditMode = true;
      this.formData = {
        id: household.id,
        name: household.name,
        ownerName: household.ownerName,
        email: household.email || '',
        phone: household.phone || '',
        ownerId: household.ownerId
      };
      this.showModal = true;
    },
    closeModal() {
      this.showModal = false;
      this.formData = {
        id: '',
        name: '',
        ownerName: '',
        email: '',
        phone: '',
        ownerId: ''
      };
    },
    async submitForm() {
      if (!this.formData.name || !this.formData.ownerName || !this.formData.email || !this.formData.phone) {
        this.addNotification('Please fill in all required fields', 'error');
        return;
      }
      const ownerId = this.formData.ownerId || this.currentUserId;
      if (!ownerId) {
        this.addNotification('Missing owner ID. Please re-login and try again.', 'error');
        return;
      }

      try {
        if (this.isEditMode) {
          await householdDataService.updateHousehold(this.formData.id, {
            name: this.formData.name,
            ownerName: this.formData.ownerName,
            email: this.formData.email,
            phone: this.formData.phone
          });
          this.addNotification(`Updated household: ${this.formData.name}`, 'success');
        } else {
          await householdDataService.createHousehold({
            name: this.formData.name,
            ownerId,
            ownerName: this.formData.ownerName,
            email: this.formData.email,
            phone: this.formData.phone
          });
          this.addNotification(`Created household: ${this.formData.name}`, 'success');
        }
        this.households = await householdDataService.getAllHouseholds();
        this.updateSelectAllCheckbox();
        this.closeModal();
      } catch (error) {
        console.error('Error saving household:', error);
        this.addNotification(error.message || 'Failed to save household', 'error');
      }
    },
    async handleDelete(householdId) {
      if (confirm('Are you sure you want to delete this household?')) {
        try {
          await householdDataService.deleteHousehold(householdId);
          this.households = await householdDataService.getAllHouseholds();
          this.selectedHouseholds = this.selectedHouseholds.filter(id => id !== householdId);
          this.updateSelectAllCheckbox();
          this.addNotification(`Deleted household: ${householdId}`, 'success');
        } catch (error) {
          console.error('Error deleting household:', error);
          this.addNotification(error.message || 'Failed to delete household', 'error');
        }
      }
    },
    async handleDeleteSelected() {
      if (this.selectedHouseholds.length === 0) return;
      if (confirm(`Delete ${this.selectedHouseholds.length} selected households?`)) {
        const selectedIds = [...this.selectedHouseholds];
        try {
          await Promise.all(selectedIds.map(id => householdDataService.deleteHousehold(id)));
          this.households = await householdDataService.getAllHouseholds();
          this.selectedHouseholds = [];
          this.updateSelectAllCheckbox();
          this.addNotification(`Deleted ${selectedIds.length} households`, 'success');
        } catch (error) {
          console.error('Error deleting households:', error);
          this.addNotification(error.message || 'Failed to delete households', 'error');
        }
      }
    },
    copyToClipboard(text, type) {
      navigator.clipboard.writeText(text).then(() => {
        this.addNotification(text, 'success');
      }).catch(() => {
        // Fallback for older browsers
        const textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        this.addNotification(text, 'success');
      });
    },
    addNotification(message, type = 'info', duration = 8000) {
      const notification = {
        message,
        type,
        id: Date.now() + Math.random(), // Ensure uniqueness
        timestamp: new Date()
      };
      
      // Add to active notifications (shown as toast)
      this.activeNotifications.unshift(notification);
      
      // Add to history
      this.notificationHistory.unshift(notification);
      
      // Auto-dismiss from active notifications after duration
      if (duration > 0) {
        setTimeout(() => {
          this.dismissNotification(notification.id);
        }, duration);
      }
    },
    dismissNotification(id) {
      const index = this.activeNotifications.findIndex(n => n.id === id);
      if (index > -1) {
        this.activeNotifications.splice(index, 1);
      }
    },
    toggleHistory() {
      this.showHistory = !this.showHistory;
    },
    clearHistory() {
      if (confirm('Clear all notification history?')) {
        this.notificationHistory = [];
      }
    },
    formatNotificationTime(timestamp) {
      const now = new Date();
      const diff = now - timestamp;
      const seconds = Math.floor(diff / 1000);
      const minutes = Math.floor(seconds / 60);
      const hours = Math.floor(minutes / 60);
      const days = Math.floor(hours / 24);
      
      if (days > 0) return `${days}d ago`;
      if (hours > 0) return `${hours}h ago`;
      if (minutes > 0) return `${minutes}m ago`;
      return `${seconds}s ago`;
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
  position: relative;
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

.notification-panel {
  position: fixed;
  top: 70px;
  right: 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  z-index: 999;
  max-width: 400px;
  pointer-events: none;
}

.notification-panel > * {
  pointer-events: auto;
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
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-logout:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(102, 126, 234, 0.3);
}

.btn-history {
  background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
  color: white;
  border-radius: 20px;
  font-size: 0.85em;
  padding: 8px 14px;
}

.btn-history:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(40, 167, 69, 0.3);
}

.btn-retry {
  background: #667eea;
  color: white;
  margin-left: 10px;
}

.btn-retry:hover {
  background: #5568d3;
}

.container {
  padding: 20px;
  width: 100%;
  margin: 0;
  display: flex;
  flex-direction: column;
}

.household-header {
  margin-bottom: 15px;
}

.household-header h2 {
  color: #333;
  margin: 0 0 10px 0;
}

.household-header p {
  color: #666;
  margin: 0;
}

.action-toolbar {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
  flex-wrap: wrap;
}

.btn-create {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-create:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-refresh {
  background: #2d9cdb;
  color: white;
}

.btn-refresh:hover:not(:disabled) {
  background: #1b83c3;
  transform: translateY(-2px);
}

.btn-refresh:disabled {
  background: #9cc9e6;
  cursor: not-allowed;
  opacity: 0.7;
}

.btn-delete-selected {
  background: #dc3545;
  color: white;
}

.btn-delete-selected:hover:not(:disabled) {
  background: #c82333;
  transform: translateY(-2px);
}

.btn-delete-selected:disabled {
  background: #ccc;
  cursor: not-allowed;
  opacity: 0.6;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  color: #666;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.alert {
  padding: 15px 20px;
  border-radius: 8px;
  margin-bottom: 20px;
}

.alert-error {
  background-color: #fee;
  border: 1px solid #fcc;
  color: #c33;
}

.alert-info {
  background-color: #e3f2fd;
  border: 1px solid #90caf9;
  color: #1976d2;
}

.households-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.household-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 20px;
  transition: all 0.3s;
}

.household-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
}

.household-card-header {
  margin-bottom: 15px;
  padding-bottom: 15px;
  border-bottom: 2px solid #f0f0f0;
}

.household-card-header h3 {
  margin: 0 0 8px 0;
  color: #333;
  font-size: 1.3em;
}

.household-id {
  color: #666;
  font-size: 0.85em;
  font-weight: normal;
}

.household-details {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
}

.detail-row .label {
  font-weight: 600;
  color: #555;
  font-size: 0.9em;
}

.detail-row .value {
  color: #333;
  font-size: 0.9em;
  text-align: right;
}

.detail-row code {
  background: #f5f5f5;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.85em;
  color: #d63384;
}

.table-wrapper {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  overflow-x: auto;
  overflow-y: hidden;
  margin-bottom: 30px;
  width: 100%;
}

.households-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9em;
}

.households-table thead {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.households-table thead tr {
  border-bottom: 2px solid #ddd;
}

.households-table thead th {
  padding: 15px;
  text-align: left;
  color: white;
  font-weight: 600;
  background-color: #667eea;
  border: none;
}

.households-table tbody tr {
  border-bottom: 1px solid #eee;
  transition: background-color 0.2s;
}

.households-table tbody tr:hover {
  background-color: #f9f9f9;
}

.households-table tbody tr.row-selected {
  background-color: #e8eef7;
}

.households-table tbody tr.row-selected:hover {
  background-color: #dde6f0;
}

.households-table tbody td {
  padding: 12px 15px;
  color: #333;
}

.checkbox-col {
  width: 50px;
  text-align: center;
}

.checkbox-header,
.checkbox-row {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #667eea;
}

.checkbox-header {
  margin: 0;
}

.name-col {
  font-weight: 600;
  color: #333;
}

.owner-col {
  color: #555;
}

.date-col {
  color: #777;
  font-size: 0.85em;
  white-space: nowrap;
}

.actions-col {
  width: 180px;
  text-align: center;
  padding: 8px 15px !important;
  white-space: nowrap;
}

.btn-sm {
  padding: 6px 10px;
  font-size: 0.8em;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
  margin: 0 3px;
  display: inline-block;
}

.btn-edit {
  background: #667eea;
  color: white;
}

.btn-edit:hover {
  background: #5568d3;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(102, 126, 234, 0.3);
}

.btn-delete {
  background: #dc3545;
  color: white;
}

.btn-delete:hover {
  background: #c82333;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(220, 53, 69, 0.3);
}

.household-stats {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 20px;
  border-radius: 12px;
  text-align: center;
}

.household-stats p {
  margin: 0;
  font-size: 1.1em;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
  max-width: 500px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  animation: modalSlideIn 0.3s ease-out;
}

@keyframes modalSlideIn {
  from {
    opacity: 0;
    transform: translateY(-50px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #eee;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.modal-header h3 {
  margin: 0;
  font-size: 1.3em;
}

.modal-close {
  background: none;
  border: none;
  font-size: 28px;
  cursor: pointer;
  color: white;
  padding: 0 5px;
  transition: transform 0.2s;
}

.modal-close:hover {
  transform: scale(1.2);
}

.modal-body {
  padding: 30px 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #333;
  font-size: 0.95em;
}

.form-group input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.95em;
  font-family: inherit;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-group.readonly input {
  background-color: #f5f5f5;
  color: #999;
  cursor: not-allowed;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 20px;
  border-top: 1px solid #eee;
  background: #f9f9f9;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 10px 20px;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-secondary {
  background: #ccc;
  color: #333;
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: #bbb;
}

/* Masked text styles */
.email-col,
.phone-col {
  font-family: 'Courier New', monospace;
  font-size: 0.9em;
  display: flex;
  align-items: center;
  gap: 8px;
}

.masked-text {
  cursor: help;
}

.email-col:hover .masked-text,
.phone-col:hover .masked-text {
  font-weight: bold;
  color: #667eea;
}

.copy-btn {
  background: none;
  border: none;
  font-size: 1rem;
  cursor: pointer;
  padding: 2px 4px;
  opacity: 0.6;
  transition: opacity 0.2s;
  display: inline-block;
  line-height: 1;
}

.copy-btn:hover {
  opacity: 1;
}

/* Notification Styles */
.notification {
  background: rgba(255, 255, 255, 0.5);
  backdrop-filter: blur(10px);
  border-left: 4px solid #667eea;
  padding: 12px 16px;
  border-radius: 4px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  animation: slideInRight 0.3s ease-out;
  min-width: 250px;
  max-width: 100%;
  word-wrap: break-word;
}

.notification-success {
  border-left-color: #28a745;
}

.notification-success .notification-content {
  color: #155724;
}

.notification-info {
  border-left-color: #667eea;
}

.notification-info .notification-content {
  color: #004085;
}

.notification-error {
  border-left-color: #dc3545;
}

.notification-error .notification-content {
  color: #721c24;
}

.notification-content {
  flex: 1;
  font-size: 0.9em;
  font-family: 'Courier New', monospace;
  word-break: break-all;
}

.notification-close {
  background: none;
  border: none;
  font-size: 1.2em;
  cursor: pointer;
  color: #999;
  padding: 0;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.2s;
}

.notification-close:hover {
  color: #333;
}

@keyframes slideInRight {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

/* Notification History Toggle Button */
/* Notification History Panel */
.notification-history-panel {
  position: fixed;
  top: 70px;
  right: 20px;
  width: 400px;
  max-height: 500px;
  background: rgba(255, 255, 255, 0.5);
  backdrop-filter: blur(10px);
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
  z-index: 997;
  display: flex;
  flex-direction: column;
  animation: slideInRight 0.3s ease-out;
}

.history-header {
  padding: 16px 20px;
  border-bottom: 2px solid rgba(240, 240, 240, 0.5);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.9) 0%, rgba(118, 75, 162, 0.9) 100%);
  color: white;
  border-radius: 8px 8px 0 0;
}

.history-header h3 {
  margin: 0;
  font-size: 1.1em;
}

.history-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.btn-clear-history {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 4px;
  padding: 6px 12px;
  cursor: pointer;
  font-size: 0.85em;
  transition: all 0.2s;
}

.btn-clear-history:hover {
  background: rgba(255, 255, 255, 0.3);
}

.btn-close-history {
  background: none;
  border: none;
  color: white;
  font-size: 1.5em;
  cursor: pointer;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s;
}

.btn-close-history:hover {
  transform: scale(1.2);
}

.history-content {
  overflow-y: auto;
  max-height: 440px;
  padding: 10px;
}

.history-empty {
  padding: 40px 20px;
  text-align: center;
  color: #999;
  font-style: italic;
}

.history-item {
  background: rgba(248, 249, 250, 0.6);
  border-left: 4px solid #667eea;
  border-radius: 4px;
  padding: 12px;
  margin-bottom: 8px;
  transition: all 0.2s;
}

.history-item:hover {
  background: rgba(233, 236, 239, 0.8);
  transform: translateX(2px);
}

.history-item-success {
  border-left-color: #28a745;
}

.history-item-error {
  border-left-color: #dc3545;
}

.history-item-info {
  border-left-color: #667eea;
}

.history-item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.history-item-time {
  font-size: 0.75em;
  color: #999;
}

.history-item-message {
  font-size: 0.9em;
  color: #333;
  font-family: 'Courier New', monospace;
  word-break: break-word;
}
</style>
