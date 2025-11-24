-- Initial schema for plants backend

-- Images table
CREATE TABLE images (
    id VARCHAR(255) PRIMARY KEY,
    filename VARCHAR(500) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    bytes BYTEA NOT NULL,
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Plant groups table
CREATE TABLE plant_groups (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    image_id VARCHAR(255),
    CONSTRAINT fk_plant_group_image FOREIGN KEY (image_id) REFERENCES images(id)
);

-- Plants table
CREATE TABLE plants (
    id VARCHAR(255) PRIMARY KEY,
    group_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    scientific_name VARCHAR(255) NOT NULL,
    thumbnail_id VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    size TEXT NOT NULL,
    toxicity TEXT NOT NULL,
    benefits TEXT[] NOT NULL, -- Array of text for benefits
    care_watering TEXT NOT NULL,
    care_light TEXT NOT NULL,
    care_temperature TEXT NOT NULL,
    care_humidity TEXT NOT NULL,
    care_soil TEXT NOT NULL,
    care_fertilizing TEXT NOT NULL,
    CONSTRAINT fk_plant_group FOREIGN KEY (group_id) REFERENCES plant_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_plant_thumbnail FOREIGN KEY (thumbnail_id) REFERENCES images(id)
);

-- Plant images junction table (many-to-many)
CREATE TABLE plant_images (
    plant_id VARCHAR(255) NOT NULL,
    image_id VARCHAR(255) NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (plant_id, image_id),
    CONSTRAINT fk_plant_images_plant FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE,
    CONSTRAINT fk_plant_images_image FOREIGN KEY (image_id) REFERENCES images(id) ON DELETE CASCADE
);

-- Common issues table
CREATE TABLE plant_issues (
    id BIGSERIAL PRIMARY KEY,
    plant_id VARCHAR(255) NOT NULL,
    issue TEXT NOT NULL,
    solution TEXT NOT NULL,
    CONSTRAINT fk_plant_issue FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
);

-- Indexes for common queries
CREATE INDEX idx_plants_group_id ON plants(group_id);
CREATE INDEX idx_plant_issues_plant_id ON plant_issues(plant_id);
CREATE INDEX idx_plant_images_plant_id ON plant_images(plant_id);
