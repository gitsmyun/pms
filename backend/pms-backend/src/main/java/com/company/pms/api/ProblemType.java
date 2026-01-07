package com.company.pms.api;

import java.net.URI;

/**
 * Problem type
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public enum ProblemType {
    VALIDATION("validation"),
    PROJECT_VALIDATION("project-validation"),
    BAD_REQUEST("bad-request"),
    PROJECT_NOT_FOUND("project-not-found"),
    UNEXPECTED("unexpected");

    private final String path;

    ProblemType(String path) {
        this.path = path;
    }

    public URI uri(String baseUrl) {
        String base = baseUrl == null ? "" : baseUrl.trim();
        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return URI.create(base + "/problems/" + path);
    }
}

