const _status408RequestTimeout = 408;
const _status429TooManyRequests = 429;
const _status500InternalServerError = 500;
const _status502BadGateway = 502;
const _status503ServiceUnavailable = 503;
const _status504GatewayTimeout = 504;

/// From IIS
const _status440LoginTimeout = 440;

/// From ngnix
const _status499ClientClosedRequest = 499;

/// From AWS Elastic Load Balancer
const _status460ClientClosedRequest = 460;

// Not in RFC:
const _status598NetworkReadTimeoutError = 598;
const _status599NetworkConnectTimeoutError = 599;

// Cloudflare Statuses
const _status520WebServerReturnedUnknownError = 520;
const _status521WebServerIsDown = 521;
const _status522ConnectionTimedOut = 522;
const _status523OriginIsUnreachable = 523;
const _status524TimeoutOccurred = 524;
const _status525SSLHandshakeFailed = 525;
const _status527RailgunError = 527;

const _defaultRetryableStatuses = <int>{
  _status408RequestTimeout,
  _status429TooManyRequests,
  _status500InternalServerError,
  _status502BadGateway,
  _status503ServiceUnavailable,
  _status504GatewayTimeout,
  _status440LoginTimeout,
  _status499ClientClosedRequest,
  _status460ClientClosedRequest,
  _status598NetworkReadTimeoutError,
  _status599NetworkConnectTimeoutError,
  _status520WebServerReturnedUnknownError,
  _status521WebServerIsDown,
  _status522ConnectionTimedOut,
  _status523OriginIsUnreachable,
  _status524TimeoutOccurred,
  _status525SSLHandshakeFailed,
  _status527RailgunError,
};

bool isHttpResponseStatusRetryable(int statusCode) => _defaultRetryableStatuses.contains(statusCode);
