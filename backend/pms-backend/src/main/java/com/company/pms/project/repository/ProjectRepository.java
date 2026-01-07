package com.company.pms.project.repository;

import com.company.pms.project.domain.Project;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Project 리포
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
public interface ProjectRepository extends JpaRepository<Project, Long> {
}
