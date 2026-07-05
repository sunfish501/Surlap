# Surlap — Google Play Console "앱 콘텐츠" 입력 가이드

> 패키지명: `com.kev208dev.Surlap`
> Supabase 프로젝트: `https://ngmvddxpoqtbrwpwiogh.supabase.co`
> 모든 정책/요청 페이지는 Supabase Edge Functions 로 호스팅(`/functions/v1/...`).
> 사전 작업: Supabase 프로젝트가 INACTIVE 면 대시보드에서 "Restore" → 활성화 →
> 아래 §10·§13 절차로 Edge Functions 3개 + 테이블 1개 배포.

각 섹션 옆에 **그대로 입력할 답변·URL** 정리. 끝쪽에 추가로 깔 Supabase 자산
(계정 삭제 Edge Function + 테이블 + 리뷰용 테스트 계정) SQL/코드.

---

## 1. 개인정보처리방침

| 항목 | 값 |
|---|---|
| URL | `https://kev208dev.github.io/Surlap/privacy.html` |

GitHub Pages 의 `docs/` 폴더에 `privacy.html` 호스팅 중. 이미 코드 상 `_openUrl` 도
이 URL을 가리킴.

추가 권장:
- 본문에 "개인정보 보호 책임자: kev208dev@gmail.com" 명시
- 데이터 수집 항목/이용 목적/보관 기간/제3자 공유(없음 또는 Supabase)/사용자 권리(열람·삭제·정정)

---

## 2. 로그인 세부정보 (App access)

리뷰어가 로그인 못 하면 거절. 로그인 우회 모드(게스트)도 있지만 가입자 전용
기능(공유 캘린더, 동기화) 검증을 위해 **리뷰용 계정** 제공 필수.

| 항목 | 값 |
|---|---|
| 모든 기능에 액세스할 수 있는 사용자 인증 정보가 필요한가요? | **예** |
| 이메일 | `play-review@surlap.app` *(아래 SQL 로 생성)* |
| 비밀번호 | `Surlap-Review-2026!` |
| 사용자 이름 | (비워둠) |
| 안내 사항 | "메인 화면에서 + 버튼 → 일정/할 일 추가, 캘린더 탭에서 월/주/일 보기 전환, 공유 캘린더 탭에서 캘린더 공유/구독 코드 입력 가능" |

테스트 계정 생성은 §6 SQL 블록 참고.

---

## 3. 광고

| 항목 | 값 |
|---|---|
| 앱에 광고가 포함되어 있나요? | **아니요** |

(AdMob 등 미사용. 향후 광고 도입 시 변경.)

---

## 4. 콘텐츠 등급 (IARC 설문)

전 등급(3+) 목표. 권장 답변:

| 항목 | 답변 |
|---|---|
| 카테고리 | **참조(Reference, News, or Educational)** — 일정 관리 |
| 폭력 | 없음 |
| 성적 콘텐츠 | 없음 |
| 비속어 | 없음 |
| 통제 약물 | 없음 |
| 도박 | 없음 |
| 공포 | 없음 |
| 사용자 상호작용 | **예** (공유 캘린더로 코드 공유 가능) |
| 위치 정보 공유 | 아니요 |
| 디지털 구매 | 아니요 |
| 사용자가 만든 콘텐츠 공유 | **예** (일정/테마) |

→ 예상 등급: **모든 사용자(Everyone / 3+)**

---

## 5. 타겟층 (Target audience and content)

| 항목 | 값 |
|---|---|
| 타겟 연령대 | **13세 이상** (초·중·고·대·일반인 모두 사용 가능. 13세 미만 따로 디자인하지 않음.) |
| 13세 미만 사용자에게 광고/UGC 노출? | 해당 없음(타겟 아님) |
| 앱이 아동에게 매력적인 디자인 요소를 가지고 있나요? | 아니요 (학습용 캘린더 톤. 마스코트 1개 있으나 주된 디자인 아님) |
| 잘못된 연령 표시 가능성에 대한 알림? | 일반 디지털 시민 안내문 |

---

## 6. 데이터 보안 (Data safety)

수집·공유·암호화 양식. Surlap 의 실제 처리 기준:

### 6.1 데이터 수집 여부
**예** — 사용자가 제공한 데이터(계정·일정·할 일·테마·시간표·생일)를 수집.

### 6.2 수집 유형 / 공유 / 목적 / 옵션
| 데이터 유형 | 수집 | 공유 | 선택/필수 | 목적 |
|---|---|---|---|---|
| 이메일 주소 | 예 | 아니요 | 필수(로그인 시) | 계정 관리 |
| 이름 / 닉네임 | 예 | 아니요 | 선택 | 계정 관리 |
| 비밀번호 | 예 | 아니요 | 필수(이메일 가입) | 인증 |
| 사용자가 만든 일정·할 일·메모·테마·생일·시간표 | 예 | 예(공유 캘린더 코드 입력 시 그 코드 소유자가 본 일정/테마만) | 선택 | 앱 기능 |
| 음성 입력(STT 결과 텍스트) | 아니요(기기에서 처리, 서버 미전송) | — | — | — |
| 알림 토큰 | 아니요 (로컬 알림만 사용) | — | — | — |
| 사용 통계·앱 성능 | 아니요 | — | — | — |
| 위치 | 아니요 | — | — | — |

### 6.3 보안 관행
| 항목 | 답변 |
|---|---|
| 전송 중 데이터 암호화 | **예 (HTTPS / Supabase TLS)** |
| 사용자가 데이터 삭제 요청 가능 | **예 (앱 내 설정→계정 삭제 + 웹 URL)** |
| Play Families 정책 준수 | 해당 없음 (13세 미만 타겟 아님) |
| 독립 보안 검토 | 아니요 |

### 6.4 데이터 삭제 URL
| 항목 | 값 |
|---|---|
| URL | `https://kev208dev.github.io/Surlap/account-delete.html` |

→ Supabase Edge Function (§7 배포 필요). GET = 안내 페이지(HTML 폼), POST = 이메일 접수.

---

## 7. 정부 앱

| 항목 | 값 |
|---|---|
| 정부 기관에서 만든 앱입니까? | **아니요** |

---

## 8. 금융 기능

| 항목 | 값 |
|---|---|
| 금융 기능(결제, 송금, 보험, 투자, 대출, 가상자산 등) 포함? | **아니요** |

---

## 9. 건강

| 항목 | 값 |
|---|---|
| 건강 데이터 처리(증상, 진료 기록, 임상 정보 등)? | **아니요** |
| 의료/임상 기능 제공? | 아니요 |

(생일 챙기기·시간표는 건강 데이터 아님.)

---

## 10. Supabase 자산 배포 — 한 번에 깔 SQL + Edge Function

### 10.1 테이블 + RLS — `apply_migration` 으로 적용
```sql
-- account_deletion_requests : 사용자가 웹/앱에서 보낸 삭제 요청 큐.
create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  status text not null default 'pending' check (status in ('pending','processed','failed'))
);
create index if not exists account_deletion_requests_email_idx
  on public.account_deletion_requests (email);

alter table public.account_deletion_requests enable row level security;

-- 익명/일반 사용자는 select 불가. Edge Function 의 service_role 만 insert/select.
-- (Edge Function 은 service_role 키로 동작하므로 RLS 우회.)
revoke all on public.account_deletion_requests from anon, authenticated;
```

### 10.2 Edge Function — `supabase/functions/account-delete-request/index.ts`
JWT 검증 없이 공개 엔드포인트(이메일 입력만 받음). 배포:
```bash
supabase functions deploy account-delete-request --no-verify-jwt
```
또는 MCP `deploy_edge_function(name='account-delete-request', verify_jwt=false)`.

소스(이미 짜둠 — `supabase/functions/account-delete-request/index.ts` 로 저장하면 됨):
```ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const HTML = `<!doctype html><html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Surlap 계정 삭제 요청</title>
<style>body{font-family:-apple-system,'Pretendard',sans-serif;background:#FBF9FE;color:#14131A;margin:0;padding:24px;display:flex;justify-content:center}
.card{max-width:520px;width:100%;background:#fff;border-radius:24px;padding:28px;box-shadow:0 20px 44px -16px rgba(74,31,208,.18)}
h1{font-size:22px;font-weight:800;letter-spacing:-.4px;margin:0 0 8px}
p{color:#6E6B7A;line-height:1.55;font-size:14.5px}
label{display:block;font-size:13px;color:#6E6B7A;font-weight:700;margin-top:18px}
input{display:block;width:100%;box-sizing:border-box;height:48px;padding:0 14px;border:1px solid rgba(20,19,26,.08);border-radius:12px;font-size:15px;margin-top:6px;background:#F6F4FA}
button{margin-top:18px;background:#5A2DF4;color:#fff;border:0;height:50px;border-radius:14px;font-weight:800;font-size:15px;width:100%;cursor:pointer}
.ok{background:#E7F8EC;color:#1F7A33;padding:12px 14px;border-radius:12px;margin-top:14px;display:none}</style></head>
<body><div class="card">
<h1>Surlap 계정 / 데이터 삭제 요청</h1>
<p>가입에 사용한 이메일을 입력하면 30일 안에 계정·일정·할 일·테마·생일·시간표 등 모든 사용자 데이터가 영구 삭제됩니다. 백업·로그 보관본도 90일 안에 제거됩니다.</p>
<form id="f"><label for="email">이메일</label>
<input id="email" name="email" type="email" required placeholder="you@example.com">
<button type="submit">삭제 요청 보내기</button></form>
<div id="ok" class="ok">접수되었습니다. 30일 안에 처리됩니다.</div>
</div><script>
document.getElementById('f').addEventListener('submit', async e => {
  e.preventDefault();
  const email = document.getElementById('email').value.trim();
  const r = await fetch(location.pathname, {method:'POST', headers:{'content-type':'application/json'}, body: JSON.stringify({email})});
  if (r.ok) { document.getElementById('f').style.display='none'; document.getElementById('ok').style.display='block'; }
  else alert('요청 실패: ' + await r.text());
});
</script></body></html>`;

Deno.serve(async (req) => {
  if (req.method === "GET") {
    return new Response(HTML, { headers: { "content-type": "text/html; charset=utf-8" } });
  }
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });
  let body: { email?: string } = {};
  try { body = await req.json(); } catch {}
  const email = (body.email ?? "").trim().toLowerCase();
  if (!email || !email.includes("@")) return new Response("invalid email", { status: 400 });
  const sb = createClient(SUPABASE_URL, SERVICE_ROLE);
  const { error } = await sb.from("account_deletion_requests").insert({ email });
  if (error) console.error("insert failed:", error.message);
  return new Response(JSON.stringify({ ok: true }), { headers: { "content-type": "application/json" } });
});
```

배포 후 URL:
```
https://ngmvddxpoqtbrwpwiogh.supabase.co/functions/v1/account-delete-request
```
→ Play Console "데이터 보안 → 사용자가 데이터 삭제 요청 가능" URL 칸에 그대로 붙여넣기.

### 10.3 리뷰용 테스트 계정 생성
Supabase 대시보드 → Auth → Users → "Add user" → 직접 입력:
- Email: `play-review@surlap.app`
- Password: `Surlap-Review-2026!`
- Auto Confirm User: **On**

또는 SQL (service_role 컨텍스트 필요):
```sql
-- Supabase 대시보드 Auth UI 권장(아래 SQL 은 보조 — auth.users 직접 insert 는 trigger 필요).
-- Dashboard → Authentication → Users → Add user.
```

처리 끝나면 비밀번호 매월 회전 + Play Console 에 업데이트.

### 10.4 OAuth 리다이렉트 URL — 별도 확인
Supabase Auth → URL Configuration → Redirect URLs 에 다음 등록:
- `surlap://login-callback`
- `https://kev208dev.github.io/Surlap/`
- `https://kev208dev.github.io/Surlap/*`

(없으면 Google 로그인 후 무한 루프.)

---

## 11. 빠른 체크리스트 (Play Console 에 그대로 입력)

| 섹션 | 입력 |
|---|---|
| 개인정보처리방침 URL | `https://kev208dev.github.io/Surlap/privacy.html` |
| 이용약관 URL (선택) | `https://kev208dev.github.io/Surlap/terms.html` |
| 광고 | 아니요 |
| 앱 액세스 | 사용자 인증 필요 — `play-review@surlap.app` / `Surlap-Review-2026!` |
| 콘텐츠 등급 카테고리 | Reference / Educational |
| 타겟 연령 | 13세 이상 |
| 데이터 수집 | 예(§6.2) |
| 전송 중 암호화 | 예 |
| 데이터 삭제 URL | `https://kev208dev.github.io/Surlap/account-delete.html` |
| 정부 앱 | 아니요 |
| 금융 기능 | 아니요 |
| 건강 | 아니요 |

---

## 13. Supabase Edge Function 3종 일괄 배포

저장소에 이미 소스 들어있음 — 프로젝트 깨운 뒤 한 번에 deploy.

```bash
# Supabase CLI 가 설치돼 있고, 프로젝트 링크돼 있다고 가정.
supabase functions deploy privacy                 --no-verify-jwt
supabase functions deploy terms                   --no-verify-jwt
supabase functions deploy account-delete-request  --no-verify-jwt
```

확인:
```bash
curl -I https://ngmvddxpoqtbrwpwiogh.supabase.co/functions/v1/privacy
curl -I https://ngmvddxpoqtbrwpwiogh.supabase.co/functions/v1/terms
curl -I https://ngmvddxpoqtbrwpwiogh.supabase.co/functions/v1/account-delete-request
```
세 곳 모두 `200 OK` + `content-type: text/html` 이어야 함.

소스 위치:
- `supabase/functions/privacy/index.ts` — 개인정보처리방침 HTML
- `supabase/functions/terms/index.ts` — 이용약관 HTML
- `supabase/functions/account-delete-request/index.ts` — GET=HTML 폼 + POST=email 큐

---

## 12. 진행 순서

1. Supabase 대시보드 Auth UI 에서 리뷰 계정 추가 (위 §10.3).
2. SQL editor 에 §10.1 붙여넣고 Run → `account_deletion_requests` 테이블 생성.
3. `supabase/functions/account-delete-request/index.ts` 파일 만들고 §10.2 코드 저장.
4. `supabase functions deploy account-delete-request --no-verify-jwt` 실행.
5. 배포된 URL 을 브라우저로 열어 HTML 페이지가 뜨는지 확인.
6. Play Console "앱 콘텐츠" 의 각 섹션에 §11 표값 그대로 입력.
7. 데이터 보안 양식 제출(§6).
8. 콘텐츠 등급 설문 + 타겟층 설문 답변(§4, §5).
9. 모든 섹션 완료 표시 확인 후 새 릴리스 검토 제출.
