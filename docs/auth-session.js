(function () {
  const endpoint = '/api/editorial/drafts';

  async function session() {
    try {
      const response = await fetch(`${endpoint}?view=session`, { credentials: 'same-origin' });
      return response.ok && (await response.json()).authenticated === true;
    } catch (_) {
      return false;
    }
  }

  async function requireSession() {
    if (await session()) return true;
    const next = `${location.pathname}${location.search}`;
    location.replace(`/admin-login?next=${encodeURIComponent(next)}`);
    return false;
  }

  async function request(url, options = {}) {
    const response = await fetch(url, { ...options, credentials: 'same-origin' });
    if (response.status === 401) {
      const next = `${location.pathname}${location.search}`;
      location.replace(`/admin-login?next=${encodeURIComponent(next)}`);
      throw new Error('로그인 세션이 만료되었습니다.');
    }
    return response;
  }

  async function logout() {
    await fetch(endpoint, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'logout' }),
    });
    location.replace('/admin-login');
  }

  window.CoaAuth = { logout, request, requireSession, session };
})();
