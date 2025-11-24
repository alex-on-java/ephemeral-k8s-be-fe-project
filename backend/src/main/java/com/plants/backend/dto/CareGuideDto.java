package com.plants.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO for plant care guide information.
 */
public record CareGuideDto(
    @NotBlank(message = "Watering information is required")
    @Size(max = 5000, message = "Watering information must not exceed 5000 characters")
    String watering,

    @NotBlank(message = "Light information is required")
    @Size(max = 5000, message = "Light information must not exceed 5000 characters")
    String light,

    @NotBlank(message = "Temperature information is required")
    @Size(max = 5000, message = "Temperature information must not exceed 5000 characters")
    String temperature,

    @NotBlank(message = "Humidity information is required")
    @Size(max = 5000, message = "Humidity information must not exceed 5000 characters")
    String humidity,

    @NotBlank(message = "Soil information is required")
    @Size(max = 5000, message = "Soil information must not exceed 5000 characters")
    String soil,

    @NotBlank(message = "Fertilizing information is required")
    @Size(max = 5000, message = "Fertilizing information must not exceed 5000 characters")
    String fertilizing
) {}
