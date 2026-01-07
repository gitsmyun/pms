-- PMS2 migration V4: 프로젝트(project) 테이블/컬럼 코멘트를 한글 표준으로 갱신
-- NOTE: 이미 적용된 코멘트 변경도 새 migration으로만 수행합니다.

COMMENT ON TABLE project IS '프로젝트(PMS). 업무(이슈/태스크)와 협업을 위한 최상위 작업 단위 컨테이너.';

COMMENT ON COLUMN project.id IS '기본키(PK). PostgreSQL BIGSERIAL(IDENTITY)로 자동 생성.';
COMMENT ON COLUMN project.name IS '프로젝트명(필수). 최대 100자.';
COMMENT ON COLUMN project.description IS '프로젝트 설명(선택). 자유 형식 텍스트.';
COMMENT ON COLUMN project.created_at IS '생성 일시. DB 서버 시간 기준, 기본값 now().';

