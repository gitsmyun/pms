package com.company.pms.project.service;

/**
 * PRJ 에러코드
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public enum ProjectErrorCode {
    PROJECT_NOT_FOUND("PMS-PRJ-404-001", "프로젝트 없음"),
    PROJECT_NAME_REQUIRED("PMS-PRJ-400-001", "프로젝트명 필수");

    private final String code;
    private final String title;

    ProjectErrorCode(String code, String title) {
        this.code = code;
        this.title = title;
    }

    public String code() {
        return code;
    }

    public String title() {
        return title;
    }
}
