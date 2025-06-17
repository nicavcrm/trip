# MQTT GeoPath Visualizer - Vue.js Frontend

This is a Vue.js application that visualizes geographical paths from MQTT message data stored in an SQLite database. The application uses Mapbox GL JS to display interactive maps with path visualization and detailed point information.

## Features

- Interactive map visualization of GPS tracking data
- Patterned line display for movement paths
- Clickable points with detailed information modals
- Statistics display showing path metrics and average frequencies
- Responsive design with modern UI

## Prerequisites

- Node.js (version 16 or higher)
- A Mapbox account and access token
- Generated `geo.json` file from the Rust backend

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Mapbox Token

1. Sign up for a free account at [Mapbox](https://account.mapbox.com/)
2. Get your access token from the [Mapbox dashboard](https://account.mapbox.com/access-tokens/)
3. Create a `.env` file in this directory:

```bash
# .env
VITE_MAPBOX_TOKEN=your_mapbox_access_token_here
```

**Important**: Replace `your_mapbox_access_token_here` with your actual Mapbox token.

### 3. Generate GeoJSON Data

Make sure you have run the Rust `geo` binary to generate the `geo.json` file:

```bash
# From the main project directory
cargo run --bin geo
```

This will create a `geo.json` file that should be copied to the `public/` directory of this Vue app.

### 4. Run the Development Server

```bash
npm run dev
```

The application will be available at `http://localhost:5173` (or another port if 5173 is busy).

## Building for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

## Troubleshooting

### Map not loading
- Check that your Mapbox token is correctly set in the `.env` file
- Ensure the token has the necessary permissions

### GeoJSON not loading
- Verify that `geo.json` exists in the `public/` directory
- Check that the Rust `geo` binary has been run successfully

## License

This project is part of the MQTT GeoPath Visualizer system.
