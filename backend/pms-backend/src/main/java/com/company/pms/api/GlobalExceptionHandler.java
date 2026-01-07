package com.company.pms.api;

import com.company.pms.project.service.ProjectErrorCode;
import com.company.pms.project.service.ProjectNotFoundException;
import com.company.pms.project.service.ProjectValidationException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 전역 예외 처리
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private final String problemBaseUrl;

    public GlobalExceptionHandler(@Value("${pms.problem.base-url:https://pms.itcen.com}") String problemBaseUrl) {
        this.problemBaseUrl = problemBaseUrl;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        ProblemDetail pd = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        pd.setType(ProblemType.VALIDATION.uri(problemBaseUrl));
        pd.setTitle(ReqErrorCode.VALIDATION_FAILED.title());
        pd.setDetail("요청이 올바르지 않습니다.");
        pd.setInstance(URI.create(request.getRequestURI()));

        pd.setProperty("code", ReqErrorCode.VALIDATION_FAILED.code());

        // 필드에러 목록
        List<Map<String, Object>> errors = new ArrayList<>();
        for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("field", fe.getField());
            item.put("message", fe.getDefaultMessage());
            Object rejected = fe.getRejectedValue();
            if (rejected != null) {
                item.put("rejected", rejected);
            }
            errors.add(item);
        }
        pd.setProperty("errors", errors);
        return pd;
    }

    // NOTE: ProjectValidationException은 IllegalArgumentException보다 먼저 매핑되어 도메인 코드가 우선 적용됨
    @ExceptionHandler(ProjectValidationException.class)
    public ProblemDetail handleProjectValidation(ProjectValidationException ex, HttpServletRequest request) {
        ProblemDetail pd = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        pd.setType(ProblemType.PROJECT_VALIDATION.uri(problemBaseUrl));
        pd.setTitle(ex.errorCode().title());
        pd.setDetail("요청이 올바르지 않습니다.");
        pd.setInstance(URI.create(request.getRequestURI()));

        pd.setProperty("code", ex.errorCode().code());

        // local만 상세
        String profile = System.getProperty("spring.profiles.active", System.getenv("SPRING_PROFILES_ACTIVE"));
        if (profile != null && profile.contains("local")) {
            pd.setProperty("debugMessage", ex.getMessage());
        }
        return pd;
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ProblemDetail handleBadRequest(IllegalArgumentException ex, HttpServletRequest request) {
        ProblemDetail pd = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        pd.setType(ProblemType.BAD_REQUEST.uri(problemBaseUrl));
        pd.setTitle(ReqErrorCode.BAD_REQUEST.title());
        pd.setDetail("요청이 올바르지 않습니다.");
        pd.setInstance(URI.create(request.getRequestURI()));

        pd.setProperty("code", ReqErrorCode.BAD_REQUEST.code());

        // local만 상세
        String profile = System.getProperty("spring.profiles.active", System.getenv("SPRING_PROFILES_ACTIVE"));
        if (profile != null && profile.contains("local")) {
            pd.setProperty("debugMessage", ex.getMessage());
        }
        return pd;
    }

    @ExceptionHandler(ProjectNotFoundException.class)
    public ProblemDetail handleProjectNotFound(ProjectNotFoundException ex, HttpServletRequest request) {
        ProblemDetail pd = ProblemDetail.forStatus(HttpStatus.NOT_FOUND);
        pd.setType(ProblemType.PROJECT_NOT_FOUND.uri(problemBaseUrl));
        pd.setTitle(ProjectErrorCode.PROJECT_NOT_FOUND.title());
        pd.setDetail("리소스를 찾을 수 없습니다.");
        pd.setInstance(URI.create(request.getRequestURI()));

        pd.setProperty("code", ProjectErrorCode.PROJECT_NOT_FOUND.code());

        // local만 상세
        String profile = System.getProperty("spring.profiles.active", System.getenv("SPRING_PROFILES_ACTIVE"));
        if (profile != null && profile.contains("local")) {
            pd.setProperty("debugMessage", ex.getMessage());
        }
        return pd;
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpected(Exception ex, HttpServletRequest request) {
        ProblemDetail pd = ProblemDetail.forStatus(HttpStatus.INTERNAL_SERVER_ERROR);
        pd.setType(ProblemType.UNEXPECTED.uri(problemBaseUrl));
        pd.setTitle(SysErrorCode.UNEXPECTED.title());
        pd.setDetail("서버 오류가 발생했습니다.");
        pd.setInstance(URI.create(request.getRequestURI()));

        pd.setProperty("code", SysErrorCode.UNEXPECTED.code());

        // local만 노출
        String profile = System.getProperty("spring.profiles.active", System.getenv("SPRING_PROFILES_ACTIVE"));
        if (profile != null && profile.contains("local")) {
            pd.setProperty("exception", ex.getClass().getName());
        }
        return pd;
    }
}
