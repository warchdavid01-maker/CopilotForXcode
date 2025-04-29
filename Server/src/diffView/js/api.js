// api.js - Public API for external use
import { initDiffEditor, updateDiffContent } from './monaco-diff-editor.js';
import { updateFileMetadata } from './ui-controller.js';

/**
 * The public API that will be exposed to the global scope
 */
const DiffViewer = {
    /**
     * Initialize the diff editor with content
     * @param {string} originalContent - Content for the original side
     * @param {string} modifiedContent - Content for the modified side
     * @param {string} path - File path
     * @param {string} status - File edit status
     * @param {Object} options - Optional configuration for the diff editor
     */
    init: function(originalContent, modifiedContent, path, status, options) {
        // Initialize editor
        initDiffEditor(originalContent, modifiedContent, options);
        
        // Update file metadata and UI
        updateFileMetadata(path, status);
    },
    
    /**
     * Update the diff editor with new content
     * @param {string} originalContent - Content for the original side
     * @param {string} modifiedContent - Content for the modified side
     * @param {string} path - File path
     * @param {string} status - File edit status
     */
    update: function(originalContent, modifiedContent, path, status) {
        // Update editor content
        updateDiffContent(originalContent, modifiedContent);
        
        // Update file metadata and UI
        updateFileMetadata(path, status);
    },
    
    /**
     * Handle resize events
     */
    handleResize: function() {
        const editor = getEditor();
        if (editor) {
            editor.layout();
        }
    }
};

export default DiffViewer;
