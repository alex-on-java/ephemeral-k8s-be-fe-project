package com.plants.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request DTO for creating a new plant group.
 */
public record CreatePlantGroupRequest(
    @NotBlank(message = "ID is required")
    @Size(max = 100, message = "ID must not exceed 100 characters")
    String id,

    @NotBlank(message = "Name is required")
    @Size(max = 255, message = "Name must not exceed 255 characters")
    String name,

    String imageId
) {}