package com.plants.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Embeddable component containing plant care instructions.
 * Maps to care_* columns in the plants table.
 */
@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CareGuide {

    @Column(name = "care_watering", columnDefinition = "TEXT")
    private String watering;

    @Column(name = "care_light", columnDefinition = "TEXT")
    private String light;

    @Column(name = "care_temperature", columnDefinition = "TEXT")
    private String temperature;

    @Column(name = "care_humidity", columnDefinition = "TEXT")
    private String humidity;

    @Column(name = "care_soil", columnDefinition = "TEXT")
    private String soil;

    @Column(name = "care_fertilizing", columnDefinition = "TEXT")
    private String fertilizing;
}
