package com.plants.backend.controller;

import com.plants.backend.dto.CreatePlantGroupRequest;
import com.plants.backend.dto.PlantGroupResponse;
import com.plants.backend.dto.UpdatePlantGroupRequest;
import com.plants.backend.service.PlantGroupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin REST controller for plant group management.
 */
@RestController
@RequestMapping("/api/admin/plant-groups")
@RequiredArgsConstructor
public class AdminPlantGroupController {

    private final PlantGroupService plantGroupService;

    /**
     * Get all plant groups.
     */
    @GetMapping
    public ResponseEntity<List<PlantGroupResponse>> getAllGroups() {
        List<PlantGroupResponse> groups = plantGroupService.getAllGroups();
        return ResponseEntity.ok(groups);
    }

    /**
     * Get a specific plant group by ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<PlantGroupResponse> getGroupById(@PathVariable String id) {
        PlantGroupResponse group = plantGroupService.getGroupById(id);
        return ResponseEntity.ok(group);
    }

    /**
     * Create a new plant group.
     */
    @PostMapping
    public ResponseEntity<PlantGroupResponse> createGroup(@Valid @RequestBody CreatePlantGroupRequest request) {
        PlantGroupResponse group = plantGroupService.createGroup(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(group);
    }

    /**
     * Update an existing plant group.
     */
    @PutMapping("/{id}")
    public ResponseEntity<PlantGroupResponse> updateGroup(
            @PathVariable String id,
            @Valid @RequestBody UpdatePlantGroupRequest request) {
        PlantGroupResponse group = plantGroupService.updateGroup(id, request);
        return ResponseEntity.ok(group);
    }

    /**
     * Delete a plant group.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteGroup(@PathVariable String id) {
        plantGroupService.deleteGroup(id);
        return ResponseEntity.noContent().build();
    }
}