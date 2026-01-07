package com.company.pms.project.service;

/**
 * 프로젝트 검증
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public class ProjectValidationException extends RuntimeException {

    private final ProjectErrorCode errorCode;

    public ProjectValidationException(ProjectErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    public ProjectErrorCode errorCode() {
        return errorCode;
    }
}

