package com.plants.backend.controller;

import com.plants.backend.dto.PlantResponse;
import com.plants.backend.service.PlantService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Public REST controller for plant operations.
 */
@RestController
@RequestMapping("/api/plants")
@RequiredArgsConstructor
public class PublicPlantController {

    private final PlantService plantService;

    /**
     * Get complete plant details by ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<PlantResponse> getPlantById(@PathVariable String id) {
        PlantResponse plant = plantService.getPlantById(id);
        return ResponseEntity.ok(plant);
    }
}
