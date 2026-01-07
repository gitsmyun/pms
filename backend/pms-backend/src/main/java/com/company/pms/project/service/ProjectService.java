package com.company.pms.project.service;

import com.company.pms.project.domain.Project;
import com.company.pms.project.repository.ProjectRepository;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Project 서비스
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
@Service
public class ProjectService {

    private final ProjectRepository projectRepository;

    public ProjectService(ProjectRepository projectRepository) {
        this.projectRepository = projectRepository;
    }

    public List<Project> findAll() {
        return projectRepository.findAll();
    }

    public Project findById(Long id) {
        // 단건 조회
        return projectRepository.findById(id).orElseThrow(() -> new ProjectNotFoundException(id));
    }

    public Project create(String name, String description) {
        // 값 검증(도메인)
        if (name == null || name.isBlank()) {
            throw new ProjectValidationException(ProjectErrorCode.PROJECT_NAME_REQUIRED, "프로젝트명은 필수입니다.");
        }
        Project project = new Project(name, description);
        return projectRepository.save(project);
    }
}
