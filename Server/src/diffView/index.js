// main.js - Main entry point for the Monaco Editor diff view
import * as monaco from 'monaco-editor/esm/vs/editor/editor.api.js';
import { initDiffEditor } from './js/monaco-diff-editor.js';
import { setupUI } from './js/ui-controller.js';
import DiffViewer from './js/api.js';

// Initialize everything when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Hide loading indicator as Monaco is directly imported
    const loadingElement = document.getElementById('loading');
    if (loadingElement) {
        loadingElement.style.display = 'none';
    }

    // Set up UI elements and event handlers
    setupUI();
});

// Expose the MonacoDiffViewer API to the global scope
window.DiffViewer = DiffViewer;

// Export the MonacoDiffViewer for webpack
export default DiffViewer;
