package com.plants.backend.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Request DTO for creating a new plant.
 */
public record CreatePlantRequest(
    @NotBlank(message = "Plant ID is required")
    @Size(max = 255, message = "Plant ID must not exceed 255 characters")
    String id,

    @NotBlank(message = "Group ID is required")
    @Size(max = 255, message = "Group ID must not exceed 255 characters")
    String groupId,

    @NotBlank(message = "Plant name is required")
    @Size(max = 255, message = "Plant name must not exceed 255 characters")
    String name,

    @NotBlank(message = "Scientific name is required")
    @Size(max = 255, message = "Scientific name must not exceed 255 characters")
    String scientificName,

    @NotBlank(message = "Thumbnail ID is required")
    @Size(max = 255, message = "Thumbnail ID must not exceed 255 characters")
    String thumbnailId,

    @NotEmpty(message = "At least one image is required")
    @Size(min = 1, max = 3, message = "Must have between 1 and 3 images")
    String[] imageIds,

    @NotBlank(message = "Description is required")
    @Size(max = 10000, message = "Description must not exceed 10000 characters")
    String description,

    @NotBlank(message = "Size information is required")
    @Size(max = 5000, message = "Size information must not exceed 5000 characters")
    String size,

    @NotBlank(message = "Toxicity information is required")
    @Size(max = 5000, message = "Toxicity information must not exceed 5000 characters")
    String toxicity,

    @NotEmpty(message = "At least one benefit is required")
    @Size(min = 4, max = 5, message = "Must have between 4 and 5 benefits")
    String[] benefits,

    @NotNull(message = "Care guide is required")
    @Valid
    CareGuideDto care,

    @NotEmpty(message = "At least one common issue is required")
    @Size(min = 2, max = 4, message = "Must have between 2 and 4 common issues")
    @Valid
    List<IssueDto> commonIssues
) {}
