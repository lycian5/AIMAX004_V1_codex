// Vercel Cron은 호출 시 Authorization: Bearer <CRON_SECRET> 헤더를 자동으로 붙인다.
// CRON_SECRET 환경변수를 설정해두면 외부에서 이 엔드포인트를 임의로 호출하는 것을 막을 수 있다.
function assertCronAuth(req) {
  const secret = process.env.CRON_SECRET;
  if (!secret) return; // 로컬 개발 등에서 미설정 시 통과 — 배포 전 반드시 설정 권장

  const header = req.headers['authorization'] || '';
  if (header !== `Bearer ${secret}`) {
    const err = new Error('Unauthorized');
    err.statusCode = 401;
    throw err;
  }
}

module.exports = { assertCronAuth };
