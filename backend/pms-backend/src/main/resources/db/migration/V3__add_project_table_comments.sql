-- PMS2 migration V3: 스키마 오브젝트 코멘트(문서화) 추가
-- NOTE: 코멘트는 스키마 계약의 일부입니다. 변경이 필요하면 새 migration으로만 수정합니다.

-- 테이블 코멘트
COMMENT ON TABLE project IS '프로젝트(PMS). 업무(이슈/태스크)와 협업을 위한 최상위 작업 단위 컨테이너.';

-- 컬럼 코멘트
COMMENT ON COLUMN project.id IS '기본키(PK). PostgreSQL BIGSERIAL(IDENTITY)로 자동 생성.';
COMMENT ON COLUMN project.name IS '프로젝트명(필수). 최대 100자.';
COMMENT ON COLUMN project.description IS '프로젝트 설명(선택). 자유 형식 텍스트.';
COMMENT ON COLUMN project.created_at IS '생성 일시. DB 서버 시간 기준, 기본값 now().';
