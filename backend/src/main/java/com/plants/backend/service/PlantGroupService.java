package com.plants.backend.service;

import com.plants.backend.dto.CreatePlantGroupRequest;
import com.plants.backend.dto.PlantGroupResponse;
import com.plants.backend.dto.UpdatePlantGroupRequest;
import com.plants.backend.entity.PlantGroup;
import com.plants.backend.exception.ResourceNotFoundException;
import com.plants.backend.mapper.PlantGroupMapper;
import com.plants.backend.repository.ImageRepository;
import com.plants.backend.repository.PlantGroupRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Service for managing plant groups.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PlantGroupService {

    private final PlantGroupRepository plantGroupRepository;
    private final ImageRepository imageRepository;
    private final PlantGroupMapper plantGroupMapper;

    /**
     * Get all plant groups.
     */
    public List<PlantGroupResponse> getAllGroups() {
        return plantGroupRepository.findAll().stream()
                .map(plantGroupMapper::toResponse)
                .toList();
    }

    /**
     * Get a plant group by ID.
     */
    public PlantGroupResponse getGroupById(String id) {
        PlantGroup group = plantGroupRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Plant group not found with id: " + id));
        return plantGroupMapper.toResponse(group);
    }

    /**
     * Create a new plant group.
     */
    @Transactional
    public PlantGroupResponse createGroup(CreatePlantGroupRequest request) {
        // Check if ID already exists
        if (plantGroupRepository.existsById(request.id())) {
            throw new IllegalArgumentException("Plant group with id '" + request.id() + "' already exists");
        }

        // Validate image reference if provided
        if (request.imageId() != null && !request.imageId().isBlank()) {
            validateImageExists(request.imageId());
        }

        PlantGroup group = plantGroupMapper.toEntity(request);
        PlantGroup savedGroup = plantGroupRepository.save(group);
        return plantGroupMapper.toResponse(savedGroup);
    }

    /**
     * Update an existing plant group.
     */
    @Transactional
    public PlantGroupResponse updateGroup(String id, UpdatePlantGroupRequest request) {
        PlantGroup group = plantGroupRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Plant group not found with id: " + id));

        // Validate image reference if provided
        if (request.imageId() != null && !request.imageId().isBlank()) {
            validateImageExists(request.imageId());
        }

        plantGroupMapper.updateEntityFromRequest(request, group);
        PlantGroup updatedGroup = plantGroupRepository.save(group);
        return plantGroupMapper.toResponse(updatedGroup);
    }

    /**
     * Delete a plant group.
     */
    @Transactional
    public void deleteGroup(String id) {
        if (!plantGroupRepository.existsById(id)) {
            throw new ResourceNotFoundException("Plant group not found with id: " + id);
        }
        plantGroupRepository.deleteById(id);
    }

    /**
     * Validate that an image exists.
     */
    private void validateImageExists(String imageId) {
        if (!imageRepository.existsById(imageId)) {
            throw new ResourceNotFoundException("Image not found with id: " + imageId);
        }
    }
}