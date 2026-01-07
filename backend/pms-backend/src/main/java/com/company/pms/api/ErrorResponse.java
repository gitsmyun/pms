package com.company.pms.api;

import java.time.Instant;
import java.util.Map;

/**
 * (레거시) 에러 DTO
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public record ErrorResponse(
        Instant timestamp,
        int status,
        String error,
        String message,
        String path,
        String code,
        Map<String, Object> details
) {
    public static ErrorResponse of(int status, String error, String message, String path, String code, Map<String, Object> details) {
        return new ErrorResponse(Instant.now(), status, error, message, path, code, details);
    }
}
