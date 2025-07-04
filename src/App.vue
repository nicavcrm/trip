<template>
  <div id="app">
    <header class="app-header">
      <h1>MQTT GeoPath Visualizer</h1>
      <div class="stats" v-if="pathStats.length > 0">
        <div v-for="stat in pathStats" :key="stat.topic" class="stat-item">
          <strong>{{ stat.topic }}</strong>: {{ stat.pointCount }} points,
          avg frequency: {{ stat.avgFrequency.toFixed(2) }} Hz
        </div>
      </div>
    </header>
    <main class="app-main">
      <MapComponent
        @point-clicked="onPointClicked"
        @stats-updated="onStatsUpdated"
      />
      <InfoModal
        v-if="selectedPoint"
        :point-data="selectedPoint"
        @close="selectedPoint = null"
      />
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import InfoModal from './components/InfoModal.vue'
import MapComponent from './components/MapComponent.vue'

const selectedPoint = ref(null)
const pathStats = ref([])

const onPointClicked = (pointData) => {
  selectedPoint.value = pointData
}

const onStatsUpdated = (stats) => {
  pathStats.value = stats
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

#app {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  background: #2c3e50;
  color: white;
  padding: 1rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.app-header h1 {
  margin-bottom: 0.5rem;
  font-size: 1.5rem;
}

.stats {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  font-size: 0.9rem;
}

.stat-item {
  background: rgba(255,255,255,0.1);
  padding: 0.5rem;
  border-radius: 4px;
}

.app-main {
  flex: 1;
  position: relative;
  overflow: hidden;
}

/* Mobile responsive styles */
@media (max-width: 768px) {
  .app-header {
    padding: 0.5rem;
  }

  .app-header h1 {
    font-size: 1.2rem;
    margin-bottom: 0.3rem;
  }

  .stats {
    gap: 0.5rem;
    font-size: 0.8rem;
  }

  .stat-item {
    padding: 0.3rem;
    font-size: 0.75rem;
  }
}
</style>
