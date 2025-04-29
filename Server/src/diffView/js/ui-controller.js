// ui-controller.js - UI event handlers and state management
/**
 * UI state and file metadata
 */
let filePath = null;
let fileEditStatus = null;

/**
 * Initialize and set up UI elements and their event handlers
 * @param {string} initialPath - The initial file path
 * @param {string} initialStatus - The initial file edit status
 */
function setupUI(initialPath = null, initialStatus = null) {
    filePath = initialPath;
    fileEditStatus = initialStatus;
    
    const keepButton = document.getElementById('keep-button');
    const undoButton = document.getElementById('undo-button');
    const choiceButtons = document.getElementById('choice-buttons');

    if (!keepButton || !undoButton || !choiceButtons) {
        console.error("Could not find UI elements");
        return;
    }

    // Set initial UI state
    updateUIStatus(initialStatus);

    // Setup event listeners
    keepButton.addEventListener('click', handleKeepButtonClick);
    undoButton.addEventListener('click', handleUndoButtonClick);
}

/**
 * Update the UI based on file edit status
 * @param {string} status - The current file edit status
 */
function updateUIStatus(status) {
    fileEditStatus = status;
    const choiceButtons = document.getElementById('choice-buttons');
    
    if (!choiceButtons) return;
    
    // Hide buttons if file has been modified
    if (status && status !== "none") {
        choiceButtons.classList.add('hidden');
    } else {
        choiceButtons.classList.remove('hidden');
    }
}

/**
 * Update the file metadata
 * @param {string} path - The file path
 * @param {string} status - The file edit status
 */
function updateFileMetadata(path, status) {
    filePath = path;
    updateUIStatus(status);
}

/**
 * Handle the "Keep" button click
 */
function handleKeepButtonClick() {
    // Send message to Swift handler
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.swiftHandler) {
        window.webkit.messageHandlers.swiftHandler.postMessage({
            event: 'keepButtonClicked',
            data: {
                filePath: filePath
            }
        });
    } else {
        console.log('Keep button clicked, but no message handler found');
    }
    
    // Hide the choice buttons
    const choiceButtons = document.getElementById('choice-buttons');
    if (choiceButtons) {
        choiceButtons.classList.add('hidden');
    }
}

/**
 * Handle the "Undo" button click
 */
function handleUndoButtonClick() {
    // Send message to Swift handler
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.swiftHandler) {
        window.webkit.messageHandlers.swiftHandler.postMessage({
            event: 'undoButtonClicked',
            data: {
                filePath: filePath
            }
        });
    } else {
        console.log('Undo button clicked, but no message handler found');
    }
    
    // Hide the choice buttons
    const choiceButtons = document.getElementById('choice-buttons');
    if (choiceButtons) {
        choiceButtons.classList.add('hidden');
    }
}

/**
 * Get the current file path
 * @returns {string} The current file path
 */
function getFilePath() {
    return filePath;
}

/**
 * Get the current file edit status
 * @returns {string} The current file edit status
 */
function getFileEditStatus() {
    return fileEditStatus;
}

export {
    setupUI,
    updateUIStatus,
    updateFileMetadata,
    getFilePath,
    getFileEditStatus
};