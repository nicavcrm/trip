<template>
  <div class="map-wrapper">
    <!-- Loading overlay - outside map container to fix Mapbox warning -->
    <div v-if="loading" class="loading-overlay">
      <div class="loading-spinner"></div>
      <p>Loading map...</p>
    </div>

    <!-- Error overlay - outside map container to fix Mapbox warning -->
    <div v-if="error" class="error-overlay">
      <p>{{ error }}</p>
    </div>

    <!-- Map container - kept empty to fix Mapbox warning -->
    <div ref="mapContainer" class="map-container"></div>

    <!-- Active Topics Legend - moved above dropdown -->
    <div v-if="!loading && !error && geoData && geoData.features" class="map-legend">
      <h4>Active Topics</h4>
      <div
        v-for="(feature, index) in filteredFeatures"
        :key="index"
        class="legend-item"
      >
        <div
          class="legend-color"
          :style="{ backgroundColor: getColorForIndex(getOriginalIndex(feature)) }"
        ></div>
        <span class="legend-topic">{{ feature.properties.topic }}</span>
        <span class="legend-count">({{ getPointCount(feature) }} points)</span>
      </div>
    </div>

    <!-- Topic Filter - moved below legend -->
    <div v-if="!loading && !error && geoData && geoData.features" class="topic-filter">
      <label for="topic-select">Filter by Topic:</label>
      <select id="topic-select" v-model="selectedTopic">
        <option value="all">Show All Topics</option>
        <option
          v-for="(feature, index) in geoData.features"
          :key="index"
          :value="index"
        >
          {{ feature.properties.topic }} ({{ getPointCount(feature) }} points)
        </option>
      </select>
    </div>
  </div>
</template>

<script setup>
import mapboxgl from 'mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'

const emit = defineEmits(['point-clicked', 'stats-updated'])

// Reactive data
const map = ref(null)
const loading = ref(true)
const error = ref(null)
const geoData = ref(null)
const selectedTopic = ref('all')
const mapContainer = ref(null)

// Computed properties
const filteredFeatures = computed(() => {
  if (!geoData.value || !geoData.value.features) return []
  if (selectedTopic.value === 'all') return geoData.value.features
  return [geoData.value.features[selectedTopic.value]]
})

// Watchers
watch(selectedTopic, () => {
  updateMapFilter()
})

// Methods
const initializeMap = async () => {
  try {
    // Check for Mapbox token
    const token = import.meta.env.VITE_MAPBOX_TOKEN || "pk.eyJ1IjoiYXZjcm0iLCJhIjoiY2xhZHVlYng0MGhlbTNwcWt6d3BvYXN1NyJ9.kzEn37oH9cDgdG0Cw_0Cbw"
    if (!token || token === 'your_mapbox_access_token_here') {
      throw new Error('Please set your Mapbox access token in the .env file')
    }

    mapboxgl.accessToken = token

    // Load GeoJSON data
    await loadGeoData()

    // Initialize map
    map.value = new mapboxgl.Map({
      container: mapContainer.value,
      style: 'mapbox://styles/mapbox/outdoors-v12',
      center: [150.914042, -34.361994], // Default center from the data
      zoom: 15
    })

    map.value.on('load', () => {
      addGeoDataToMap()
      addMapControls()
      calculateAndEmitStats()
      loading.value = false
    })

    map.value.on('error', (e) => {
      console.error('Map error:', e)
      error.value = 'Failed to load map'
      loading.value = false
    })

  } catch (err) {
    console.error('Error initializing map:', err)
    error.value = err.message
    loading.value = false
  }
}

const loadGeoData = async () => {
  try {
    const response = await fetch('./geo.json')
    if (!response.ok) {
      throw new Error('Failed to load geo data')
    }
    geoData.value = await response.json()
  } catch (err) {
    throw new Error('Could not load geo.json file: ' + err.message)
  }
}

const addGeoDataToMap = () => {
  if (!geoData.value || !geoData.value.features) {
    console.warn('No geo data to display')
    return
  }

  // Define colors for different features
  const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#feca57', '#ff9ff3', '#54a0ff']

  // Add feature index to each feature for color differentiation
  geoData.value.features.forEach((feature, index) => {
    feature.properties.feature_index = index
  })

  // Add GeoJSON source
  map.value.addSource('geo-paths', {
    type: 'geojson',
    data: geoData.value
  })

  // Add line layer with different colors for each feature
  map.value.addLayer({
    id: 'path-lines',
    type: 'line',
    source: 'geo-paths',
    layout: {
      'line-join': 'round',
      'line-cap': 'round'
    },
    paint: {
      'line-color': [
        'case',
        ...geoData.value.features.flatMap((feature, index) => [
          ['==', ['get', 'feature_index'], index],
          colors[index % colors.length]
        ]),
        '#ff6b6b' // fallback color
      ],
      'line-width': 4,
      'line-dasharray': [2, 4] // Dashed pattern
    }
  })

  // Create point features for interactivity
  const pointFeatures = createPointFeatures()

  map.value.addSource('geo-points', {
    type: 'geojson',
    data: {
      type: 'FeatureCollection',
      features: pointFeatures
    }
  })

  // Add points layer with matching colors
  map.value.addLayer({
    id: 'path-points',
    type: 'circle',
    source: 'geo-points',
    paint: {
      'circle-radius': 6,
      'circle-color': [
        'case',
        ...geoData.value.features.flatMap((feature, index) => [
          ['==', ['get', 'feature_index'], index],
          colors[index % colors.length]
        ]),
        '#ff6b6b' // fallback color
      ],
      'circle-stroke-width': 2,
      'circle-stroke-color': '#ffffff'
    }
  })

  // Add click event for points
  map.value.on('click', 'path-points', (e) => {
    if (e.features.length > 0) {
      const feature = e.features[0]
      emit('point-clicked', {
        coordinates: feature.geometry.coordinates,
        properties: feature.properties
      })
    }
  })

  // Change cursor on hover
  map.value.on('mouseenter', 'path-points', () => {
    map.value.getCanvas().style.cursor = 'pointer'
  })

  map.value.on('mouseleave', 'path-points', () => {
    map.value.getCanvas().style.cursor = ''
  })

  // Fit map to show all data
  fitMapToAllFeatures()
}

const createPointFeatures = () => {
  const pointFeatures = []

  geoData.value.features.forEach((feature, featureIndex) => {
    const coordinates = feature.geometry.coordinates
    const pointsProperties = feature.properties.points_properties || []

    coordinates.forEach((coord, pointIndex) => {
      const pointProperties = pointsProperties[pointIndex] || {}

      pointFeatures.push({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: coord
        },
        properties: {
          ...pointProperties,
          topic: feature.properties.topic,
          feature_index: featureIndex,
          point_index: pointIndex,
          unique_id: `${featureIndex}-${pointIndex}`
        }
      })
    })
  })

  return pointFeatures
}

const fitMapToAllFeatures = () => {
  const bounds = new mapboxgl.LngLatBounds()

  geoData.value.features.forEach(feature => {
    if (feature.geometry.type === 'LineString') {
      feature.geometry.coordinates.forEach(coord => {
        bounds.extend(coord)
      })
    }
  })

  map.value.fitBounds(bounds, {
    padding: 50,
    maxZoom: 16
  })
}

const calculateAndEmitStats = () => {
  const stats = geoData.value.features.map(feature => {
    const coordinates = feature.geometry.coordinates
    const pointsProperties = feature.properties.points_properties || []

    let avgFrequency = 0
    if (pointsProperties.length > 1) {
      // Calculate frequency based on timestamps
      const timestamps = pointsProperties
        .map(p => p.timestamp)
        .filter(t => t)
        .map(t => new Date(t).getTime())
        .sort((a, b) => a - b)

      if (timestamps.length > 1) {
        const totalTime = (timestamps[timestamps.length - 1] - timestamps[0]) / 1000 // seconds
        const intervals = timestamps.length - 1
        avgFrequency = intervals / totalTime
      }
    }

    return {
      topic: feature.properties.topic,
      pointCount: coordinates.length,
      avgFrequency: avgFrequency
    }
  })

  emit('stats-updated', stats)
}

const addMapControls = () => {
  // Add zoom and rotation controls to the map
  map.value.addControl(new mapboxgl.NavigationControl(), 'bottom-left')

  // Add fullscreen control
  map.value.addControl(new mapboxgl.FullscreenControl(), 'bottom-left')
}

const updateMapFilter = () => {
  if (!map.value) return

  // Update the filter for lines
  if (selectedTopic.value === 'all') {
    map.value.setFilter('path-lines', null)
    map.value.setFilter('path-points', null)
  } else {
    const filterExpression = ['==', ['get', 'feature_index'], parseInt(selectedTopic.value)]
    map.value.setFilter('path-lines', filterExpression)
    map.value.setFilter('path-points', filterExpression)
  }

  // Fit map to filtered features
  fitMapToFilteredFeatures()
}

const fitMapToFilteredFeatures = () => {
  if (!filteredFeatures.value.length) return

  const bounds = new mapboxgl.LngLatBounds()

  filteredFeatures.value.forEach(feature => {
    if (feature.geometry.type === 'LineString') {
      feature.geometry.coordinates.forEach(coord => {
        bounds.extend(coord)
      })
    }
  })

  map.value.fitBounds(bounds, {
    padding: 50,
    maxZoom: 16
  })
}

const getOriginalIndex = (feature) => {
  // Find the original index of the feature in the full dataset
  return geoData.value.features.findIndex(f => f.properties.topic === feature.properties.topic)
}

const getColorForIndex = (index) => {
  const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#feca57', '#ff9ff3', '#54a0ff']
  return colors[index % colors.length]
}

const getPointCount = (feature) => {
  return feature.geometry.coordinates.length
}

// Lifecycle hooks
onMounted(async () => {
  await initializeMap()
})

onBeforeUnmount(() => {
  if (map.value) {
    map.value.remove()
  }
})
</script>

<style scoped>
.map-wrapper {
  position: relative;
  width: 100%;
  height: 100%;
}

.map-container {
  width: 100%;
  height: 100%;
}

.loading-overlay,
.error-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.9);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.loading-spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 2s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-overlay p {
  color: #e74c3c;
  font-weight: bold;
  text-align: center;
  padding: 1rem;
}

.topic-filter {
  position: absolute;
  top: 130px;
  left: 10px;
  background: rgba(255, 255, 255, 0.95);
  padding: 12px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  font-size: 14px;
  min-width: 300px;
}

.topic-filter label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
  color: #333;
}

.topic-filter select {
  width: 100%;
  min-width: 280px;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: white;
}

.map-legend {
  position: absolute;
  top: 10px;
  left: 10px;
  background: rgba(255, 255, 255, 0.95);
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  font-size: 12px;
  min-width: 300px;
  max-width: 350px;
}

.map-legend h4 {
  margin: 0 0 10px 0;
  font-size: 14px;
  color: #333;
  border-bottom: 1px solid #eee;
  padding-bottom: 5px;
}

.legend-item {
  display: flex;
  align-items: center;
  margin-bottom: 5px;
  gap: 8px;
}

.legend-color {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.legend-topic {
  font-weight: bold;
  color: #333;
  flex: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.legend-count {
  color: #666;
  font-size: 11px;
  flex-shrink: 0;
}

/* Mobile responsive styles */
@media (max-width: 768px) {
  .map-legend {
    min-width: 200px;
    max-width: 250px;
    padding: 10px;
    font-size: 11px;
  }

  .map-legend h4 {
    font-size: 12px;
    margin-bottom: 8px;
  }

  .legend-item {
    margin-bottom: 4px;
    gap: 6px;
  }

  .legend-color {
    width: 10px;
    height: 10px;
  }

  .legend-topic {
    font-size: 11px;
  }

  .legend-count {
    font-size: 10px;
  }

  .topic-filter {
    min-width: 200px;
    padding: 8px;
    font-size: 12px;
    top: 110px;
  }

  .topic-filter label {
    font-size: 12px;
    margin-bottom: 4px;
  }

  .topic-filter select {
    min-width: 180px;
    padding: 6px;
    font-size: 12px;
  }
}
</style>
