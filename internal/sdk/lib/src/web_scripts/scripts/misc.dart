const String SUPPORT_RN_CUSTOM_INJECTIONS = """
  window["ReactNativeWebView"] = {
    postMessage: (str) => window.flutter_inappwebview.callHandler('extractedData', str)
  };
""";

const String PAGE_CONTENT_CAPTURE_ON_LOAD = """
  (function() {
    function getFrameContent(frame) {
      try {
        if (!frame.contentDocument) return '';
        let content = frame.contentDocument.documentElement.outerHTML;
        // Recursively get content from nested frames
        const frames = frame.contentDocument.getElementsByTagName('frame');
        const iframes = frame.contentDocument.getElementsByTagName('iframe');
        for (const f of [...frames, ...iframes]) {
          content += getFrameContent(f);
        }
        return content;
      } catch (e) {
        return ''; // Return empty string if we can't access frame content (cross-origin)
      }
    }

    function getCompletePageContent() {
      let content = document.documentElement.outerHTML;
      // Get content from all frames and iframes
      const frames = document.getElementsByTagName('frame');
      const iframes = document.getElementsByTagName('iframe');
      for (const frame of [...frames, ...iframes]) {
        content += getFrameContent(frame);
      }
      return content;
    }

    let lastUrl = window.location.href;
    let lastHtml = getCompletePageContent();
    let isProcessing = false;
    let debounceTimer = null;
    let significantChanges = false;
    
    // Track DOM mutations that might indicate significant changes
    const mutationObserver = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        // Check if the mutation is significant (e.g., not just attribute changes)
        if (mutation.type === 'childList' || 
            (mutation.type === 'attributes' && 
             ['class', 'style', 'src', 'href'].includes(mutation.attributeName))) {
          significantChanges = true;
          break;
        }
      }
    });

    // Start observing the entire document for significant changes
    mutationObserver.observe(document.documentElement, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class', 'style', 'src', 'href']
    });
    
    function hasSignificantChanges() {
      if (!significantChanges) return false;
      
      // Only do full HTML comparison if we detected significant changes
      const currentHtml = getCompletePageContent();
      const hasChanged = currentHtml !== lastHtml;
      if (hasChanged) {
        lastHtml = currentHtml;
      }
      significantChanges = false;
      return hasChanged;
    }

    function getFormData() {
      function findElementsInShadowDOM(selector, root = document) {
        const elements = [];
        
        // Search in current document/shadow root
        elements.push(...root.querySelectorAll(selector));
        
        // Search in all shadow roots
        root.querySelectorAll('*').forEach(el => {
          if (el.shadowRoot) {
            elements.push(...findElementsInShadowDOM(selector, el.shadowRoot));
          }
        });
        
        return elements;
      }
      
      const data = {};
      const inputs = findElementsInShadowDOM('input');
      inputs.forEach(input => {
        // Skip password fields for security
        if (input.type === 'password') return;
        
        const key = input.name || input.id || input.getAttribute('formcontrolname') || '';
        if (key) data[key] = input.value;
      });

      const textareas = findElementsInShadowDOM('textarea');
      textareas.forEach(textarea => {
        const key = textarea.name || textarea.id || textarea.getAttribute('formcontrolname') || '';
        if (key) data[key] = textarea.value;
      });
      
      const selects = findElementsInShadowDOM('select');
      selects.forEach(select => {
        const key = select.name || select.id || select.getAttribute('formcontrolname') || '';
        if (key) data[key] = select.value;
      });

      return JSON.stringify(data);
    }
    
    function handlePageChange() {
      if (isProcessing) return;
      
      // Clear any existing debounce timer
      if (debounceTimer) {
        clearTimeout(debounceTimer);
      }
      
      isProcessing = true;
      
      // Debounce the check to avoid too frequent comparisons
      debounceTimer = setTimeout(() => {
        if (hasSignificantChanges()) {
          window.ReclaimMessenger.send('pageLoadComplete', {
            url: window.location.href,
            dom: getCompletePageContent(),
            formData: getFormData()
          });
        }
        isProcessing = false;
      }, 7000);
    }
    
    // Monitor location changes
    const urlObserver = new MutationObserver(() => {
      if (window.location.href !== lastUrl) {
        lastUrl = window.location.href;
        significantChanges = true; // Force check on URL change
        handlePageChange();
      }
    });
    
    // Start observing
    urlObserver.observe(document, {
      subtree: true,
      childList: true
    });
    
    // Monitor clicks with debouncing
    document.addEventListener('click', function(e) {
      handlePageChange();
    });
    
    // Listen for load event
    window.addEventListener('load', function() {
      significantChanges = true; // Force check on page load
      handlePageChange();
    });
    
    // Initial check
    handlePageChange();
  })();
""";
