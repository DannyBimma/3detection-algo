# 3D Detection Algorithm - Web Demo

Interactive visualization of the 3D Component Intersection Detection and Joint Classification Algorithm.

## Features

- **Real-time 3D Visualization**: See the algorithm in action with animated component analysis
- **Interactive Controls**: Start/Stop, Reset, Speed control, and display toggles
- **Live Algorithm Log**: Step-by-step execution with timestamps
- **Joint Classification**: Visual representation of Finger, Hole, and Slot joints
- **Responsive Design**: Modern dark-themed interface

## Quick Start

### Option 1: Using npx (Recommended - No Installation)

```bash
npx serve .
```

Then open your browser to: `http://localhost:3000`

### Option 2: Using npm

```bash
# Install dependencies
npm install

# Start the demo
npm start
```

Then open your browser to: `http://localhost:3000`

### Option 3: Custom Port

```bash
npm run dev
```

This will start the server on port 8000: `http://localhost:8000`

### Option 4: Python HTTP Server

```bash
# Python 3
python3 -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

Then open your browser to: `http://localhost:8000`

## Controls

- **Start/Stop Button**: Begin or pause algorithm execution
- **Reset Button**: Return to initial state
- **Speed Slider**: Adjust animation speed (100ms - 2000ms per step)
- **Toggle Normal Vectors**: Show/hide component normal vectors
- **Toggle Grid**: Show/hide background grid
- **Auto-Rotate**: Enable automatic camera rotation

## Algorithm Details

The algorithm detects intersections between 3D planar components and classifies joints into three types:

1. **Finger Joints** (Green): Both intersection segments lie on component edges
2. **Hole Joints** (Orange): One segment is on an edge, the other is not
3. **Slot Joints** (Red): Neither segment lies on an edge

## Files

- `index.html` - Main demo page structure
- `demo.css` - Styling and layout
- `demo.js` - Visualization and UI logic
- `3d_detection_algo_browser.js` - Core algorithm implementation
- `package.json` - NPM configuration

## Browser Compatibility

Works best in modern browsers with ES6+ support:
- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

## License

GNU General Public License v3.0
