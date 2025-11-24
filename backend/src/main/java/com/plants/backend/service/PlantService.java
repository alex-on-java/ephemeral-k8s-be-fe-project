package com.plants.backend.service;

import com.plants.backend.dto.*;
import com.plants.backend.entity.Image;
import com.plants.backend.entity.Issue;
import com.plants.backend.entity.Plant;
import com.plants.backend.exception.ResourceNotFoundException;
import com.plants.backend.mapper.PlantMapper;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.IssueRepository;
import com.plants.backend.repository.PlantGroupRepository;
import com.plants.backend.repository.PlantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for plant operations with validation and business logic.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class PlantService {

    private final PlantRepository plantRepository;
    private final PlantGroupRepository plantGroupRepository;
    private final ImageRepository imageRepository;
    private final IssueRepository issueRepository;
    private final PlantMapper plantMapper;

    /**
     * Get all plants as summary responses.
     */
    @Transactional(readOnly = true)
    public List<PlantSummaryResponse> getAllPlants() {
        return plantRepository.findAll().stream()
                .map(plantMapper::toSummaryResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all plants belonging to a specific group.
     */
    @Transactional(readOnly = true)
    public List<PlantSummaryResponse> getPlantsByGroup(String groupId) {
        // Verify group exists
        if (!plantGroupRepository.existsById(groupId)) {
            throw new ResourceNotFoundException("Plant group not found: " + groupId);
        }

        return plantRepository.findByGroupId(groupId).stream()
                .map(plantMapper::toSummaryResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get complete plant details by ID.
     */
    @Transactional(readOnly = true)
    public PlantResponse getPlantById(String id) {
        Plant plant = plantRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Plant not found: " + id));
        return plantMapper.toResponse(plant);
    }

    /**
     * Create a new plant with validation.
     */
    public PlantResponse createPlant(CreatePlantRequest request) {
        // Check if plant ID already exists
        if (plantRepository.existsById(request.id())) {
            throw new IllegalArgumentException("Plant with ID '" + request.id() + "' already exists");
        }

        // Validate group exists
        if (!plantGroupRepository.existsById(request.groupId())) {
            throw new IllegalArgumentException("Plant group not found: " + request.groupId());
        }

        // Validate thumbnail exists
        if (!imageRepository.existsById(request.thumbnailId())) {
            throw new IllegalArgumentException("Thumbnail image not found: " + request.thumbnailId());
        }

        // Validate all image IDs exist
        for (String imageId : request.imageIds()) {
            if (!imageRepository.existsById(imageId)) {
                throw new IllegalArgumentException("Image not found: " + imageId);
            }
        }

        // Map request to entity
        Plant plant = plantMapper.toEntity(request);

        // Set up images relationship
        List<Image> images = Arrays.stream(request.imageIds())
                .map(id -> imageRepository.findById(id).orElseThrow())
                .collect(Collectors.toList());
        plant.setImages(images);

        // Set up issues relationship
        List<Issue> issues = request.commonIssues().stream()
                .map(dto -> {
                    Issue issue = plantMapper.toIssue(dto);
                    issue.setPlantId(request.id());
                    return issue;
                })
                .collect(Collectors.toList());
        plant.setCommonIssues(issues);

        // Save plant
        Plant savedPlant = plantRepository.save(plant);

        return plantMapper.toResponse(savedPlant);
    }

    /**
     * Update an existing plant.
     */
    public PlantResponse updatePlant(String id, UpdatePlantRequest request) {
        Plant plant = plantRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Plant not found: " + id));

        // Validate group exists
        if (!plantGroupRepository.existsById(request.groupId())) {
            throw new IllegalArgumentException("Plant group not found: " + request.groupId());
        }

        // Validate thumbnail exists
        if (!imageRepository.existsById(request.thumbnailId())) {
            throw new IllegalArgumentException("Thumbnail image not found: " + request.thumbnailId());
        }

        // Validate all image IDs exist
        for (String imageId : request.imageIds()) {
            if (!imageRepository.existsById(imageId)) {
                throw new IllegalArgumentException("Image not found: " + imageId);
            }
        }

        // Update basic fields
        plantMapper.updateEntityFromRequest(request, plant);

        // Update images relationship
        plant.getImages().clear();
        List<Image> newImages = Arrays.stream(request.imageIds())
                .map(imageId -> imageRepository.findById(imageId).orElseThrow())
                .collect(Collectors.toList());
        plant.getImages().addAll(newImages);

        // Update issues relationship (remove old, add new)
        plant.getCommonIssues().clear();
        List<Issue> newIssues = request.commonIssues().stream()
                .map(dto -> {
                    Issue issue = plantMapper.toIssue(dto);
                    issue.setPlantId(id);
                    return issue;
                })
                .collect(Collectors.toList());
        plant.getCommonIssues().addAll(newIssues);

        Plant updatedPlant = plantRepository.save(plant);
        return plantMapper.toResponse(updatedPlant);
    }

    /**
     * Delete a plant by ID.
     */
    public void deletePlant(String id) {
        if (!plantRepository.existsById(id)) {
            throw new ResourceNotFoundException("Plant not found: " + id);
        }
        plantRepository.deleteById(id);
    }
}
