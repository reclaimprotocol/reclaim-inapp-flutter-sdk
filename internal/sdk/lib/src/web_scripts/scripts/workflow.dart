const String workflowScript = '''
// Simple Workflow Manager - Simplified automation for browser scripts
// Core principle: URL pattern -> Element checks -> Actions -> Built-in retries
// Singleton pattern ensures only one workflow runs per session

(function() {
    'use strict';

    // Check if workflow is already initialized
    if (window.ReclaimWorkFlow && window.ReclaimWorkFlow._initialized) {
        console.log('[ReclaimWorkFlow] Already initialized, skipping...');
        return;
    }

    const ReclaimWorkFlow = {
        _initialized: false,
        _instanceId: null,
        _sessionKey: 'simpleWorkflow_session',
        tasks: [],
        data: {},
        completedTasks: new Set(),
        config: {
            maxRetries: 3,
            retryDelay: 1000,
            waitTimeout: 5000,
            pollInterval: 500,
            debug: true,
            sessionId: null
        },

        // Initialize workflow configuration (does not start monitoring)
        init(options = {}) {
            // Prevent multiple initialization
            if (this._initialized) {
                this.log('Workflow already initialized');
                return this;
            }

            this.config = { ...this.config, ...options };

            // Generate or load session ID
            this.initSession();

            // Load persisted state
            this.loadState();

            // Mark as initialized
            this._initialized = true;
            this._instanceId = this.generateId();

            this.log('Initialized workflow instance:', this._instanceId);
            return this;
        },

        // Start monitoring for tasks (call after defining all tasks)
        start() {
            if (!this._initialized) {
                throw new Error('Workflow must be initialized before starting. Call init() first.');
            }

            this.startMonitoring();
            return this;
        },

        // Generate unique session ID
        initSession() {
            let sessionData = this.getSessionData();

            if (!sessionData.id) {
                sessionData = {
                    id: this.generateId(),
                    created: Date.now(),
                    completedTasks: []
                };
                this.saveSessionData(sessionData);
                this.log('Created new session:', sessionData.id);
            } else {
                this.log('Resuming session:', sessionData.id);
            }

            this.config.sessionId = sessionData.id;
            this.completedTasks = new Set(sessionData.completedTasks);
        },

        // Add a task (URL pattern + element checks + action)
        task(urlPattern, elementCheck, action) {
            const taskId = `task_\${this.tasks.length}_\${this.generateId().slice(0, 6)}`;
            this.tasks.push({
                id: taskId,
                urlPattern,
                elementCheck,
                action,
                completed: this.completedTasks.has(taskId),
                retryCount: 0
            });
            return this;
        },

        // Check if URL matches pattern
        matchesUrl(pattern) {
            const url = window.location.href;
            if (pattern instanceof RegExp) return pattern.test(url);
            if (typeof pattern === 'string') return url.includes(pattern);
            return false;
        },

        // Check if elements exist
        async checkElements(elements) {
            if (typeof elements === 'string') {
                return document.querySelector(elements) !== null;
            }
            if (Array.isArray(elements)) {
                return elements.every(sel => document.querySelector(sel) !== null);
            }
            if (typeof elements === 'function') {
                return elements();
            }
            return true;
        },

        // Wait for elements with retry
        async waitFor(selector, timeout = this.config.waitTimeout) {
            const start = Date.now();
            while (Date.now() - start < timeout) {
                const element = document.querySelector(selector);
                if (element) return element;
                await this.sleep(this.config.pollInterval);
            }
            throw new Error(`Element \${selector} not found within \${timeout}ms`);
        },

        // Core actions with built-in retry
        async click(selector) {
            return this.withRetry(async () => {
                const element = await this.waitFor(selector);
                if (!element) throw new Error(`Cannot click \${selector} - not found`);
                element.scrollIntoView({ behavior: 'smooth' });
                await this.sleep(200);
                element.click();
                this.log(`Clicked: \${selector}`);
            });
        },

        // Check if element is visible
        isVisible(selector) {
            try {
                const element = document.querySelector(selector);
                if (!element) return false;

                const rect = element.getBoundingClientRect();
                const style = window.getComputedStyle(element);

                return rect.width > 0 &&
                       rect.height > 0 &&
                       style.display !== 'none' &&
                       style.visibility !== 'hidden' &&
                       style.opacity !== '0';
            } catch (error) {
                return false;
            }
        },

        // Execute action with automatic retry
        async withRetry(action, maxRetries = this.config.maxRetries) {
            for (let i = 0; i <= maxRetries; i++) {
                try {
                    return await action();
                } catch (error) {
                    this.log(`Attempt \${i + 1} failed:`, error.message);
                    if (i === maxRetries) throw error;
                    await this.sleep(this.config.retryDelay * (i + 1));
                }
            }
        },

        // Simple context for actions
        createContext() {
            return {
                click: this.click.bind(this),
                waitFor: this.waitFor.bind(this),
                sleep: this.sleep.bind(this),
                isVisible: this.isVisible.bind(this),
                data: this.data,
                setData: (key, value) => {
                    this.data[key] = value;
                    this.saveData();
                },
                getData: (key) => this.data[key],
                log: (message, logType = 'debug') => {
                    const fullMessage = `[WorkflowTask] \${message}`;
                    if (window.ReclaimMessenger && window.ReclaimMessenger.log) {
                        window.ReclaimMessenger.log(logType, fullMessage);
                    } else {
                        if (logType === 'error') {
                            console.error(fullMessage);
                        } else {
                            console.log(fullMessage);
                        }
                    }
                },
                navigate: (url) => window.location.href = url
            };
        },

        // Check and execute tasks
        async checkTasks() {
            for (const task of this.tasks) {
                // Skip if already completed in this session
                if (task.completed || this.completedTasks.has(task.id)) {
                    continue;
                }

                try {
                    // Check URL pattern
                    if (!this.matchesUrl(task.urlPattern)) continue;

                    // Check elements
                    if (!(await this.checkElements(task.elementCheck))) continue;

                    this.log(`Executing task: \${task.id}`);

                    // Execute action with context
                    const ctx = this.createContext();
                    await task.action(ctx);

                    // Mark as completed and persist
                    task.completed = true;
                    task.retryCount = 0;
                    this.markTaskCompleted(task.id);

                    this.log(`Task completed: \${task.id}`);

                } catch (error) {
                    task.retryCount++;
                    this.log(`Task \${task.id} failed (attempt \${task.retryCount}):`, error.message);

                    if (task.retryCount >= this.config.maxRetries) {
                        this.log(`Task \${task.id} exceeded max retries`);
                        task.completed = true;
                        this.markTaskCompleted(task.id); // Mark as done to avoid infinite retries
                    }
                }
            }

            // Check if all tasks are complete
            if (this.tasks.every(task => task.completed)) {
                this.log('All tasks completed!');
                this.completeWorkflow();
            }
        },

        // Mark task as completed and persist
        markTaskCompleted(taskId) {
            this.completedTasks.add(taskId);
            const sessionData = this.getSessionData();
            sessionData.completedTasks = Array.from(this.completedTasks);
            sessionData.lastUpdate = Date.now();
            this.saveSessionData(sessionData);
        },

        // Complete the entire workflow
        completeWorkflow() {
            this.stopMonitoring();
            const sessionData = this.getSessionData();
            sessionData.completed = true;
            sessionData.completedAt = Date.now();
            this.saveSessionData(sessionData);
            this.log('Workflow completed! Session will not restart.');
        },

        // Monitor for task execution
        startMonitoring() {
            if (this.monitorInterval) return;

            // Check if workflow is already completed
            const sessionData = this.getSessionData();
            if (sessionData.completed) {
                this.log('Workflow already completed in this session. Skipping monitoring.');
                return;
            }

            this.log('Starting workflow monitoring...');

            // Initial check
            setTimeout(() => this.checkTasks(), 1000);

            // Periodic checks
            this.monitorInterval = setInterval(() => {
                this.checkTasks();
            }, this.config.pollInterval * 2);
        },

        stopMonitoring() {
            if (this.monitorInterval) {
                clearInterval(this.monitorInterval);
                this.monitorInterval = null;
                this.log('Workflow monitoring stopped');
            }
        },

        // Reset all tasks
        reset() {
            this.tasks.forEach(task => {
                task.completed = false;
                task.retryCount = 0;
            });
            this.data = {};
            this.saveData();
            this.log('Workflow reset');
        },

        // Get status
        getStatus() {
            const total = this.tasks.length;
            const completed = this.tasks.filter(t => t.completed).length;
            const failed = this.tasks.filter(t => t.retryCount >= this.config.maxRetries && !t.completed).length;

            return {
                total,
                completed,
                failed,
                progress: total > 0 ? Math.round((completed / total) * 100) : 0,
                isRunning: this.monitorInterval !== null,
                data: this.data
            };
        },

        // Utility functions
        async sleep(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        },

        log(...args) {
            if (this.config.debug) {
                const message = ['[ReclaimWorkFlow]', ...args].join(' ');
                if (window.ReclaimMessenger && window.ReclaimMessenger.log) {
                    window.ReclaimMessenger.log('debug', message);
                } else {
                    console.log('[ReclaimWorkFlow]', ...args);
                }
            }
        },

        // Session management functions
        getSessionData() {
            try {
                const saved = sessionStorage.getItem(this._sessionKey);
                return saved ? JSON.parse(saved) : {};
            } catch (e) {
                this.log('Failed to load session data:', e);
                return {};
            }
        },

        saveSessionData(data) {
            try {
                sessionStorage.setItem(this._sessionKey, JSON.stringify(data));
            } catch (e) {
                this.log('Failed to save session data:', e);
            }
        },

        // Load complete state
        loadState() {
            // Load workflow data
            try {
                const saved = sessionStorage.getItem('simpleWorkflowData');
                if (saved) {
                    this.data = JSON.parse(saved);
                }
            } catch (e) {
                this.log('Failed to load workflow data:', e);
                this.data = {};
            }
        },

        // Simple data persistence
        saveData() {
            try {
                sessionStorage.setItem('simpleWorkflowData', JSON.stringify(this.data));
            } catch (e) {
                this.log('Failed to save data:', e);
            }
        },

        // Generate unique ID
        generateId() {
            return Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
        },

        // Reset workflow session (for testing)
        resetSession() {
            sessionStorage.removeItem(this._sessionKey);
            sessionStorage.removeItem('simpleWorkflowData');
            this.completedTasks.clear();
            this.data = {};
            this._initialized = false;
            this.stopMonitoring();
            this.log('Session reset');
        }
    };

    // Export globally
    window.ReclaimWorkFlow = ReclaimWorkFlow;
    window.RWF = ReclaimWorkFlow; // Short alias

    // Auto-initialize on load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            // Auto-resume if there are tasks
            if (ReclaimWorkFlow.tasks.length > 0) {
                ReclaimWorkFlow.init();
            }
        });
    }

})();
''';
