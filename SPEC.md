# Plant Care Guide - Data Specification

## Entities

### PlantGroup

Categories for organizing plants.

| Field   | Type   | Required | Notes              |
|---------|--------|----------|--------------------|
| id      | string | yes      | Unique identifier  |
| name    | string | yes      | Display name       |
| imageId | string | no       | Reference to Image |

### Plant

Individual plant species with care information.

| Field          | Type     | Required | Notes                       |
|----------------|----------|----------|-----------------------------|
| id             | string   | yes      | Unique identifier           |
| groupId        | string   | yes      | Reference to PlantGroup     |
| name           | string   | yes      | Common name                 |
| scientificName | string   | yes      | Latin name                  |
| thumbnailId    | string   | yes      | Reference to Image          |
| imageIds       | string[] | yes      | References to Images (1-3)  |
| description    | text      | yes      | Multi-paragraph description |
| size           | string    | yes      | Mature size description     |
| toxicity       | string    | yes      | Safety information          |
| benefits       | string[]  | yes      | 4-5 benefit statements      |
| care           | CareGuide | yes      | Embedded care object        |
| commonIssues   | Issue[]   | yes      | 2-4 issue/solution pairs    |

### CareGuide (embedded in Plant)

Detailed growing instructions.

| Field       | Type | Required |
|-------------|------|----------|
| watering    | text | yes      |
| light       | text | yes      |
| temperature | text | yes      |
| humidity    | text | yes      |
| soil        | text | yes      |
| fertilizing | text | yes      |

### Issue (entity related to Plant)

Common problems and solutions stored in separate table with auto-generated ID.

| Field    | Type   | Required | Notes                      |
|----------|--------|----------|----------------------------|
| id       | long   | yes      | Auto-generated (BIGSERIAL) |
| plantId  | string | yes      | Reference to Plant         |
| issue    | string | yes      | Problem description        |
| solution | text   | yes      | Solution description       |

### Image

Plant and group images stored as binary data.

| Field       | Type      | Required | Notes                           |
|-------------|-----------|----------|---------------------------------|
| id          | string    | yes      | Unique identifier               |
| bytes       | binary    | yes      | Image data (lazy-loaded)        |
| contentType | string    | yes      | MIME type (image/jpeg, etc.)    |
| filename    | string    | yes      | Original filename               |
| createdDate | timestamp | yes      | Upload timestamp                |

## Relationships

```
PlantGroup (1) ──< (N) Plant
PlantGroup (N) ──> (1) Image (cover image)
Plant (N) ──> (1) Image (thumbnail)
Plant (N) ──< (N) Image (detail images)
```

- Each Plant belongs to exactly one PlantGroup
- Each PlantGroup can have multiple Plants
- Each PlantGroup references one Image for cover
- Each Plant references one Image for thumbnail
- Each Plant references 1-3 Images for details
- Images can be shared across entities


