package com.plants.backend.repository;

import com.plants.backend.entity.Issue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for Issue entity operations.
 */
@Repository
public interface IssueRepository extends JpaRepository<Issue, Long> {

    /**
     * Find all issues for a specific plant.
     */
    List<Issue> findByPlantId(String plantId);
}
