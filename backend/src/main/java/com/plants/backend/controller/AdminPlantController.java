package com.plants.backend.controller;

import com.plants.backend.dto.CreatePlantRequest;
import com.plants.backend.dto.PlantResponse;
import com.plants.backend.dto.PlantSummaryResponse;
import com.plants.backend.dto.UpdatePlantRequest;
import com.plants.backend.service.PlantService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin REST controller for plant CRUD operations.
 */
@RestController
@RequestMapping("/api/admin/plants")
@RequiredArgsConstructor
public class AdminPlantController {

    private final PlantService plantService;

    /**
     * Get all plants (summary view).
     */
    @GetMapping
    public ResponseEntity<List<PlantSummaryResponse>> getAllPlants() {
        List<PlantSummaryResponse> plants = plantService.getAllPlants();
        return ResponseEntity.ok(plants);
    }

    /**
     * Get specific plant by ID (full details).
     */
    @GetMapping("/{id}")
    public ResponseEntity<PlantResponse> getPlantById(@PathVariable String id) {
        PlantResponse plant = plantService.getPlantById(id);
        return ResponseEntity.ok(plant);
    }

    /**
     * Create new plant.
     */
    @PostMapping
    public ResponseEntity<PlantResponse> createPlant(@Valid @RequestBody CreatePlantRequest request) {
        PlantResponse created = plantService.createPlant(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * Update existing plant.
     */
    @PutMapping("/{id}")
    public ResponseEntity<PlantResponse> updatePlant(
            @PathVariable String id,
            @Valid @RequestBody UpdatePlantRequest request) {
        PlantResponse updated = plantService.updatePlant(id, request);
        return ResponseEntity.ok(updated);
    }

    /**
     * Delete plant.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlant(@PathVariable String id) {
        plantService.deletePlant(id);
        return ResponseEntity.noContent().build();
    }
}
