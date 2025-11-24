package com.plants.backend.controller;

import com.plants.backend.service.SeedService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.Map;

/**
 * Admin controller for database seeding operations.
 * Provides endpoints to populate and reset database with initial plant data.
 */
@RestController
@RequestMapping("/api/admin")
public class AdminSeedController {

    private final SeedService seedService;

    public AdminSeedController(SeedService seedService) {
        this.seedService = seedService;
    }

    /**
     * Seeds the database with initial plant data from fixtures.
     * Loads images and plant data from classpath resources.
     *
     * @return Success message
     */
    @PostMapping("/seed")
    public ResponseEntity<Map<String, String>> seedDatabase() {
        try {
            seedService.seedDatabase();
            return ResponseEntity.ok(Map.of("message", "Database seeded successfully"));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Failed to seed database: " + e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Unexpected error: " + e.getMessage()));
        }
    }

    /**
     * Resets the database by clearing all data and re-seeding with initial data.
     *
     * @return Success message
     */
    @PostMapping("/reset")
    public ResponseEntity<Map<String, String>> resetDatabase() {
        try {
            seedService.resetDatabase();
            return ResponseEntity.ok(Map.of("message", "Database reset and seeded successfully"));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Failed to reset database: " + e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Unexpected error: " + e.getMessage()));
        }
    }
}
