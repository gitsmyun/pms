package com.company.pms.project.controller;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Project 생성요청
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public record CreateProjectRequest(
        @NotBlank(message = "프로젝트명은 필수입니다.")
        @Size(max = 100, message = "프로젝트명은 최대 100자까지 가능합니다.")
        String name,

        @Size(max = 2000, message = "프로젝트 설명은 최대 2000자까지 가능합니다.")
        String description
) {
}
