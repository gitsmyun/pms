package com.company.pms.project.service;

/**
 * 프로젝트 없음
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public class ProjectNotFoundException extends RuntimeException {

    public ProjectNotFoundException(Long id) {
        super("프로젝트 없음: id=" + id);
    }
}

