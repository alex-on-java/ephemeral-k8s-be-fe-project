package com.plants.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.Array;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.ArrayList;
import java.util.List;

/**
 * Entity representing an individual plant species with care information.
 * Maps to the plants table.
 */
@Entity
@Table(name = "plants")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Plant {

    @Id
    @Column(nullable = false, unique = true, length = 255)
    private String id;

    @Column(name = "group_id", nullable = false, length = 255)
    private String groupId;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(name = "scientific_name", length = 255)
    private String scientificName;

    @Column(name = "thumbnail_id", length = 255)
    private String thumbnailId;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "TEXT")
    private String size;

    @Column(columnDefinition = "TEXT")
    private String toxicity;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(columnDefinition = "TEXT[]")
    private String[] benefits;

    @Embedded
    private CareGuide care;

    @OneToMany(mappedBy = "plant", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<Issue> commonIssues = new ArrayList<>();

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "plant_images",
        joinColumns = @JoinColumn(name = "plant_id"),
        inverseJoinColumns = @JoinColumn(name = "image_id")
    )
    @OrderColumn(name = "display_order")
    private List<Image> images = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", insertable = false, updatable = false)
    private PlantGroup group;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "thumbnail_id", insertable = false, updatable = false)
    private Image thumbnail;
}
