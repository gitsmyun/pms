package com.company.pms.project.controller;

import com.company.pms.project.domain.Project;
import com.company.pms.project.service.ProjectService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Project API
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
@RestController
public class ProjectController {

    private final ProjectService projectService;

    public ProjectController(ProjectService projectService) {
        this.projectService = projectService;
    }

    @GetMapping("/api/projects")
    public List<ProjectResponse> getProjects() {
        // 목록 조회
        return projectService.findAll().stream().map(ProjectResponse::from).toList();
    }

    @PostMapping("/api/projects")
    @ResponseStatus(HttpStatus.CREATED)
    public ProjectResponse createProject(@Valid @RequestBody CreateProjectRequest request) {
        // 프로젝트 생성
        Project created = projectService.create(request.name(), request.description());
        return ProjectResponse.from(created);
    }

    @GetMapping("/api/projects/{id}")
    public ProjectResponse getProject(@PathVariable Long id) {
        // 단건 조회
        Project project = projectService.findById(id);
        return ProjectResponse.from(project);
    }

    public record ProjectResponse(Long id, String name, String description, LocalDateTime createdAt) {
        public static ProjectResponse from(Project project) {
            return new ProjectResponse(project.getId(), project.getName(), project.getDescription(), project.getCreatedAt());
        }
    }
}
