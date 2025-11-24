package com.plants.backend.repository;

import com.plants.backend.entity.PlantGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository for PlantGroup entities.
 */
@Repository
public interface PlantGroupRepository extends JpaRepository<PlantGroup, String> {
}