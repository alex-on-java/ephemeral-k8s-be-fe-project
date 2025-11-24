package com.plants.backend.controller;

import com.plants.backend.dto.PlantGroupResponse;
import com.plants.backend.dto.PlantSummaryResponse;
import com.plants.backend.service.PlantGroupService;
import com.plants.backend.service.PlantService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Public REST controller for plant group operations.
 */
@RestController
@RequestMapping("/api/plant-groups")
@RequiredArgsConstructor
public class PublicPlantGroupController {

    private final PlantGroupService plantGroupService;
    private final PlantService plantService;

    /**
     * Get all plant groups.
     */
    @GetMapping
    public ResponseEntity<List<PlantGroupResponse>> getAllGroups() {
        List<PlantGroupResponse> groups = plantGroupService.getAllGroups();
        return ResponseEntity.ok(groups);
    }

    /**
     * Get plants by group ID.
     */
    @GetMapping("/{groupId}/plants")
    public ResponseEntity<List<PlantSummaryResponse>> getPlantsByGroup(@PathVariable String groupId) {
        List<PlantSummaryResponse> plants = plantService.getPlantsByGroup(groupId);
        return ResponseEntity.ok(plants);
    }
}