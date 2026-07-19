# n8n 보관 워크플로

이 폴더의 JSON 파일은 초기 설계 이력과 수동 참조용입니다.

- `workflow_collect.json`: 구형 n8n 기본 수집, 비활성화
- `workflow_suggest.json`: 구형 n8n 추천, 비활성화
- `workflow_agent_reach_collect.json`: Agent Reach 호출용 템플릿, import 후 운영자가 명시적으로 활성화

구형 기본 수집과 추천 워크플로는 Vercel cron 및 VPS Agent Reach 수집과 중복되므로 운영 환경에서 활성화하지 않습니다. VPS 설치, 보안, 백업, 복원 기준은 `deploy/n8n/README.md`만 사용합니다. 특히 5678 포트를 외부에 직접 공개하지 않습니다.
