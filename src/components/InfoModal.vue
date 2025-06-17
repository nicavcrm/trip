<template>
  <div class="modal-backdrop" @click="$emit('close')">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h3>Point Information</h3>
        <button class="close-button" @click="$emit('close')">&times;</button>
      </div>

      <div class="modal-body">
        <div class="info-section">
          <h4>Location</h4>
          <div class="info-grid">
            <div class="info-item">
              <span class="label">Topic:</span>
              <span class="value">{{ pointData.properties.topic }}</span>
            </div>
            <div class="info-item">
              <span class="label">Coordinates:</span>
              <span class="value">
                {{ formatCoordinate(pointData.coordinates[1], 'lat') }},
                {{ formatCoordinate(pointData.coordinates[0], 'lng') }}
              </span>
            </div>
            <div class="info-item" v-if="pointData.properties.timestamp">
              <span class="label">Timestamp:</span>
              <span class="value">{{ formatTimestamp(pointData.properties.timestamp) }}</span>
            </div>
          </div>
        </div>

        <div class="info-section" v-if="hasFlightData">
          <h4>Flight Data</h4>
          <div class="info-grid">
            <div class="info-item" v-if="pointData.properties.gps_alt !== undefined">
              <span class="label">Altitude:</span>
              <span class="value">{{ pointData.properties.gps_alt }}m</span>
            </div>
            <div class="info-item" v-if="pointData.properties.height !== undefined">
              <span class="label">Height:</span>
              <span class="value">{{ pointData.properties.height }}m</span>
            </div>
            <div class="info-item" v-if="pointData.properties.attitude_head !== undefined">
              <span class="label">Heading:</span>
              <span class="value">{{ pointData.properties.attitude_head }}°</span>
            </div>
            <div class="info-item" v-if="pointData.properties.imu_yaw !== undefined">
              <span class="label">Yaw:</span>
              <span class="value">{{ pointData.properties.imu_yaw }}°</span>
            </div>
            <div class="info-item" v-if="pointData.properties.imu_pitch !== undefined">
              <span class="label">Pitch:</span>
              <span class="value">{{ pointData.properties.imu_pitch }}°</span>
            </div>
            <div class="info-item" v-if="pointData.properties.imu_roll !== undefined">
              <span class="label">Roll:</span>
              <span class="value">{{ pointData.properties.imu_roll }}°</span>
            </div>
          </div>
        </div>

        <div class="info-section" v-if="hasSensorData">
          <h4>Sensor Data</h4>
          <div class="info-grid">
            <div class="info-item" v-if="pointData.properties.battery !== undefined">
              <span class="label">Battery:</span>
              <span class="value">{{ pointData.properties.battery }}%</span>
            </div>
            <div class="info-item" v-if="pointData.properties.temperature !== undefined">
              <span class="label">Temperature:</span>
              <span class="value">{{ pointData.properties.temperature }}°C</span>
            </div>
            <div class="info-item" v-if="pointData.properties.humidity !== undefined">
              <span class="label">Humidity:</span>
              <span class="value">{{ pointData.properties.humidity }}%</span>
            </div>
            <div class="info-item" v-if="pointData.properties.gps_accuracy !== undefined">
              <span class="label">GPS Accuracy:</span>
              <span class="value">{{ pointData.properties.gps_accuracy }}m</span>
            </div>
          </div>
        </div>

        <div class="info-section" v-if="hasDeviceData">
          <h4>Device Information</h4>
          <div class="info-grid">
            <div class="info-item" v-if="pointData.properties.device_id">
              <span class="label">Device ID:</span>
              <span class="value">{{ pointData.properties.device_id }}</span>
            </div>
            <div class="info-item" v-if="pointData.properties.device_type">
              <span class="label">Device Type:</span>
              <span class="value">{{ pointData.properties.device_type }}</span>
            </div>
          </div>
        </div>

        <div class="info-section" v-if="hasGyroData">
          <h4>Gyroscope Data</h4>
          <div class="info-grid">
            <div class="info-item" v-if="pointData.properties.gyro_x !== undefined">
              <span class="label">Gyro X:</span>
              <span class="value">{{ pointData.properties.gyro_x }}</span>
            </div>
            <div class="info-item" v-if="pointData.properties.gyro_y !== undefined">
              <span class="label">Gyro Y:</span>
              <span class="value">{{ pointData.properties.gyro_y }}</span>
            </div>
            <div class="info-item" v-if="pointData.properties.gyro_z !== undefined">
              <span class="label">Gyro Z:</span>
              <span class="value">{{ pointData.properties.gyro_z }}</span>
            </div>
          </div>
        </div>

        <!-- Additional properties that don't fit into other categories -->
        <div class="info-section" v-if="hasAdditionalProperties">
          <h4>Additional Data</h4>
          <div class="info-grid">
            <div
              class="info-item"
              v-for="(value, key) in additionalProperties"
              :key="key"
            >
              <span class="label">{{ formatPropertyName(key) }}:</span>
              <span class="value">{{ formatPropertyValue(value) }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted } from 'vue'

const props = defineProps({
  pointData: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['close'])

const hasFlightData = computed(() => {
  const properties = props.pointData.properties
  return properties.gps_alt !== undefined ||
         properties.height !== undefined ||
         properties.attitude_head !== undefined ||
         properties.imu_yaw !== undefined ||
         properties.imu_pitch !== undefined ||
         properties.imu_roll !== undefined
})

const hasSensorData = computed(() => {
  const properties = props.pointData.properties
  return properties.battery !== undefined ||
         properties.temperature !== undefined ||
         properties.humidity !== undefined ||
         properties.gps_accuracy !== undefined
})

const hasDeviceData = computed(() => {
  const properties = props.pointData.properties
  return properties.device_id || properties.device_type
})

const hasGyroData = computed(() => {
  const properties = props.pointData.properties
  return properties.gyro_x !== undefined ||
         properties.gyro_y !== undefined ||
         properties.gyro_z !== undefined
})

const additionalProperties = computed(() => {
  const properties = props.pointData.properties
  const knownProps = new Set([
    'topic', 'timestamp', 'gps_alt', 'height', 'attitude_head',
    'imu_yaw', 'imu_pitch', 'imu_roll', 'battery', 'temperature',
    'humidity', 'gps_accuracy', 'device_id', 'device_type',
    'gyro_x', 'gyro_y', 'gyro_z', 'feature_index', 'point_index', 'unique_id'
  ])

  const additional = {}
  Object.keys(properties).forEach(key => {
    if (!knownProps.has(key) && properties[key] !== undefined && properties[key] !== null) {
      additional[key] = properties[key]
    }
  })

  return additional
})

const hasAdditionalProperties = computed(() => {
  return Object.keys(additionalProperties.value).length > 0
})

const formatCoordinate = (coord, type) => {
  const abs = Math.abs(coord)
  const degrees = Math.floor(abs)
  const minutes = (abs - degrees) * 60
  const direction = type === 'lat' ? (coord >= 0 ? 'N' : 'S') : (coord >= 0 ? 'E' : 'W')
  return `${degrees}°${minutes.toFixed(4)}'${direction}`
}

const formatTimestamp = (timestamp) => {
  try {
    const date = new Date(timestamp)
    return date.toLocaleString()
  } catch (e) {
    return timestamp
  }
}

const formatPropertyName = (key) => {
  return key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
}

const formatPropertyValue = (value) => {
  if (typeof value === 'number') {
    return Number.isInteger(value) ? value.toString() : value.toFixed(2)
  }
  return String(value)
}

const handleEscape = (e) => {
  if (e.key === 'Escape') {
    emit('close')
  }
}

onMounted(() => {
  document.addEventListener('keydown', handleEscape)
})

onBeforeUnmount(() => {
  document.removeEventListener('keydown', handleEscape)
})
</script>

<style scoped>
.modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 2rem;
}

.modal-content {
  background: white;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
  max-width: 800px;
  width: 100%;
  max-height: 85vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #eee;
  background: #f8f9fa;
  border-radius: 8px 8px 0 0;
}

.modal-header h3 {
  margin: 0;
  color: #2c3e50;
}

.close-button {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: background-color 0.2s;
}

.close-button:hover {
  background-color: #e9ecef;
}

.modal-body {
  padding: 1.5rem;
}

.info-section {
  margin-bottom: 2rem;
}

.info-section:last-child {
  margin-bottom: 0;
}

.info-section h4 {
  margin: 0 0 1rem 0;
  color: #34495e;
  font-size: 1.1rem;
  border-bottom: 2px solid #3498db;
  padding-bottom: 0.5rem;
}

.info-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 0.75rem;
}

@media (min-width: 480px) {
  .info-grid {
    grid-template-columns: 1fr 1fr;
  }
}

@media (min-width: 768px) {
  .info-grid {
    grid-template-columns: 1fr 1fr 1fr;
  }
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.label {
  font-weight: 600;
  color: #555;
  font-size: 0.9rem;
}

.value {
  color: #2c3e50;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 0.9rem;
  background: #f8f9fa;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  border: 1px solid #dee2e6;
}
</style>
