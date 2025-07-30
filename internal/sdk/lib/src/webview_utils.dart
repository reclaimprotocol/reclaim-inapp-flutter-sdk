import 'dart:convert';

import 'constants.dart';
import 'data/providers.dart';
import 'web_scripts/scripts/mwjs.dart';

const String NONE = '''
console.log(async function(request, response) {
  try{
''';

const XHOOK =
// Note: Abdul said this is not a problem.
// ignore: unnecessary_string_escapes
"""var xhook=function(){"use strict";const e=(e,t)=>Array.prototype.slice.call(e,t);let t=null;"undefined"!=typeof WorkerGlobalScope&&self instanceof WorkerGlobalScope?t=self:"undefined"!=typeof global?t=global:window&&(t=window);const n=t,r=t.document,o=["load","loadend","loadstart"],s=["progress","abort","error","timeout"],a=e=>["returnValue","totalSize","position"].includes(e),i=function(e,t){for(let n in e){if(a(n))continue;const r=e[n];try{t[n]=r}catch(e){}}return t},c=function(e,t,n){const r=e=>function(r){const o={};for(let e in r){if(a(e))continue;const s=r[e];o[e]=s===t?n:s}return n.dispatchEvent(e,o)};for(let o of Array.from(e))n._has(o)&&(t['on'+o]=r(o))},u=function(e){if(r&&null!=r.createEventObject){const t=r.createEventObject();return t.type=e,t}try{return new Event(e)}catch(t){return{type:e}}},l=function(t){let n={};const r=e=>n[e]||[],o={addEventListener:function(e,t,o){n[e]=r(e),n[e].indexOf(t)>=0||(o=void 0===o?n[e].length:o,n[e].splice(o,0,t))},removeEventListener:function(e,t){if(void 0===e)return void(n={});void 0===t&&(n[e]=[]);const o=r(e).indexOf(t);-1!==o&&r(e).splice(o,1)},dispatchEvent:function(){const n=e(arguments),s=n.shift();t||(n[0]=i(n[0],u(s)));const a=o['on'+s];a&&a.apply(o,n);const c=r(s).concat(r("*"));for(let e=0;e<c.length;e++){c[e].apply(o,n)}},_has:e=>!(!n[e]&&!o['on'+e])};return t&&(o.listeners=t=>e(r(t)),o.on=o.addEventListener,o.off=o.removeEventListener,o.fire=o.dispatchEvent,o.once=function(e,t){var n=function(){return o.off(e,n),t.apply(null,arguments)};return o.on(e,n)},o.destroy=()=>n={}),o};var f=function(e,t){switch(typeof e){case"object":return n=e,Object.entries(n).map((([e,t])=>e.toLowerCase()+':' +t)).join("\\r\\n");case"string":return function(e,t){const n=e.split("\\r\\n");null==t&&(t={});for(let e of n)if(/([^:]+):\s*(.+)/.test(e)){const e=null!=RegExp.\$1?RegExp.\$1.toLowerCase():void 0,n=RegExp.\$2;null==t[e]&&(t[e]=n)}return t}(e,t)}var n;return[]};const d=l(!0),p=e=>void 0===e?null:e,h=n.XMLHttpRequest,y=function(){const e=new h,t={};let n,r,a,u=null;var y=0;const v=function(){if(a.status=u||e.status,-1!==u&&(a.statusText=e.statusText),-1===u);else{const t=f(e.getAllResponseHeaders());for(let e in t){const n=t[e];if(!a.headers[e]){const t=e.toLowerCase();a.headers[t]=n}}}},g=function(){x.status=a.status,x.statusText=a.statusText},E=function(){n||x.dispatchEvent("load",{}),x.dispatchEvent("loadend",{}),n&&(x.readyState=0)},b=function(e){for(;e>y&&y<4;)x.readyState=++y,1===y&&x.dispatchEvent("loadstart",{}),2===y&&g(),4===y&&(g(),"text"in a&&(x.responseText=a.text),"xml"in a&&(x.responseXML=a.xml),"data"in a&&(x.response=a.data),"finalUrl"in a&&(x.responseURL=a.finalUrl)),x.dispatchEvent("readystatechange",{}),4===y&&(!1===t.async?E():setTimeout(E,0))},m=function(e){if(4!==e)return void b(e);const n=d.listeners("after");var r=function(){if(n.length>0){const e=n.shift();2===e.length?(e(t,a),r()):3===e.length&&t.async?e(t,a,r):r()}else b(4)};r()};var x=l();t.xhr=x,e.onreadystatechange=function(t){try{2===e.readyState&&v()}catch(e){}4===e.readyState&&(r=!1,v(),function(){if(e.responseType&&"text"!==e.responseType)"document"===e.responseType?(a.xml=e.responseXML,a.data=e.responseXML):a.data=e.response;else{a.text=e.responseText,a.data=e.responseText;try{a.xml=e.responseXML}catch(e){}}"responseURL"in e&&(a.finalUrl=e.responseURL)}()),m(e.readyState)};const L=function(){n=!0};x.addEventListener("error",L),x.addEventListener("timeout",L),x.addEventListener("abort",L),x.addEventListener("progress",(function(t){y<3?m(3):e.readyState<=3&&x.dispatchEvent("readystatechange",{})})),"withCredentials"in e&&(x.withCredentials=!1),x.status=0;for(let e of Array.from(s.concat(o)))x['on'+e ]=null;if(x.open=function(e,o,s,i,c){y=0,n=!1,r=!1,t.headers={},t.headerNames={},t.status=0,t.method=e,t.url=o,t.async=!1!==s,t.user=i,t.pass=c,a={},a.headers={},m(1)},x.send=function(n){let u,l;for(u of["type","timeout","withCredentials"])l="type"===u?"responseType":u,l in x&&(t[u]=x[l]);t.body=n;const f=d.listeners("before");var p=function(){if(!f.length)return function(){for(u of(c(s,e,x),x.upload&&c(s.concat(o),e.upload,x.upload),r=!0,e.open(t.method,t.url,t.async,t.user,t.pass),["type","timeout","withCredentials"]))l="type"===u?"responseType":u,u in t&&(e[l]=t[u]);for(let n in t.headers){const r=t.headers[n];n&&e.setRequestHeader(n,r)}e.send(t.body)}();const n=function(e){if("object"==typeof e&&("number"==typeof e.status||"number"==typeof a.status))return i(e,a),"data"in e||(e.data=e.response||e.text),void m(4);p()};n.head=function(e){i(e,a),m(2)},n.progress=function(e){i(e,a),m(3)};const d=f.shift();1===d.length?n(d(t)):2===d.length&&t.async?d(t,n):n()};p()},x.abort=function(){u=-1,r?e.abort():x.dispatchEvent("abort",{})},x.setRequestHeader=function(e,n){const r=null!=e?e.toLowerCase():void 0,o=t.headerNames[r]=t.headerNames[r]||e;t.headers[o]&&(n=t.headers[o]+", "+n),t.headers[o]=n},x.getResponseHeader=e=>p(a.headers[e?e.toLowerCase():void 0]),x.getAllResponseHeaders=()=>p(f(a.headers)),e.overrideMimeType&&(x.overrideMimeType=function(){e.overrideMimeType.apply(e,arguments)}),e.upload){let e=l();x.upload=e,t.upload=e}return x.UNSENT=0,x.OPENED=1,x.HEADERS_RECEIVED=2,x.LOADING=3,x.DONE=4,x.response="",x.responseText="",x.responseXML=null,x.readyState=0,x.statusText="",x};y.UNSENT=0,y.OPENED=1,y.HEADERS_RECEIVED=2,y.LOADING=3,y.DONE=4;var v={patch(){h&&(n.XMLHttpRequest=y)},unpatch(){h&&(n.XMLHttpRequest=h)},Native:h,Xhook:y};const g=n.fetch;function E(e){return e instanceof Headers?b([...e.entries()]):Array.isArray(e)?b(e):e}function b(e){return e.reduce(((e,[t,n])=>(e[t]=n,e)),{})}const m=function(e,t={headers:{}}){let n=Object.assign(Object.assign({},t),{isFetch:!0});if(e instanceof Request){const r=function(e){let t={};return["method","headers","body","mode","credentials","cache","redirect","referrer","referrerPolicy","integrity","keepalive","signal","url"].forEach((n=>t[n]=e[n])),t}(e),o=Object.assign(Object.assign({},E(r.headers)),E(n.headers));n=Object.assign(Object.assign(Object.assign({},r),t),{headers:o,acceptedRequest:!0})}else n.url=e;const r=d.listeners("before"),o=d.listeners("after");return new Promise((function(e,t){let s=e;const a=function(e){if(!o.length)return s(e);const t=o.shift();return 2===t.length?(t(n,e),a(e)):3===t.length?t(n,e,a):a(e)},i=function(t){if(void 0!==t){const n=new Response(t.body||t.text,t);return e(n),void a(n)}c()},c=function(){if(!r.length)return void u();const e=r.shift();return 1===e.length?i(e(n)):2===e.length?e(n,i):void 0},u=()=>{const{url:e,isFetch:r,acceptedRequest:o}=n,i=function(e,t){var n={};for(var r in e)Object.prototype.hasOwnProperty.call(e,r)&&t.indexOf(r)<0&&(n[r]=e[r]);if(null!=e&&"function"==typeof Object.getOwnPropertySymbols){var o=0;for(r=Object.getOwnPropertySymbols(e);o<r.length;o++)t.indexOf(r[o])<0&&Object.prototype.propertyIsEnumerable.call(e,r[o])&&(n[r[o]]=e[r[o]])}return n}(n,["url","isFetch","acceptedRequest"]);g(e,i).then((e=>a(e))).catch((function(e){return s=t,a(e),t(e)}))};c()}))};var x={patch(){g&&(n.fetch=m)},unpatch(){g&&(n.fetch=g)},Native:g,Xhook:m};const L=d;return L.EventEmitter=l,L.before=function(e,t){if(e.length<1||e.length>2)throw"invalid hook";return L.on("before",e,t)},L.after=function(e,t){if(e.length<2||e.length>3)throw"invalid hook";return L.on("after",e,t)},L.enable=function(){v.patch(),x.patch()},L.disable=function(){v.unpatch(),x.unpatch()},L.XMLHttpRequest=v.Native,L.fetch=x.Native,L.headers=f,L.enable(),L}();
  xhook.before(async (request) => {
    let url = request.url;
    if (request.url.startsWith("/")) {
      url = window.location.origin + request.url;
    } else if (!request.url.startsWith("http")) {
      url = window.location.href + request.url;
    }
    const requestMethod = request.method;
    let requestBody = "";
    if (request.body) {
      requestBody = request.body;
    }
    let parsedHeaders = {};
    if (request.headers && request.headers.get) {
      parsedHeaders = Object.fromEntries(request.headers);
    } else {
      parsedHeaders = request.headers;
    }
    
    if(window.requestInterceptorOverride){
      window.requestInterceptorOverride(url, requestMethod, requestBody, parsedHeaders,request)  
    }
  });
  xhook.after(async function (request, response) {
    try {
      let url = request.url;
      if (request.url.startsWith("/")) {
        url = window.location.origin + request.url;
      } else if (!request.url.startsWith("http")) {
        url = window.location.href + request.url;
      }
      const requestMethod = request.method;
      const headers = request.headers;
      let requestBody = "";
      if (request.body) {
        requestBody = request.body;
      }
      let responseText = "";
      if (request.isFetch) {
        const cloneResponse = response.clone();
        responseText = await cloneResponse.text();
      } else {
        responseText = response.text;
      }
""";

const String MSWJS = """
    $MSWJS_BASE
    window.allRequest =  new Map();
    window.reclaimInterceptor.on('request', async ({ request, requestId }) => {
      try {
        window.allRequest.set(requestId, request.clone())
        
      } catch (err) {
        console.log('err', err)
      }
    })
    window.reclaimInterceptor.on('response', async ({requestId,response}) => {
      try{
        const request =   window.allRequest.get(requestId);
        const url = request.url.startsWith('/') ? window.location.origin + request.url :request.url ;
        let parsedHeaders = {}
        let requestMethod = request.method ? request.method : 'GET';
        if(request.headers && request.headers.get){
          parsedHeaders= Object.fromEntries(request.headers);
        }
        else{
          parsedHeaders= request.headers;
        }
        let responseText;
        if(typeof response.text === 'function'){
          const cloneResponse = response.clone()
          responseText =  await cloneResponse.text()
        }
        else{
          responseText = response.text
        }
        const headers = parsedHeaders;
        let requestBody;
        if (typeof request.text === 'function') {
          const cloneRequest = request.clone()
          requestBody = await cloneRequest.text()
        } else {
          requestBody = response.text
        } 
        

""";

const requestReplayInjection = """
if(!window.reclaimFetchInjected){
      fetch(window.location.href,{method:"GET"}).then(async (response) => {})
      window.reclaimFetchInjected = true;
    }
""";

class InjectionRequest {
  final String urlRegex;
  final String bodySniffRegex;
  final bool bodySniffEnabled;
  final RequestMethodType method;
  // For identifying which request is being matched
  final String requestHash;

  const InjectionRequest({
    required this.urlRegex,
    required this.bodySniffRegex,
    required this.bodySniffEnabled,
    required this.method,
    required this.requestHash,
  });

  Map<String, dynamic> toJson() {
    return {
      'urlRegex': urlRegex.replaceAll('\\\\', '\\'),
      'bodySniffRegex': bodySniffRegex.replaceAll('\\\\', '\\'),
      'bodySniffEnabled': bodySniffEnabled,
      'method': method.name,
      'requestHash': requestHash,
    };
  }
}

const _sendRequestLogs =
    r"window.flutter_inappwebview.callHandler('requestLogs', JSON.stringify({ requestBody: requestBody, url: url, responseBody: responseText, method: requestMethod, currentPageUrl: window.location.href, contentType: headers['content-type'] || headers['Content-Type'], metadata: { loadEventStart: new Date((window.performance.timeOrigin + (window.performance.getEntriesByType('navigation')[0].loadEventStart))).toISOString(),  receivedAt: new Date().toISOString() }}));";

String createInjection(Iterable<InjectionRequest> requests, bool disableRequestReplay, InjectionType injectionType) {
  final requestsJson = json.encode(requests.toList());
  final s = """
    window.ReclaimInjected = true;
    ${injectionType == InjectionType.MSWJS ? MSWJS : ''}
    ${injectionType == InjectionType.NONE ? NONE : ''}
    ${injectionType == InjectionType.XHOOK ? XHOOK : ''}
        $_sendRequestLogs
        const injectedRequests = $requestsJson;
        for (const injectedRequest of injectedRequests) {
          if (url.match(injectedRequest.urlRegex) && requestMethod === injectedRequest.method && (!injectedRequest.bodySniffEnabled || (injectedRequest.bodySniffEnabled && requestBody.match(injectedRequest.bodySniffRegex)))) {
            window.flutter_inappwebview.callHandler('proofData', JSON.stringify({requestBody: requestBody,url: url,headers: headers ,response : responseText, matchedRequest: injectedRequest}));
            break;
          }
        }
      }
      catch (e){
        window.flutter_inappwebview.callHandler('errorLogs', JSON.stringify({log:e.message }));
      }
    });
    ${!disableRequestReplay ? requestReplayInjection : ""}
  true;
  """;

  return s;
}

String createManualVerificationInjections(bool disableRequestReplay, InjectionType injectionType) {
  final s = """
    window.ReclaimInjected = true;
    ${injectionType == InjectionType.NONE ? NONE : ''}
    ${injectionType == InjectionType.MSWJS ? MSWJS : ''}
    ${injectionType == InjectionType.XHOOK ? XHOOK : ''}
        $_sendRequestLogs
        // add param matching logic
      }
      catch (e){
        window.flutter_inappwebview.callHandler('errorLogs', JSON.stringify({log:e.message }));
        
      }
    });
    ${!disableRequestReplay ? requestReplayInjection : ""}
  true;
  """;
  return s;
}

String escapeSpecialCharacters(String input, {bool extraEscape = false}) {
  return input.replaceAllMapped(RegExp(r'[[\]()*+?.,\\^$|#]'), (Match match) {
    return extraEscape ? '\\\\${match[0]}' : '\\${match[0]}';
  });
}

String escapeRegexTemplate({String regexTemplate = '', bool extraEscape = false}) {
  const greedyPattern = '(.*)';
  const lazyPattern = '(.*?)';
  return regexTemplate
      .split(greedyPattern)
      .map((it) {
        return it
            .split(lazyPattern)
            .map((it) => escapeSpecialCharacters(it, extraEscape: extraEscape))
            .join(lazyPattern);
      })
      .join(greedyPattern);
}

typedef ConvertedTemplateResult = (String template, List<String> allVars, List<String> unSubstitutedVars);

Iterable<String> getTemplateVariables(final String template) {
  return templateParamRegex.allMatches(template).map((match) => match.group(1)).whereType<String>();
}

String interpolateParamValue(final String template, final String param, final Map<String, String> values) {
  final value = values[param];
  if (value == null) return template;
  return template.replaceAll('{{$param}}', value);
}

String interpolateTemplateWithValues(final String template, final Map<String, String> values) {
  String value = template;
  for (final param in values.keys) {
    value = interpolateParamValue(value, param, values);
  }
  return value;
}

ConvertedTemplateResult convertTemplateToRegex({
  Map<String, String> parameters = const {},
  String template = '',
  MatchType? matchTypeOverride,
  bool extraEscape = false,
}) {
  template = escapeSpecialCharacters(template, extraEscape: extraEscape);

  final List<String> unSubstitutedVars = [];
  final Set<String> allVars = getTemplateVariables(template).toSet();
  for (final param in allVars) {
    if (parameters.containsKey(param)) {
      template = interpolateParamValue(template, param, parameters);
    } else {
      unSubstitutedVars.add(param);

      final replacement = matchTypeOverride == MatchType.GREEDY || param.endsWith('GRD') ? '(.*)' : '(.*?)';
      template = template.replaceAll('{{$param}}', replacement);
    }
  }
  return (template, allVars.toList(), unSubstitutedVars);
}
