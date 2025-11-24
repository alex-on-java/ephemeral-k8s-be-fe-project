package com.plants.backend.repository;

import com.plants.backend.entity.Plant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for Plant entity operations.
 */
@Repository
public interface PlantRepository extends JpaRepository<Plant, String> {

    /**
     * Find all plants belonging to a specific plant group.
     */
    List<Plant> findByGroupId(String groupId);
}
