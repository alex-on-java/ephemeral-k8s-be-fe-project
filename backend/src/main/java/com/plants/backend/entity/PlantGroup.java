package com.plants.backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Entity representing a plant group/category.
 */
@Entity
@Table(name = "plant_groups")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PlantGroup {

    @Id
    @Column(nullable = false, unique = true, length = 100)
    private String id;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(name = "image_id", length = 100)
    private String imageId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "image_id", insertable = false, updatable = false)
    private Image image;
}