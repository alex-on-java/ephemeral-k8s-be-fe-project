package com.plants.backend.controller;

import com.plants.backend.BaseIntegrationTest;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.repository.PlantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for AdminSeedController.
 * Tests seed and reset endpoints.
 */
class AdminSeedControllerTest extends BaseIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ImageRepository imageRepository;

    @Autowired
    private PlantGroupRepository plantGroupRepository;

    @Autowired
    private PlantRepository plantRepository;

    @BeforeEach
    void setUp() {
        // Clean database before each test
        plantRepository.deleteAll();
        plantGroupRepository.deleteAll();
        imageRepository.deleteAll();
    }

    @Test
    void postSeed_shouldReturn200AndPopulateDatabase() {
        // When
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/admin/seed",
            null,
            Map.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("message")).isEqualTo("Database seeded successfully");

        // Verify database was populated
        assertThat(imageRepository.count()).isGreaterThan(0);
        assertThat(plantGroupRepository.count()).isEqualTo(6);
        assertThat(plantRepository.count()).isEqualTo(4);
    }

    @Test
    void postReset_shouldReturn200AndRepopulateDatabase() {
        // Given - seed database first
        restTemplate.postForEntity("/api/admin/seed", null, Map.class);

        // Verify data exists
        assertThat(plantRepository.count()).isGreaterThan(0);

        // When - reset database
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/admin/reset",
            null,
            Map.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("message")).isEqualTo("Database reset and seeded successfully");

        // Verify database still has data (cleared and re-seeded)
        assertThat(imageRepository.count()).isGreaterThan(0);
        assertThat(plantGroupRepository.count()).isEqualTo(6);
        assertThat(plantRepository.count()).isEqualTo(4);
    }

    @Test
    void postSeed_shouldReturnSuccessMessage() {
        // When
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/admin/seed",
            null,
            Map.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).containsKey("message");
        assertThat(response.getBody().get("message")).isNotNull();
    }

    @Test
    void postSeed_canBeCalledMultipleTimes() {
        // First seed
        ResponseEntity<Map> response1 = restTemplate.postForEntity(
            "/api/admin/seed",
            null,
            Map.class
        );
        assertThat(response1.getStatusCode()).isEqualTo(HttpStatus.OK);

        long firstImageCount = imageRepository.count();
        long firstGroupCount = plantGroupRepository.count();
        long firstPlantCount = plantRepository.count();

        // Second seed (should add more data or handle duplicates gracefully)
        ResponseEntity<Map> response2 = restTemplate.postForEntity(
            "/api/admin/seed",
            null,
            Map.class
        );
        assertThat(response2.getStatusCode()).isEqualTo(HttpStatus.OK);

        // Note: Second seed will create duplicate entries (no unique constraints besides IDs)
        // This is acceptable behavior for a seed endpoint
        long secondImageCount = imageRepository.count();
        long secondGroupCount = plantGroupRepository.count();
        long secondPlantCount = plantRepository.count();

        assertThat(secondImageCount).isGreaterThanOrEqualTo(firstImageCount);
        assertThat(secondGroupCount).isGreaterThanOrEqualTo(firstGroupCount);
        assertThat(secondPlantCount).isGreaterThanOrEqualTo(firstPlantCount);
    }
}
