package com.company.pms.api;

/**
 * REQ 에러코드
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public enum ReqErrorCode {
    VALIDATION_FAILED("PMS-REQ-400-001", "요청 검증 실패"),
    BAD_REQUEST("PMS-REQ-400-002", "요청 오류");

    private final String code;
    private final String title;

    ReqErrorCode(String code, String title) {
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
