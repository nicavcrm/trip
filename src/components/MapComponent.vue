<template>
  <div ref="mapContainer" class="map-container">
    <div v-if="loading" class="loading-overlay">
      <div class="loading-spinner"></div>
      <p>Loading map...</p>
    </div>
    <div v-if="error" class="error-overlay">
      <p>{{ error }}</p>
    </div>

    <!-- Topic Filter -->
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

    <!-- Legend -->
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
  </div>
</template>

<script>
import mapboxgl from 'mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'

export default {
  name: 'MapComponent',
  emits: ['point-clicked', 'stats-updated'],
  data() {
    return {
      map: null,
      loading: true,
      error: null,
      geoData: null,
      selectedTopic: 'all'
    }
  },
  computed: {
    filteredFeatures() {
      if (!this.geoData || !this.geoData.features) return []
      if (this.selectedTopic === 'all') return this.geoData.features
      return [this.geoData.features[this.selectedTopic]]
    }
  },
  watch: {
    selectedTopic() {
      this.updateMapFilter()
    }
  },
  async mounted() {
    await this.initializeMap()
  },
  beforeUnmount() {
    if (this.map) {
      this.map.remove()
    }
  },
  methods: {
    async initializeMap() {
      try {
        // Check for Mapbox token
        const token = import.meta.env.VITE_MAPBOX_TOKEN || "pk.eyJ1IjoiYXZjcm0iLCJhIjoiY2xhZHVlYng0MGhlbTNwcWt6d3BvYXN1NyJ9.kzEn37oH9cDgdG0Cw_0Cbw"
        if (!token || token === 'your_mapbox_access_token_here') {
          throw new Error('Please set your Mapbox access token in the .env file')
        }

        mapboxgl.accessToken = token

        // Load GeoJSON data
        await this.loadGeoData()

        // Initialize map
        this.map = new mapboxgl.Map({
          container: this.$refs.mapContainer,
          style: 'mapbox://styles/mapbox/outdoors-v12',
          center: [150.914042, -34.361994], // Default center from the data
          zoom: 15
        })

        this.map.on('load', () => {
          this.addGeoDataToMap()
          this.addMapControls()
          this.calculateAndEmitStats()
          this.loading = false
        })

        this.map.on('error', (e) => {
          console.error('Map error:', e)
          this.error = 'Failed to load map'
          this.loading = false
        })

      } catch (err) {
        console.error('Error initializing map:', err)
        this.error = err.message
        this.loading = false
      }
    },

    async loadGeoData() {
      try {
        const response = await fetch('./geo.json')
        if (!response.ok) {
          throw new Error('Failed to load geo data')
        }
        this.geoData = await response.json()
      } catch (err) {
        throw new Error('Could not load geo.json file: ' + err.message)
      }
    },

    addGeoDataToMap() {
      if (!this.geoData || !this.geoData.features) {
        console.warn('No geo data to display')
        return
      }

      // Define colors for different features
      const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#feca57', '#ff9ff3', '#54a0ff']

      // Add feature index to each feature for color differentiation
      this.geoData.features.forEach((feature, index) => {
        feature.properties.feature_index = index
      })

      // Add GeoJSON source
      this.map.addSource('geo-paths', {
        type: 'geojson',
        data: this.geoData
      })

      // Add line layer with different colors for each feature
      this.map.addLayer({
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
            ...this.geoData.features.flatMap((feature, index) => [
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
      const pointFeatures = this.createPointFeatures()

      this.map.addSource('geo-points', {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: pointFeatures
        }
      })

      // Add points layer with matching colors
      this.map.addLayer({
        id: 'path-points',
        type: 'circle',
        source: 'geo-points',
        paint: {
          'circle-radius': 6,
          'circle-color': [
            'case',
            ...this.geoData.features.flatMap((feature, index) => [
              ['==', ['get', 'feature_index'], index],
              colors[index % colors.length]
            ]),
            '#4ecdc4' // fallback color
          ],
          'circle-stroke-color': '#ffffff',
          'circle-stroke-width': 2
        }
      })

      // Add hover effect
      this.map.addLayer({
        id: 'path-points-hover',
        type: 'circle',
        source: 'geo-points',
        paint: {
          'circle-radius': 8,
          'circle-color': '#ff9f43',
          'circle-stroke-color': '#ffffff',
          'circle-stroke-width': 3
        },
        filter: ['==', 'point_index', '']
      })

      // Set up click handlers
      this.setupPointInteractions()

      // Fit map to show all features
      this.fitMapToFeatures()
    },

    createPointFeatures() {
      const pointFeatures = []

      this.geoData.features.forEach((feature, featureIndex) => {
        if (feature.geometry.type === 'LineString') {
          feature.geometry.coordinates.forEach((coord, pointIndex) => {
            const pointProperties = feature.properties.points_properties?.[pointIndex] || {}

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
        }
      })

      return pointFeatures
    },

    setupPointInteractions() {
      // Change cursor on hover
      this.map.on('mouseenter', 'path-points', () => {
        this.map.getCanvas().style.cursor = 'pointer'
      })

      this.map.on('mouseleave', 'path-points', () => {
        this.map.getCanvas().style.cursor = ''
        // Clear hover effect
        this.map.setFilter('path-points-hover', ['==', 'unique_id', ''])
      })

      // Show hover effect
      this.map.on('mousemove', 'path-points', (e) => {
        if (e.features.length > 0) {
          const uniqueId = e.features[0].properties.unique_id
          this.map.setFilter('path-points-hover', ['==', 'unique_id', uniqueId])
        }
      })

      // Handle clicks
      this.map.on('click', 'path-points', (e) => {
        if (e.features.length > 0) {
          const feature = e.features[0]
          this.$emit('point-clicked', {
            properties: feature.properties,
            coordinates: feature.geometry.coordinates
          })
        }
      })
    },

    fitMapToFeatures() {
      if (!this.geoData.features.length) return

      const bounds = new mapboxgl.LngLatBounds()

      this.geoData.features.forEach(feature => {
        if (feature.geometry.type === 'LineString') {
          feature.geometry.coordinates.forEach(coord => {
            bounds.extend(coord)
          })
        }
      })

      this.map.fitBounds(bounds, {
        padding: 50,
        maxZoom: 16
      })
    },

    calculateAndEmitStats() {
      const stats = this.geoData.features.map(feature => {
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

      this.$emit('stats-updated', stats)
    },

    addMapControls() {
      // Add zoom and rotation controls to the map
      this.map.addControl(new mapboxgl.NavigationControl(), 'bottom-left')

      // Add fullscreen control
      this.map.addControl(new mapboxgl.FullscreenControl(), 'bottom-left')
    },

    updateMapFilter() {
      if (!this.map) return

      // Update the filter for lines
      if (this.selectedTopic === 'all') {
        this.map.setFilter('path-lines', null)
        this.map.setFilter('path-points', null)
      } else {
        const filterExpression = ['==', ['get', 'feature_index'], parseInt(this.selectedTopic)]
        this.map.setFilter('path-lines', filterExpression)
        this.map.setFilter('path-points', filterExpression)
      }

      // Fit map to filtered features
      this.fitMapToFilteredFeatures()
    },

    fitMapToFilteredFeatures() {
      if (!this.filteredFeatures.length) return

      const bounds = new mapboxgl.LngLatBounds()

      this.filteredFeatures.forEach(feature => {
        if (feature.geometry.type === 'LineString') {
          feature.geometry.coordinates.forEach(coord => {
            bounds.extend(coord)
          })
        }
      })

      this.map.fitBounds(bounds, {
        padding: 50,
        maxZoom: 16
      })
    },

    getOriginalIndex(feature) {
      // Find the original index of the feature in the full dataset
      return this.geoData.features.findIndex(f => f.properties.topic === feature.properties.topic)
    },

    getColorForIndex(index) {
      const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#feca57', '#ff9ff3', '#54a0ff']
      return colors[index % colors.length]
    },

    getPointCount(feature) {
      return feature.geometry.coordinates.length
    }
  }
}
</script>

<style scoped>
.map-container {
  width: 100%;
  height: 100%;
  position: relative;
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
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-overlay {
  color: #e74c3c;
  font-weight: bold;
}

.topic-filter {
  position: absolute;
  top: 10px;
  left: 10px;
  background: rgba(255, 255, 255, 0.95);
  padding: 12px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
  z-index: 1000;
  backdrop-filter: blur(5px);
  min-width: 250px;
}

.topic-filter label {
  display: block;
  font-size: 12px;
  font-weight: bold;
  color: #333;
  margin-bottom: 6px;
}

.topic-filter select {
  width: 100%;
  padding: 6px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 12px;
  background: white;
  cursor: pointer;
}

.topic-filter select:focus {
  outline: none;
  border-color: #4ecdc4;
  box-shadow: 0 0 0 2px rgba(78, 205, 196, 0.2);
}

.map-legend {
  position: absolute;
  top: 10px;
  right: 10px;
  background: rgba(255, 255, 255, 0.95);
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
  z-index: 1000;
  min-width: 200px;
  backdrop-filter: blur(5px);
}

.map-legend h4 {
  margin: 0 0 10px 0;
  font-size: 14px;
  font-weight: bold;
  color: #333;
}

.legend-item {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  font-size: 12px;
}

.legend-color {
  width: 20px;
  height: 4px;
  margin-right: 8px;
  border-radius: 2px;
  flex-shrink: 0;
}

.legend-topic {
  font-weight: 500;
  color: #333;
  margin-right: 5px;
  word-break: break-all;
  flex: 1;
}

.legend-count {
  color: #666;
  font-size: 11px;
  white-space: nowrap;
}
</style>
