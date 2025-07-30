const String SUPPORT_RN_CUSTOM_INJECTIONS = """
  window["ReactNativeWebView"] = {
    postMessage: (str) => window.flutter_inappwebview.callHandler('extractedData', str)
  };
""";

/// @param idleTimeThreshold The idle time in seconds before triggering manual verification.
String userInteractionInjection(int idleTimeThreshold) {
  int idleTimeThresholdInMillis = idleTimeThreshold * 1000;
  return """
  (function() {
    function initializeInteractionTracking() {
      let lastInteractionTime = Date.now();
      const events = ['click', 'touchstart', 'keydown', 'scroll', 'input'];
      events.forEach(event => {
        document.addEventListener(event, () => {
          lastInteractionTime = Date.now();
        });
      });
      
      setInterval(() => {
        const timeSinceLastInteraction = Date.now() - lastInteractionTime;
        if (timeSinceLastInteraction >= $idleTimeThresholdInMillis) {
          window.flutter_inappwebview.callHandler('triggerAIFlow');
        }
      }, 1000);
    }

    if (document.readyState === 'complete') {
      initializeInteractionTracking();
    } else {
      document.addEventListener('DOMContentLoaded', initializeInteractionTracking);
    }
  })();
  """;
}

String loginButtonHeuristicsInjection() {
  return """
const loginWords = [
    'login', 'log in', 'sign in', 'signin', 'sign-in',
    'register', 'signup', 'sign up', 'sign-up',
    'account', 'profile', 'user',
    'authenticate', 'authentication', 'welcome',
    'welcome back','logout', 'log out', 'sign out', 'signout', 'disconnect',
        'my account', 'my profile', 'settings', 'preferences', 'personal'
];

const containsLoginWord = (text) => {
    if (!text) return false;
    const lowerText = text.toLowerCase();
    return loginWords.some(word => lowerText.includes(word));
};

const hasLoginChildren = (element) => {
    return Array.from(element.children).some(child => {
        // Check child's text content
        if (containsLoginWord(child.textContent)) return true;
        // Recursively check child's children
        return hasLoginChildren(child);
    });
};
const findLoginElements = () => {
    const allElements = document.querySelectorAll('*');
    const loginElements = [];

    for(const element of allElements) {
        if(loginElements.length > 12)break;
        // Skip if element has children with login-related content
        if (hasLoginChildren(element)) continue;

        // Check element's own text (excluding children's text)
        const ownText = Array.from(element.childNodes)
            .filter(node => node.nodeType === 3) // Text nodes only
            .map(node => node.textContent.trim())
            .join(' ');

        if (containsLoginWord(ownText.toLowerCase()) && ownText.length < 40) {
            loginElements.push({
                ElementTag: element.tagName.toLowerCase(),
                text: ownText
            });
        }

        // Check element's attributes
        const attributes = ['id', 'class', 'name', 'aria-label', 'placeholder', 'title', 'alt'];
        attributes.forEach(attr => {
            if (element.hasAttribute(attr) && containsLoginWord(element.getAttribute(attr))) {
                const clone = element.cloneNode(false);
                const elementWithoutChildren = clone.outerHTML;
                loginElements.push({
                    elementTag: element.tagName.toLowerCase(),
                    htmlElement:elementWithoutChildren
                });
            }
        });
    };
    
    let result = JSON.stringify(loginElements)
    const finalResult = result.slice(0, 2000);
    return finalResult
};
""";
}
