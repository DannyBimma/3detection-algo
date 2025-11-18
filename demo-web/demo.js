/**
 * 3D Component Intersection Detection Algorithm
 * Demo Visualization Script
 */

import { createDemoScene, JointType } from './3d_detection_algo_browser.js';

// DOM Elements
const canvas = document.getElementById('visualization-canvas');
const ctx = canvas.getContext('2d');
const startBtn = document.getElementById('start-btn');
const resetBtn = document.getElementById('reset-btn');
const speedSlider = document.getElementById('animation-speed');
const speedValue = document.getElementById('speed-value');
const showNormalsCheckbox = document.getElementById('show-normals');
const showGridCheckbox = document.getElementById('show-grid');
const autoRotateCheckbox = document.getElementById('auto-rotate');
const stepIndicator = document.getElementById('current-step');
const logContainer = document.getElementById('algorithm-log');
const resultsContainer = document.getElementById('results-container');

// State
let detector = null;
let isRunning = false;
let rotationAngle = 0;
let autoRotate = false;
let showNormals = true;
let showGrid = true;

// Colors
const COLORS = {
  grid: '#334155',
  axis: '#64748b',
  normal: '#fbbf24',
  component1: '#60a5fa',
  component2: '#34d399',
  component3: '#f472b6',
  finger: '#10b981',
  hole: '#f59e0b',
  slot: '#ef4444'
};

/**
 * Initialize the application
 */
function init() {
  setupEventListeners();
  drawInitialScene();
  animate();
}

/**
 * Setup event listeners
 */
function setupEventListeners() {
  startBtn.addEventListener('click', handleStart);
  resetBtn.addEventListener('click', handleReset);

  speedSlider.addEventListener('input', (e) => {
    speedValue.textContent = `${e.target.value}ms`;
  });

  showNormalsCheckbox.addEventListener('change', (e) => {
    showNormals = e.target.checked;
  });

  showGridCheckbox.addEventListener('change', (e) => {
    showGrid = e.target.checked;
  });

  autoRotateCheckbox.addEventListener('change', (e) => {
    autoRotate = e.target.checked;
  });
}

/**
 * Handle start button click
 */
async function handleStart() {
  if (isRunning) return;

  isRunning = true;
  startBtn.disabled = true;
  resetBtn.disabled = false;

  clearLog();
  addLogEntry('Starting algorithm...', 'info');

  // Create detector with animation settings
  const animationDelay = parseInt(speedSlider.value);
  detector = createDemoScene();
  detector.animationMode = true;
  detector.animationDelay = animationDelay;

  // Setup event listeners
  setupDetectorEvents(detector);

  try {
    await detector.detectIntersections();
    addLogEntry('Algorithm completed successfully!', 'success');
    displayResults(detector.getResults());
  } catch (error) {
    addLogEntry(`Error: ${error.message}`, 'error');
  } finally {
    isRunning = false;
    startBtn.disabled = false;
  }
}

/**
 * Handle reset button click
 */
function handleReset() {
  detector = null;
  isRunning = false;
  startBtn.disabled = false;
  resetBtn.disabled = true;
  rotationAngle = 0;

  clearLog();
  addLogEntry('System ready. Click "Start Detection" to begin.', 'info');

  stepIndicator.textContent = 'Ready to start';

  // Clear results
  resultsContainer.innerHTML = `
    <div class="empty-state">
      <svg class="empty-icon" width="64" height="64" viewBox="0 0 16 16" fill="currentColor">
        <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"/>
        <path d="M4.285 12.433a.5.5 0 0 0 .683-.183A3.498 3.498 0 0 1 8 10.5c1.295 0 2.426.703 3.032 1.75a.5.5 0 0 0 .866-.5A4.498 4.498 0 0 0 8 9.5a4.5 4.5 0 0 0-3.898 2.25.5.5 0 0 0 .183.683zM7 6.5C7 7.328 6.552 8 6 8s-1-.672-1-1.5S5.448 5 6 5s1 .672 1 1.5zm4 0c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S9.448 5 10 5s1 .672 1 1.5z"/>
      </svg>
      <p>No results yet</p>
      <p class="empty-hint">Run the algorithm to see intersection analysis</p>
    </div>
  `;

  drawInitialScene();
}

/**
 * Setup detector event listeners
 */
function setupDetectorEvents(detector) {
  detector.on('algorithm:start', (data) => {
    addLogEntry(`Processing ${data.componentCount} components (${data.totalSteps} comparisons)`, 'info');
  });

  detector.on('step:start', (data) => {
    stepIndicator.textContent = `Step ${data.step}/${data.totalSteps}: Comparing components ${data.component1} and ${data.component2}`;
    addLogEntry(`Comparing C${data.component1} ↔ C${data.component2}`, 'info');
  });

  detector.on('step:coplanar', (data) => {
    addLogEntry(`Coplanar components detected: C${data.component1} and C${data.component2}`, 'warning');
  });

  detector.on('intersection:found', (data) => {
    addLogEntry(`Intersection found between C${data.component1} and C${data.component2}`, 'success');
  });

  detector.on('joint:classified', (data) => {
    const type1 = data.component1.jointType;
    const type2 = data.component2.jointType;
    addLogEntry(
      `Joint classified: C${data.component1.id} → ${type1.toUpperCase()} | C${data.component2.id} → ${type2.toUpperCase()}`,
      'success'
    );
  });

  detector.on('algorithm:complete', (data) => {
    stepIndicator.textContent = 'Algorithm complete!';
  });
}

/**
 * Draw initial scene
 */
function drawInitialScene() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  if (showGrid) {
    drawGrid();
  }

  drawAxes();

  // Draw sample components
  drawComponent(
    { x: 200, y: 300 },
    { x: 600, y: 300 },
    COLORS.component1,
    'C1: XY Plane'
  );

  drawComponent(
    { x: 300, y: 150 },
    { x: 300, y: 450 },
    COLORS.component2,
    'C2: YZ Plane'
  );

  drawComponent(
    { x: 150, y: 250 },
    { x: 650, y: 350 },
    COLORS.component3,
    'C3: XZ Plane'
  );
}

/**
 * Draw grid
 */
function drawGrid() {
  ctx.strokeStyle = COLORS.grid;
  ctx.lineWidth = 0.5;

  const gridSize = 50;

  // Vertical lines
  for (let x = 0; x < canvas.width; x += gridSize) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, canvas.height);
    ctx.stroke();
  }

  // Horizontal lines
  for (let y = 0; y < canvas.height; y += gridSize) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(canvas.width, y);
    ctx.stroke();
  }
}

/**
 * Draw coordinate axes
 */
function drawAxes() {
  const centerX = canvas.width / 2;
  const centerY = canvas.height / 2;
  const axisLength = 100;

  ctx.lineWidth = 2;
  ctx.font = '14px monospace';

  // X axis (red)
  ctx.strokeStyle = '#ef4444';
  ctx.fillStyle = '#ef4444';
  ctx.beginPath();
  ctx.moveTo(centerX, centerY);
  ctx.lineTo(centerX + axisLength, centerY);
  ctx.stroke();
  ctx.fillText('X', centerX + axisLength + 10, centerY + 5);

  // Y axis (green)
  ctx.strokeStyle = '#10b981';
  ctx.fillStyle = '#10b981';
  ctx.beginPath();
  ctx.moveTo(centerX, centerY);
  ctx.lineTo(centerX, centerY - axisLength);
  ctx.stroke();
  ctx.fillText('Y', centerX + 5, centerY - axisLength - 10);

  // Z axis (blue) - simulated with diagonal
  ctx.strokeStyle = '#3b82f6';
  ctx.fillStyle = '#3b82f6';
  ctx.beginPath();
  ctx.moveTo(centerX, centerY);
  ctx.lineTo(centerX - axisLength * 0.7, centerY + axisLength * 0.7);
  ctx.stroke();
  ctx.fillText('Z', centerX - axisLength * 0.7 - 20, centerY + axisLength * 0.7 + 10);
}

/**
 * Draw a component (simplified as a line)
 */
function drawComponent(start, end, color, label) {
  ctx.strokeStyle = color;
  ctx.fillStyle = color;
  ctx.lineWidth = 4;

  // Draw the component as a thick line
  ctx.beginPath();
  ctx.moveTo(start.x, start.y);
  ctx.lineTo(end.x, end.y);
  ctx.stroke();

  // Draw endpoints
  ctx.beginPath();
  ctx.arc(start.x, start.y, 6, 0, Math.PI * 2);
  ctx.fill();

  ctx.beginPath();
  ctx.arc(end.x, end.y, 6, 0, Math.PI * 2);
  ctx.fill();

  // Draw label
  if (label) {
    const midX = (start.x + end.x) / 2;
    const midY = (start.y + end.y) / 2;

    ctx.font = 'bold 12px monospace';
    ctx.fillStyle = color;
    ctx.fillText(label, midX + 10, midY - 10);
  }

  // Draw normal vector if enabled
  if (showNormals) {
    const midX = (start.x + end.x) / 2;
    const midY = (start.y + end.y) / 2;
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const len = Math.sqrt(dx * dx + dy * dy);
    const normalX = -dy / len * 50;
    const normalY = dx / len * 50;

    ctx.strokeStyle = COLORS.normal;
    ctx.lineWidth = 2;
    ctx.setLineDash([5, 5]);
    ctx.beginPath();
    ctx.moveTo(midX, midY);
    ctx.lineTo(midX + normalX, midY + normalY);
    ctx.stroke();
    ctx.setLineDash([]);

    // Arrow head
    const arrowSize = 8;
    const angle = Math.atan2(normalY, normalX);
    ctx.fillStyle = COLORS.normal;
    ctx.beginPath();
    ctx.moveTo(midX + normalX, midY + normalY);
    ctx.lineTo(
      midX + normalX - arrowSize * Math.cos(angle - Math.PI / 6),
      midY + normalY - arrowSize * Math.sin(angle - Math.PI / 6)
    );
    ctx.lineTo(
      midX + normalX - arrowSize * Math.cos(angle + Math.PI / 6),
      midY + normalY - arrowSize * Math.sin(angle + Math.PI / 6)
    );
    ctx.closePath();
    ctx.fill();
  }
}

/**
 * Animation loop
 */
function animate() {
  if (autoRotate) {
    rotationAngle += 0.005;
    drawInitialScene();
  }

  requestAnimationFrame(animate);
}

/**
 * Add log entry
 */
function addLogEntry(message, type = 'info') {
  const entry = document.createElement('div');
  entry.className = `log-entry log-${type}`;

  const time = new Date().toLocaleTimeString('en-US', { hour12: false });

  entry.innerHTML = `
    <span class="log-time">${time}</span>
    <span class="log-message">${message}</span>
  `;

  logContainer.appendChild(entry);
  logContainer.scrollTop = logContainer.scrollHeight;
}

/**
 * Clear log
 */
function clearLog() {
  logContainer.innerHTML = '';
}

/**
 * Display results
 */
function displayResults(results) {
  resultsContainer.innerHTML = '';

  results.forEach(component => {
    const card = document.createElement('div');
    card.className = 'result-card';

    const totalJoints = component.fingerCount + component.holeCount + component.slotCount;

    card.innerHTML = `
      <div class="result-card-header">
        <h3 class="result-card-title">Component ${component.id}</h3>
        <div class="component-color" style="background-color: ${component.color}"></div>
      </div>
      <div class="result-stats">
        <div class="stat-row">
          <span class="stat-label">Finger Joints</span>
          <span class="stat-value joint-finger">${component.fingerCount}</span>
        </div>
        <div class="stat-row">
          <span class="stat-label">Hole Joints</span>
          <span class="stat-value joint-hole">${component.holeCount}</span>
        </div>
        <div class="stat-row">
          <span class="stat-label">Slot Joints</span>
          <span class="stat-value joint-slot">${component.slotCount}</span>
        </div>
        <div class="stat-row" style="border-top: 2px solid var(--border); margin-top: var(--spacing-sm); padding-top: var(--spacing-sm);">
          <span class="stat-label"><strong>Total Joints</strong></span>
          <span class="stat-value" style="color: var(--primary-color)">${totalJoints}</span>
        </div>
      </div>
    `;

    resultsContainer.appendChild(card);
  });
}

// Initialize on load
document.addEventListener('DOMContentLoaded', init);
