<template>
  <div class="app-layout" :style="{ '--sidebar-width': sidebarWidth + 'px' }">
    <aside class="sidebar" :style="{ width: sidebarWidth + 'px' }">
      <Navigation 
        :isCollapsed="isCollapsed"
        :currentPage="currentPage"
        @toggle-collapse="toggleCollapse"
        @navigate="handleNavigation"
      />
    </aside>
    
    <div 
      class="resize-handle" 
      @mousedown="startResize"
      title="Drag to resize"
    ></div>
    
    <main class="content">
      <slot :currentPage="currentPage"></slot>
    </main>
  </div>
</template>

<script>
import Navigation from './Navigation.vue';

export default {
  name: 'AppLayout',
  components: {
    Navigation
  },
  data() {
    return {
      sidebarWidth: 250,
      isCollapsed: false,
      currentPage: 'dashboard',
      isResizing: false,
      startX: 0,
      startWidth: 0,
      collapsedWidth: 70,
      expandedWidth: 250
    };
  },
  mounted() {
    // Load saved sidebar state from localStorage
    const savedWidth = localStorage.getItem('app-sidebar-width');
    const savedCollapsed = localStorage.getItem('app-sidebar-collapsed');
    const savedPage = localStorage.getItem('app-current-page');
    
    if (savedCollapsed === 'true') {
      this.isCollapsed = true;
      this.sidebarWidth = this.collapsedWidth;
    } else if (savedWidth) {
      this.sidebarWidth = parseInt(savedWidth, 10);
      this.expandedWidth = this.sidebarWidth;
    }
    
    if (savedPage) {
      this.currentPage = savedPage;
      // Notify parent component about the restored page
      this.$emit('page-change', savedPage);
    }
    
    // Add mouse event listeners
    document.addEventListener('mousemove', this.onMouseMove);
    document.addEventListener('mouseup', this.stopResize);
  },
  beforeUnmount() {
    document.removeEventListener('mousemove', this.onMouseMove);
    document.removeEventListener('mouseup', this.stopResize);
  },
  methods: {
    handleNavigation(page) {
      this.currentPage = page;
      localStorage.setItem('app-current-page', page);
      this.$emit('page-change', page);
    },
    toggleCollapse() {
      this.isCollapsed = !this.isCollapsed;
      
      if (this.isCollapsed) {
        this.sidebarWidth = this.collapsedWidth;
      } else {
        this.sidebarWidth = this.expandedWidth;
      }
      
      localStorage.setItem('app-sidebar-collapsed', this.isCollapsed.toString());
    },
    startResize(e) {
      if (this.isCollapsed) return; // Don't resize when collapsed
      
      this.isResizing = true;
      this.startX = e.clientX;
      this.startWidth = this.sidebarWidth;
      document.body.style.cursor = 'col-resize';
      document.body.style.userSelect = 'none';
    },
    onMouseMove(e) {
      if (!this.isResizing || this.isCollapsed) return;
      
      const diff = e.clientX - this.startX;
      const newWidth = Math.max(200, Math.min(this.startWidth + diff, 500));
      
      this.sidebarWidth = newWidth;
      this.expandedWidth = newWidth;
    },
    stopResize() {
      if (this.isResizing) {
        this.isResizing = false;
        document.body.style.cursor = 'default';
        document.body.style.userSelect = 'auto';
        
        // Save sidebar width to localStorage
        localStorage.setItem('app-sidebar-width', this.sidebarWidth.toString());
      }
    }
  }
};
</script>

<style scoped>
.app-layout {
  display: flex;
  height: 100vh;
  width: 100%;
  overflow: hidden;
  --sidebar-width: 250px;
}

.sidebar {
  flex-shrink: 0;
  overflow: hidden;
  transition: width 0.3s ease-out;
}

.resize-handle {
  flex-shrink: 0;
  width: 4px;
  background: linear-gradient(180deg, #667eea 0%, #764ba2 100%);
  cursor: col-resize;
  transition: background 0.2s ease;
  position: relative;
  z-index: 10;
}

.resize-handle:hover {
  background: linear-gradient(180deg, #764ba2 0%, #667eea 100%);
  width: 6px;
  margin-left: -1px;
}

.content {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  display: flex;
  flex-direction: column;
}

/* Smooth scrollbar for content area */
.content::-webkit-scrollbar {
  width: 8px;
}

.content::-webkit-scrollbar-track {
  background: #f5f5f5;
}

.content::-webkit-scrollbar-thumb {
  background: #ddd;
  border-radius: 4px;
}

.content::-webkit-scrollbar-thumb:hover {
  background: #999;
}
</style>
