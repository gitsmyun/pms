package com.company.pms.api;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;

/**
 * prod 예외 처리
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
@RestControllerAdvice
@Profile("prod")
public class ProdExceptionHandler {

    private final String problemBaseUrl;

    public ProdExceptionHandler(@Value("${pms.problem.base-url:https://pms.itcen.com}") String problemBaseUrl) {
        this.problemBaseUrl = problemBaseUrl;
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpectedProd(Exception ignored, HttpServletRequest request) {
        ProblemDetail pd = ProblemDetail.forStatus(HttpStatus.INTERNAL_SERVER_ERROR);
        pd.setType(ProblemType.UNEXPECTED.uri(problemBaseUrl));
        pd.setTitle(SysErrorCode.UNEXPECTED.title());
        pd.setDetail("서버 오류가 발생했습니다.");
        pd.setInstance(URI.create(request.getRequestURI()));

        pd.setProperty("code", SysErrorCode.UNEXPECTED.code());
        // exception 비노출(prod)
        return pd;
    }
}
