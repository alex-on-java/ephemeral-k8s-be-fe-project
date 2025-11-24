/**
 * TypeScript type definitions for API requests and responses.
 * These types mirror the backend Java DTOs exactly.
 */

// ============================================================================
// Response Types
// ============================================================================

/**
 * Plant group response (read operations).
 */
export interface PlantGroupResponse {
  id: string;
  name: string;
  imageId: string | null;
}

/**
 * Plant summary response (list view).
 * Lightweight response without detailed care instructions.
 */
export interface PlantSummaryResponse {
  id: string;
  name: string;
  scientificName: string;
  thumbnailId: string;
}

/**
 * Complete plant response (detail view).
 */
export interface PlantResponse {
  id: string;
  groupId: string;
  name: string;
  scientificName: string;
  thumbnailId: string;
  imageIds: string[]; // Backend uses String[] - matches Java array
  description: string;
  size: string;
  toxicity: string;
  benefits: string[]; // Backend uses String[] - matches Java array
  care: CareGuide;
  commonIssues: Issue[]; // Backend uses List<IssueDto>
}

/**
 * Care guide details.
 * All fields required, max 5000 characters each.
 */
export interface CareGuide {
  watering: string;
  light: string;
  temperature: string;
  humidity: string;
  soil: string;
  fertilizing: string;
}

/**
 * Plant issue with solution.
 * Both fields required, max 5000 characters each.
 */
export interface Issue {
  issue: string;
  solution: string;
}

/**
 * Image response.
 */
export interface ImageResponse {
  id: string;
  filename: string;
  contentType: string;
  createdDate: string; // ISO 8601 datetime string from Java LocalDateTime
}

/**
 * Upload image response (simplified).
 */
export interface UploadImageResponse {
  imageId: string;
}

// ============================================================================
// Request Types
// ============================================================================

/**
 * Create plant group request.
 *
 * Validation:
 * - id: required, max 100 characters
 * - name: required, max 255 characters
 * - imageId: optional
 */
export interface CreatePlantGroupRequest {
  id: string;
  name: string;
  imageId?: string | null;
}

/**
 * Update plant group request.
 * Note: ID cannot be changed (not included).
 *
 * Validation:
 * - name: required, max 255 characters
 * - imageId: optional
 */
export interface UpdatePlantGroupRequest {
  name: string;
  imageId?: string | null;
}

/**
 * Create plant request.
 *
 * Validation:
 * - id: required, max 255 characters
 * - groupId: required, max 255 characters
 * - name: required, max 255 characters
 * - scientificName: required, max 255 characters
 * - thumbnailId: required, max 255 characters
 * - imageIds: required, min 1, max 3 items
 * - description: required, max 10000 characters
 * - size: required, max 5000 characters
 * - toxicity: required, max 5000 characters
 * - benefits: required, min 4, max 5 items
 * - care: required, all 6 fields required (max 5000 each)
 * - commonIssues: required, min 2, max 4 items
 */
export interface CreatePlantRequest {
  id: string;
  groupId: string;
  name: string;
  scientificName: string;
  thumbnailId: string;
  imageIds: string[];
  description: string;
  size: string;
  toxicity: string;
  benefits: string[];
  care: CareGuide;
  commonIssues: Issue[];
}

/**
 * Update plant request.
 * Note: ID cannot be changed (not included).
 *
 * Same validation as CreatePlantRequest except for id field.
 */
export interface UpdatePlantRequest {
  groupId: string;
  name: string;
  scientificName: string;
  thumbnailId: string;
  imageIds: string[];
  description: string;
  size: string;
  toxicity: string;
  benefits: string[];
  care: CareGuide;
  commonIssues: Issue[];
}

// ============================================================================
// Error Response Types
// ============================================================================

/**
 * Validation error for a specific field.
 */
export interface ValidationError {
  field: string;
  message: string;
}

/**
 * Error response from backend.
 * Returned for 400/404/500 errors.
 */
export interface ErrorResponse {
  timestamp: string; // ISO 8601 datetime string from Java Instant
  status: number;
  error: string;
  message: string;
  path: string;
  validationErrors?: ValidationError[];
}

// ============================================================================
// Utility Types
// ============================================================================

/**
 * API error with parsed error response.
 */
export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public errorResponse?: ErrorResponse
  ) {
    super(message);
    this.name = 'ApiError';
  }
}
