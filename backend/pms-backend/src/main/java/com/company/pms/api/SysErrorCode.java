package com.company.pms.api;

/**
 * SYS 에러코드
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public enum SysErrorCode {
    UNEXPECTED("PMS-SYS-500-001", "서버 오류");

    private final String code;
    private final String title;

    SysErrorCode(String code, String title) {
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

