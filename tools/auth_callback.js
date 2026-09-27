// Capture Auth responses before the engine loads; keep tokens only in memory.
(() => {
  const params = new URLSearchParams(window.location.hash.slice(1));
  if (!params.has('access_token') && !params.has('error') && !params.has('error_code')) return;
  const response = {};
  for (const key of ['type', 'access_token', 'refresh_token', 'expires_in', 'error', 'error_code']) {
    if (params.has(key)) response[key] = params.get(key);
  }
  window.history.replaceState(null, '', window.location.pathname + window.location.search);
  window.__glutwachtEmailLink = response;
})();
