import '@xterm/xterm/css/xterm.css';
import { Terminal } from '@xterm/xterm';
import { FitAddon } from '@xterm/addon-fit';

window.initializeTerminal = function() {
    const term = new Terminal({
        cursorBlink: true,
        theme: {
            background: '#1e1e1e',
            foreground: '#cccccc',
            cursor: '#ffffff',
            selection: 'rgba(128, 128, 128, 0.4)'
        },
        fontFamily: 'Menlo, Monaco, "Courier New", monospace',
        fontSize: 13
    });
    
    const fitAddon = new FitAddon();
    term.loadAddon(fitAddon);
    term.open(document.getElementById('terminal'));
    fitAddon.fit();
    
    term.onData(data => {
        window.webkit.messageHandlers.terminalInput.postMessage(data);
    });
    
    window.addEventListener('resize', () => {
        fitAddon.fit();
    });
    
    window.writeToTerminal = function(text) {
        term.write(text);
    };
    
    window.clearTerminal = function() {
        term.clear();
    };
    
    return term;
}
