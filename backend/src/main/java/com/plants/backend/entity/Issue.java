package com.plants.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Entity representing a common plant issue and its solution.
 * Maps to the plant_issues table.
 */
@Entity
@Table(name = "plant_issues")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Issue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "plant_id", nullable = false, length = 255)
    private String plantId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String issue;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String solution;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plant_id", insertable = false, updatable = false)
    private Plant plant;
}
