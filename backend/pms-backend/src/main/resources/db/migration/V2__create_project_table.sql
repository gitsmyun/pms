-- PMS2 baseline migration V2: create minimal project table
-- Rule: do not edit applied migrations. Add a new V{n}__*.sql for changes.

CREATE TABLE IF NOT EXISTS project (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_project_created_at ON project (created_at);

