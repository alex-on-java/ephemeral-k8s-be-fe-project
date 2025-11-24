package com.plants.backend.controller;

import com.plants.backend.dto.ImageResponse;
import com.plants.backend.service.ImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/images")
@RequiredArgsConstructor
public class AdminImageController {

    private final ImageService imageService;

    @GetMapping
    public ResponseEntity<List<ImageResponse>> getAllImages() {
        List<ImageResponse> images = imageService.getAllImages();
        return ResponseEntity.ok(images);
    }

    @PostMapping
    public ResponseEntity<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) {
        ImageResponse response = imageService.uploadImage(file);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(Map.of("imageId", response.id()));
    }
}
