const HAWKEYE_SCRIPT = r'''
// ==UserScript==
// @name         Reclaim Interceptor
// @namespace    http://tampermonkey.net/
// @version      2025-07-11
// @description  Intercepts requests and response
// @author       Abdul Rashid Reshamwala
// @match        *://*/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=reclaimprotocol.org
// @grant        none
// ==/UserScript==

(function () {
  "use strict";

  /**
   * Debug utility for consistent logging across the interceptor
   * @type {Object}
   */
  const debug = {
    log: (...args) => console.log("🔍 [Debug]:", ...args),
    error: (...args) => console.error("❌ [Error]:", ...args),
    info: (...args) => console.info("ℹ️ [Info]:", ...args),
  };

  /**
   * Symbol to mark patched modules
   */
  const IS_PATCHED_MODULE = Symbol("rc-patched");

  /**
   * RequestInterceptor class
   * Provides middleware-based interception for both Fetch and XMLHttpRequest
   * Allows monitoring and modification of HTTP requests and responses
   */
  class RequestInterceptor {
    /**
     * Initialize the interceptor with empty middleware arrays and store original methods
     */
    constructor(options = {}) {
      this.requestMiddlewares = new Map();
      this.responseMiddlewares = new Map();
      this.subscriptions = []; // Store cleanup functions

      // Debug options
      this.options = {
        disableFetch: options.disableFetch || false,
        disableXHR: options.disableXHR || false,
        useProxyForFetch: options.useProxyForFetch !== false, // Default to true for backward compatibility
        useGetterForFetch: options.useGetterForFetch || false, // Use getter/setter for maximum robustness
        ...options,
      };

      // Store original methods before overriding
      this.originalFetch = window.fetch?.bind(window);
      this.originalXHR = window.XMLHttpRequest;

      // Verify browser environment and required APIs
      if (
        typeof window === "undefined" ||
        !this.originalFetch ||
        !this.originalXHR
      ) {
        debug.error(
          "Not in a browser environment or required APIs not available"
        );
        return;
      }

      this.setupInterceptor();
      debug.info("RequestInterceptor initialized", this.options);
    }

    /**
     * Process response middlewares without blocking the main thread
     * @param {Response} response - The response object
     * @param {Object} requestData - The original request data
     */
    async processResponseMiddlewares(response, requestData) {
      const parsedResponse = await this.parseResponse(response);

      for (const middleware of this.responseMiddlewares.values()) {
        try {
          await middleware(parsedResponse, requestData);
        } catch (error) {
          debug.error("Error in response middleware:", error);
        }
      }
    }

    /**
     * Parse response data into a consistent format
     * @param {Response} response - The response object to parse (should already be cloned)
     * @returns {Object} - Parsed response with standardized format
     */
    async parseResponse(response) {
      let responseBody;
      let contentType = response.headers.get("content-type") || "";

      try {
        // Check if the response body is already consumed
        if (response.bodyUsed) {
          responseBody = "[Response body already consumed]";
        } else {
          // Try to parse based on content type using the provided response directly
          if (contentType.includes("text/") || contentType.includes("application/json")) {
            try {
              responseBody = await response.text();
            } catch (textError) {
              // If response body parsing fails, the body is consumed, we can't read it again
              responseBody = "[Invalid response format]";
            }
          } else {
            // For binary data, get as text but mark it as binary
            const text = await response.text();
            responseBody = text === "" ? "[Binary Data]" : text;
          }
        }
      } catch (error) {
        debug.error("Error parsing response:", error);
        responseBody = `[Error reading response: ${error.message}]`;
      }

      return {
        id: response.id || null,
        url: response.url,
        status: response.status,
        statusText: response.statusText,
        headers: Object.fromEntries(response.headers.entries()),
        body: responseBody,
        isMockedResponse: false, // Always false for real responses
        originalResponse: response,
        timestamp: Date.now(),
      };
    }

    /**
     * Check if a URL can be parsed as an absolute URL
     * @param {string} url - The URL to check
     * @returns {boolean} - True if the URL can be parsed
     */
    canParseUrl(url) {
      try {
        new URL(url);
        return true;
      } catch {
        return false;
      }
    }

    /**
     * Set up interception for both Fetch and XMLHttpRequest
     * This method overrides the global fetch and XMLHttpRequest objects
     */
    setupInterceptor() {
      // Setup Fetch interceptor (only if not disabled)
      if (!this.options.disableFetch) {
        const originalFetch = this.originalFetch;
        const self = this;

        // Priority order: useGetterForFetch > useProxyForFetch > direct replacement
        if (this.options.useGetterForFetch) {
          // Method 3: Getter/Setter approach (most robust)
          // Store the current fetch function (could be overridden later)
          let currentFetch = originalFetch;

          const createInterceptedFetch = (baseFetch) => {
            return async function (input, init) {
              // Create a unique request ID for tracking
              const requestId = `req_${Date.now()}_${Math.random()
                .toString(36)
                .substr(2, 9)}`;

              // Resolve potentially relative request URL (similar to MSW)
              const resolvedInput =
                typeof input === "string" &&
                typeof location !== "undefined" &&
                !self.canParseUrl(input)
                  ? new URL(input, location.href)
                  : input;

              // Create a proper Request object
              const request = new Request(resolvedInput, init);

              // Create request data for middleware
              const requestData = {
                id: requestId,
                url: request.url,
                method: request.method,
                headers: Object.fromEntries(request.headers.entries()),
                body: null, // Will be set if needed
                request: request, // Include the actual Request object
                timestamp: Date.now(),
              };

              debug.info(`[${requestId}] ${request.method} ${request.url}`);

              try {
                // Process request middlewares
                await Promise.all(
                  Array.from(self.requestMiddlewares.values()).map(
                    (middleware) => middleware(requestData)
                  )
                );
              } catch (error) {
                debug.error("Error in request middleware:", error);
              }

              // Clone the request for response event (preserves body readability)
              const requestClone = request.clone();

              try {
                // Make the actual fetch call
                const response = await baseFetch.call(this, request);

                debug.info(`[${requestId}] Response received:`, {
                  status: response.status,
                  statusText: response.statusText,
                  url: response.url,
                });

                // Process response middlewares without blocking
                if (self.responseMiddlewares.size > 0) {
                  // Clone response for middleware (preserves body readability)
                  const responseClone = response.clone();

                  self
                    .processResponseMiddlewares(responseClone, {
                      ...requestData,
                      request: requestClone,
                    })
                    .catch((error) => {
                      debug.error("Error in response middleware:", error);
                    });
                }

                return response;
              } catch (error) {
                debug.error(`[${requestId}] Request failed:`, error);
                throw error;
              }
            };
          };

          // Check if fetch is already patched
          if (originalFetch && originalFetch[IS_PATCHED_MODULE]) {
            debug.error("Failed to patch fetch: already patched.");
            return;
          }

          // Use getter/setter to ensure ALL access to fetch is intercepted
          // This allows overriding while maintaining our interceptor at the root
          Object.defineProperty(window, "fetch", {
            get: function () {
              return createInterceptedFetch(currentFetch);
            },
            set: function (newFetch) {
              // Allow overriding but wrap the new function with our interceptor
              if (typeof newFetch === "function") {
                currentFetch = newFetch;
                debug.info(
                  "Fetch function was overridden, but interceptor maintained"
                );
              } else {
                debug.info("Invalid fetch function provided, ignoring");
              }
            },
            configurable: true,
            enumerable: true,
          });

          // Mark as patched
          Object.defineProperty(window.fetch, IS_PATCHED_MODULE, {
            enumerable: true,
            configurable: true,
            value: true,
          });

          // Also add to global scope and prototype chain
          if (typeof globalThis !== "undefined") {
            Object.defineProperty(globalThis, "fetch", {
              get: function () {
                return createInterceptedFetch(currentFetch);
              },
              set: function (newFetch) {
                if (typeof newFetch === "function") {
                  currentFetch = newFetch;
                  debug.info(
                    "Fetch function was overridden on globalThis, but interceptor maintained"
                  );
                } else {
                  debug.info(
                    "Invalid fetch function provided to globalThis, ignoring"
                  );
                }
              },
              configurable: true,
              enumerable: true,
            });
          }

          if (window.Window && window.Window.prototype) {
            Object.defineProperty(window.Window.prototype, "fetch", {
              get: function () {
                return createInterceptedFetch(currentFetch);
              },
              set: function (newFetch) {
                if (typeof newFetch === "function") {
                  currentFetch = newFetch;
                  debug.info(
                    "Fetch function was overridden on prototype, but interceptor maintained"
                  );
                } else {
                  debug.info(
                    "Invalid fetch function provided to prototype, ignoring"
                  );
                }
              },
              configurable: true,
              enumerable: false,
            });
          }

          // Store cleanup function
          this.subscriptions.push(() => {
            // Remove patched marker
            Object.defineProperty(window.fetch, IS_PATCHED_MODULE, {
              value: undefined,
            });

            // Restore original fetch
            if (typeof globalThis !== "undefined") {
              globalThis.fetch = originalFetch;
            }
            window.fetch = originalFetch;

            if (window.Window && window.Window.prototype) {
              delete window.Window.prototype.fetch;
            }

            debug.info("Restored native fetch!", originalFetch.name);
          });

          debug.info(
            "Fetch interceptor enabled (using getter/setter with override support)"
          );
        } else if (this.options.useProxyForFetch) {
          // Method 1: Using Proxy (original method)
          window.fetch = new Proxy(originalFetch, {
            apply: async function (target, thisArg, argumentsList) {
              const [url, options = {}] = argumentsList;

              if (!url) {
                return Reflect.apply(target, thisArg, argumentsList);
              }

              const requestData = {
                url,
                options: {
                  ...options,
                  method: options.method || "GET",
                  headers: options.headers || {},
                },
              };

              try {
                // Process request middlewares
                await Promise.all(
                  Array.from(self.requestMiddlewares.values()).map(
                    (middleware) => middleware(requestData)
                  )
                );
              } catch (error) {
                debug.error("Error in request middleware:", error);
              }

              // Make the actual fetch call with potentially modified data
              const response = await Reflect.apply(target, thisArg, [
                requestData.url,
                requestData.options,
              ]);

              // Process response middlewares without blocking
              self
                .processResponseMiddlewares(response.clone(), requestData)
                .catch((error) => {
                  debug.error("Error in response middleware:", error);
                });

              return response; // Return the original response object
            },
          });
          debug.info("Fetch interceptor enabled (using Proxy)");
        } else {
          // Method 2: Direct replacement with property descriptor (alternative method)
          const interceptedFetch = async function (input, init) {
            const requestId = `req_${Date.now()}_${Math.random()
              .toString(36)
              .substr(2, 9)}`;

            const resolvedInput =
              typeof input === "string" &&
              typeof location !== "undefined" &&
              !self.canParseUrl(input)
                ? new URL(input, location.href)
                : input;

            const request = new Request(resolvedInput, init);
            const requestData = {
              id: requestId,
              url: request.url,
              method: request.method,
              headers: Object.fromEntries(request.headers.entries()),
              request: request,
              timestamp: Date.now(),
            };

            debug.info(`[${requestId}] ${request.method} ${request.url}`);

            try {
              await Promise.all(
                Array.from(self.requestMiddlewares.values()).map((middleware) =>
                  middleware(requestData)
                )
              );
            } catch (error) {
              debug.error("Error in request middleware:", error);
            }

            const requestClone = request.clone();

            try {
              const response = await originalFetch.call(this, request);

              debug.info(`[${requestId}] Response received:`, {
                status: response.status,
                statusText: response.statusText,
                url: response.url,
              });

              if (self.responseMiddlewares.size > 0) {
                const responseClone = response.clone();
                self
                  .processResponseMiddlewares(responseClone, {
                    ...requestData,
                    request: requestClone,
                  })
                  .catch((error) => {
                    debug.error("Error in response middleware:", error);
                  });
              }

              return response;
            } catch (error) {
              debug.error(`[${requestId}] Request failed:`, error);
              throw error;
            }
          };

          Object.defineProperty(window, "fetch", {
            value: interceptedFetch,
            writable: true,
            configurable: true,
            enumerable: true,
          });

          if (window.Window && window.Window.prototype) {
            Object.defineProperty(window.Window.prototype, "fetch", {
              value: interceptedFetch,
              writable: true,
              configurable: true,
              enumerable: false,
            });
          }

          debug.info(
            "Fetch interceptor enabled (using property descriptor replacement)"
          );
        }
      } else {
        debug.info("Fetch interceptor disabled");
      }

      // Setup XHR interceptor by modifying the prototype (only if not disabled)
      if (!this.options.disableXHR) {
        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;
        const originalSetRequestHeader =
          XMLHttpRequest.prototype.setRequestHeader;
        const self = this; // Add self reference for XHR interceptor

        // Create a WeakMap to store request info for each XHR instance
        const requestInfoMap = new WeakMap();

        // Modify open method on prototype
        XMLHttpRequest.prototype.open = function (...args) {
          const [method = "GET", url = ""] = args;
          const requestId = `xhr_${Date.now()}_${Math.random()
            .toString(36)
            .substr(2, 9)}`;

          const requestInfo = {
            id: requestId,
            url,
            method,
            headers: {},
            body: null,
            timestamp: Date.now(),
          };

          // Store request info in WeakMap
          requestInfoMap.set(this, requestInfo);

          // Call original method
          return originalOpen.apply(this, args);
        };

        // Modify setRequestHeader method on prototype
        XMLHttpRequest.prototype.setRequestHeader = function (header, value) {
          const requestInfo = requestInfoMap.get(this);
          if (requestInfo && header && value) {
            requestInfo.headers[header] = value;
          }
          return originalSetRequestHeader.apply(this, arguments);
        };

        // Modify send method on prototype
        XMLHttpRequest.prototype.send = function (data) {
          const requestInfo = requestInfoMap.get(this);
          if (requestInfo) {
            requestInfo.body = data;

            debug.info(
              `[${requestInfo.id}] ${requestInfo.method} ${requestInfo.url}`
            );

            // Process request middlewares
            const runRequestMiddlewares = async () => {
              try {
                await Promise.all(
                  Array.from(self.requestMiddlewares.values()).map(
                    (middleware) => middleware(requestInfo)
                  )
                );
              } catch (error) {
                debug.error("Error in request middleware:", error);
              }
            };

            // Store original onreadystatechange
            const originalHandler = this.onreadystatechange;

            // Override onreadystatechange
            this.onreadystatechange = function (event) {
              if (typeof originalHandler === "function") {
                originalHandler.apply(this, arguments);
              }

              if (this.readyState === 4) {
                const status = this.status || 500;
                const statusText = this.statusText || "Request Failed";

                try {
                  const getResponseString = (response) => {
                    if (response === null || response === undefined) {
                      return "";
                    }

                    switch (typeof response) {
                      case "string":
                        return response;
                      case "object":
                        if (
                          response instanceof Blob ||
                          response instanceof ArrayBuffer
                        ) {
                          return "[Binary Data]";
                        }
                        if (response instanceof Document) {
                          return response.documentElement.outerHTML;
                        }
                        try {
                          return JSON.stringify(response);
                        } catch (e) {
                          return String(response);
                        }
                      default:
                        return String(response);
                    }
                  };

                  const responseObj = new Response(
                    getResponseString(this.response),
                    {
                      status: status,
                      statusText: statusText,
                      headers: new Headers(
                        Object.fromEntries(
                          (this.getAllResponseHeaders() || "")
                            .split("\r\n")
                            .filter(Boolean)
                            .map((line) => line.split(": "))
                        )
                      ),
                    }
                  );

                  Object.defineProperty(responseObj, "url", {
                    value: requestInfo.url,
                    writable: false,
                  });

                  debug.info(`[${requestInfo.id}] Response received:`, {
                    status: status,
                    statusText: statusText,
                    url: requestInfo.url,
                  });

                  self
                    .processResponseMiddlewares(responseObj, requestInfo)
                    .catch((error) =>
                      debug.error("Error in response middleware:", error)
                    );
                } catch (error) {
                  debug.error("Error processing XHR response:", error);
                }
              }
            };

            // Run middlewares then send
            runRequestMiddlewares().then(() => {
              originalSend.call(this, requestInfo.body);
            });
          } else {
            // Handle case where open wasn't called first
            originalSend.apply(this, arguments);
          }
        };

        // Store cleanup function
        this.subscriptions.push(() => {
          XMLHttpRequest.prototype.open = originalOpen;
          XMLHttpRequest.prototype.send = originalSend;
          XMLHttpRequest.prototype.setRequestHeader = originalSetRequestHeader;
          debug.info("Restored native XHR methods!");
        });

        debug.info("XHR interceptor enabled");
      } else {
        debug.info("XHR interceptor disabled");
      }
    }

    /**
     * Update debug options at runtime
     * @param {Object} options - New options to apply
     */
    updateOptions(options) {
      this.options = { ...this.options, ...options };
      debug.info("Options updated:", this.options);

      // Reapply interceptors with new options
      this.setupInterceptor();
    }

    /**
     * Add a middleware function to process requests before they are sent
     * @param {Function} middleware - Function to process request data
     * @param {string} id - Unique identifier for the middleware (optional)
     */
    addRequestMiddleware(middleware, id = null) {
      if (typeof middleware === "function") {
        const finalId =
          id || `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        this.requestMiddlewares.set(finalId, middleware);
        debug.info(`Request middleware added with ID: ${finalId}`);
      }
    }

    /**
     * Add a middleware function to process responses after they are received
     * @param {Function} middleware - Function to process response data
     * @param {string} id - Unique identifier for the middleware (optional)
     */
    addResponseMiddleware(middleware, id = null) {
      if (typeof middleware === "function") {
        const finalId =
          id || `resp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        this.responseMiddlewares.set(finalId, middleware);
        debug.info(`Response middleware added with ID: ${finalId}`);
      }
    }

    /**
     * Remove a request middleware by ID
     * @param {string} id - The ID of the middleware to remove
     */
    removeRequestMiddleware(id) {
      const removed = this.requestMiddlewares.delete(id);
      if (removed) {
        debug.info(`Request middleware removed: ${id}`);
      } else {
        debug.error(`Request middleware not found: ${id}`);
      }
      return removed;
    }

    /**
     * Remove a response middleware by ID
     * @param {string} id - The ID of the middleware to remove
     */
    removeResponseMiddleware(id) {
      const removed = this.responseMiddlewares.delete(id);
      if (removed) {
        debug.info(`Response middleware removed: ${id}`);
      } else {
        debug.error(`Response middleware not found: ${id}`);
      }
      return removed;
    }

    /**
     * Get all middleware IDs
     * @returns {Object} Object containing arrays of request and response middleware IDs
     */
    getMiddlewareIds() {
      return {
        request: Array.from(this.requestMiddlewares.keys()),
        response: Array.from(this.responseMiddlewares.keys()),
      };
    }

    /**
     * Clean up and restore original fetch/XHR functions
     */
    cleanup() {
      debug.info("Cleaning up interceptor...");

      this.subscriptions.forEach((cleanup) => {
        try {
          cleanup();
        } catch (error) {
          debug.error("Error during cleanup:", error);
        }
      });

      this.subscriptions = [];
      this.requestMiddlewares.clear();
      this.responseMiddlewares.clear();

      debug.info("Interceptor cleanup completed");
    }
  }

  // Create instance with debug options
  const interceptor = new RequestInterceptor({
    disableFetch: false, // Set to true to disable fetch interception
    disableXHR: false, // Set to true to disable XHR interception
    useProxyForFetch: \(useProxyForFetch), // Set to false to use direct replacement instead of Proxy (default: true)
    useGetterForFetch: \(useGetterForFetch), // Set to true to use getter/setter approach (most robust)
  });

  // Example middleware for logging requests with ID
  interceptor.addRequestMiddleware(async (requestData) => {
    debug.info(`[${requestData.id}] Request:`, {
      url: requestData.url,
      method: requestData.method,
      headers: requestData.headers,
    });
  }, "request_logger");

  // Example middleware for logging responses with ID
  interceptor.addResponseMiddleware(async (response, requestData) => {
    debug.info(`[${requestData.id}] Response:`, {
      url: requestData.url,
      status: response.status,
      body:
        typeof response.body === "string"
          ? response.body.substring(0, 100) + "..."
          : response.body,
    });
  }, "response_logger");

  /**
   * Expose the interceptor instance globally
   * This allows adding more middlewares from other scripts or the console
   *
   * Usage examples:
   *
   * // Create interceptor with options
   * const interceptor = new RequestInterceptor({
   *   disableFetch: false,        // Set to true to disable fetch interception
   *   disableXHR: false,         // Set to true to disable XHR interception
   *   useProxyForFetch: true,    // Set to false to use direct replacement instead of Proxy (default: true)
   *   useGetterForFetch: false,  // Set to true to use getter/setter approach (most robust)
   * });
   *
   * // Add a request middleware
   * window.reclaimInterceptor.addRequestMiddleware(async (request) => {
   *   console.log('New request:', request.url);
   * });
   *
   * // Add a response middleware
   * window.reclaimInterceptor.addResponseMiddleware(async (response, request) => {
   *   console.log('New response:', response.body);
   * });
   *
   * // Update options at runtime
   * window.reclaimInterceptor.updateOptions({
   *   useProxyForFetch: false,  // Switch to direct replacement method
   *   useGetterForFetch: true   // Or use getter/setter for maximum robustness
   * });
   *
   * // Clean up and restore original functions
   * window.reclaimInterceptor.cleanup();
   */
  window.reclaimInterceptor = interceptor;

  debug.info(
    "Userscript initialized and ready - Access via window.reclaimInterceptor"
  );
})();
''';
