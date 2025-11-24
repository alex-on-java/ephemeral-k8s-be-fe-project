package com.plants.backend.dto;

/**
 * Response DTO for plant group information.
 */
public record PlantGroupResponse(
    String id,
    String name,
    String imageId
) {}