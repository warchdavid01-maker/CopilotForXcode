// monaco-diff-editor.js - Monaco Editor diff view core functionality
import * as monaco from 'monaco-editor/esm/vs/editor/editor.api.js';

// Editor state
let diffEditor = null;
let originalModel = null;
let modifiedModel = null;
let resizeObserver = null;

/**
 * Initialize the Monaco diff editor
 * @param {string} originalContent - Content for the original side
 * @param {string} modifiedContent - Content for the modified side
 * @param {Object} options - Optional configuration for the diff editor
 * @returns {Object} The diff editor instance
 */
function initDiffEditor(originalContent, modifiedContent, options = {}) {
    try {
        // Default options
        const editorOptions = {
            renderSideBySide: false,
            readOnly: true,
            // Enable automatic layout adjustments
            automaticLayout: true,
            ...options
        };

        // Create the diff editor if it doesn't exist yet
        if (!diffEditor) {
            diffEditor = monaco.editor.createDiffEditor(
                document.getElementById("container"),
                editorOptions
            );
            
            // Add resize handling
            setupResizeHandling();
        } else {
            // Apply any new options
            diffEditor.updateOptions(editorOptions);
        }

        // Create and set models
        updateModels(originalContent, modifiedContent);
        
        return diffEditor;
    } catch (error) {
        console.error("Error initializing diff editor:", error);
        return null;
    }
}

/**
 * Setup proper resize handling for the editor
 */
function setupResizeHandling() {
    window.addEventListener('resize', () => {
        if (diffEditor) {
            diffEditor.layout();
        }
    });
    
    if (window.ResizeObserver && !resizeObserver) {
        const container = document.getElementById('container');
        resizeObserver = new ResizeObserver(() => {
            if (diffEditor) {
                diffEditor.layout()
            }
        });
        
        if (container) {
            resizeObserver.observe(container);
        }
    }
}

/**
 * Create or update the models for the diff editor
 * @param {string} originalContent - Content for the original side
 * @param {string} modifiedContent - Content for the modified side
 */
function updateModels(originalContent, modifiedContent) {
    try {
        // Clean up existing models if they exist
        if (originalModel) {
            originalModel.dispose();
        }
        if (modifiedModel) {
            modifiedModel.dispose();
        }

        // Create new models with the content
        originalModel = monaco.editor.createModel(originalContent || "", "plaintext");
        modifiedModel = monaco.editor.createModel(modifiedContent || "", "plaintext");
        
        // Set the models to show the diff
        if (diffEditor) {
            diffEditor.setModel({
                original: originalModel,
                modified: modifiedModel,
            });
        }
    } catch (error) {
        console.error("Error updating models:", error);
    }
}

/**
 * Update the diff view with new content
 * @param {string} originalContent - Content for the original side
 * @param {string} modifiedContent - Content for the modified side
 */
function updateDiffContent(originalContent, modifiedContent) {
    // If editor exists, update it
    if (diffEditor && diffEditor.getModel()) {
        const model = diffEditor.getModel();
        
        // Update model values
        model.original.setValue(originalContent || "");
        model.modified.setValue(modifiedContent || "");
    } else {
        // Initialize if not already done
        initDiffEditor(originalContent, modifiedContent);
    }
}

/**
 * Get the current diff editor instance
 * @returns {Object|null} The diff editor instance or null
 */
function getEditor() {
    return diffEditor;
}

/**
 * Dispose of the editor and models to clean up resources
 */
function dispose() {
    if (resizeObserver) {
        resizeObserver.disconnect();
        resizeObserver = null;
    }
    
    if (originalModel) {
        originalModel.dispose();
        originalModel = null;
    }
    if (modifiedModel) {
        modifiedModel.dispose();
        modifiedModel = null;
    }
    if (diffEditor) {
        diffEditor.dispose();
        diffEditor = null;
    }
}

export {
    initDiffEditor,
    updateDiffContent,
    getEditor,
    dispose
};
