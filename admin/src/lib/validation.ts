/**
 * Client-side validation utilities matching backend constraints.
 * These validators should be used before making API calls to provide
 * immediate feedback to users.
 */

// ============================================================================
// Validation Result Type
// ============================================================================

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

// ============================================================================
// Field Length Validators
// ============================================================================

/**
 * Validate string is not blank (not null, undefined, or empty after trim).
 */
export const isNotBlank = (value: string | null | undefined): boolean => {
  return value != null && value.trim().length > 0;
};

/**
 * Validate string length does not exceed maximum.
 */
export const maxLength = (
  value: string | null | undefined,
  max: number
): boolean => {
  if (!value) return true; // Empty is valid for maxLength check
  return value.length <= max;
};

/**
 * Validate array size is within min and max bounds.
 */
export const arraySize = (
  array: unknown[] | null | undefined,
  min?: number,
  max?: number
): boolean => {
  if (!array) return min === undefined || min === 0;
  const length = array.length;

  if (min !== undefined && length < min) return false;
  if (max !== undefined && length > max) return false;

  return true;
};

// ============================================================================
// ID Format Validators
// ============================================================================

/**
 * Validate plant group ID format.
 * Convention: lowercase single word (e.g., "succulents", "tropical")
 */
export const isValidGroupId = (id: string): boolean => {
  if (!isNotBlank(id)) return false;
  if (!maxLength(id, 100)) return false;

  // Allow lowercase letters and hyphens only
  return /^[a-z]+(-[a-z]+)*$/.test(id);
};

/**
 * Validate plant ID format.
 * Convention: lowercase hyphenated (e.g., "aloe-vera", "snake-plant")
 */
export const isValidPlantId = (id: string): boolean => {
  if (!isNotBlank(id)) return false;
  if (!maxLength(id, 255)) return false;

  // Allow lowercase letters and hyphens only
  return /^[a-z]+(-[a-z]+)*$/.test(id);
};

// ============================================================================
// Plant Group Validators
// ============================================================================

export const validatePlantGroupId = (id: string): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(id)) {
    errors.push('ID is required');
  } else if (!maxLength(id, 100)) {
    errors.push('ID must not exceed 100 characters');
  } else if (!isValidGroupId(id)) {
    errors.push('ID must be lowercase letters only (e.g., "succulents", "tropical")');
  }

  return { isValid: errors.length === 0, errors };
};

export const validatePlantGroupName = (name: string): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(name)) {
    errors.push('Name is required');
  } else if (!maxLength(name, 255)) {
    errors.push('Name must not exceed 255 characters');
  }

  return { isValid: errors.length === 0, errors };
};

// ============================================================================
// Plant Validators
// ============================================================================

export const validatePlantId = (id: string): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(id)) {
    errors.push('Plant ID is required');
  } else if (!maxLength(id, 255)) {
    errors.push('Plant ID must not exceed 255 characters');
  } else if (!isValidPlantId(id)) {
    errors.push('Plant ID must be lowercase hyphenated (e.g., "aloe-vera", "snake-plant")');
  }

  return { isValid: errors.length === 0, errors };
};

export const validatePlantName = (name: string): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(name)) {
    errors.push('Plant name is required');
  } else if (!maxLength(name, 255)) {
    errors.push('Plant name must not exceed 255 characters');
  }

  return { isValid: errors.length === 0, errors };
};

export const validateScientificName = (name: string): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(name)) {
    errors.push('Scientific name is required');
  } else if (!maxLength(name, 255)) {
    errors.push('Scientific name must not exceed 255 characters');
  }

  return { isValid: errors.length === 0, errors };
};

export const validateDescription = (description: string): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(description)) {
    errors.push('Description is required');
  } else if (!maxLength(description, 10000)) {
    errors.push('Description must not exceed 10,000 characters');
  }

  return { isValid: errors.length === 0, errors };
};

export const validateSizeInfo = (size: string): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(size)) {
    errors.push('Size information is required');
  } else if (!maxLength(size, 5000)) {
    errors.push('Size information must not exceed 5,000 characters');
  }

  return { isValid: errors.length === 0, errors };
};

export const validateToxicity = (toxicity: string): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(toxicity)) {
    errors.push('Toxicity information is required');
  } else if (!maxLength(toxicity, 5000)) {
    errors.push('Toxicity information must not exceed 5,000 characters');
  }

  return { isValid: errors.length === 0, errors };
};

export const validateBenefits = (benefits: string[]): ValidationResult => {
  const errors: string[] = [];

  if (!benefits || benefits.length === 0) {
    errors.push('At least one benefit is required');
  } else if (!arraySize(benefits, 4, 5)) {
    errors.push('Must have between 4 and 5 benefits');
  } else {
    // Check each benefit
    benefits.forEach((benefit, index) => {
      if (!isNotBlank(benefit)) {
        errors.push(`Benefit ${index + 1} cannot be empty`);
      }
    });
  }

  return { isValid: errors.length === 0, errors };
};

export const validateImageIds = (imageIds: string[]): ValidationResult => {
  const errors: string[] = [];

  if (!imageIds || imageIds.length === 0) {
    errors.push('At least one image is required');
  } else if (!arraySize(imageIds, 1, 3)) {
    errors.push('Must have between 1 and 3 images');
  } else {
    // Check each image ID
    imageIds.forEach((imageId, index) => {
      if (!isNotBlank(imageId)) {
        errors.push(`Image ${index + 1} ID cannot be empty`);
      }
    });
  }

  return { isValid: errors.length === 0, errors };
};

// ============================================================================
// Care Guide Validators
// ============================================================================

export const validateCareField = (
  fieldName: string,
  value: string
): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(value)) {
    errors.push(`${fieldName} is required`);
  } else if (!maxLength(value, 5000)) {
    errors.push(`${fieldName} must not exceed 5,000 characters`);
  }

  return { isValid: errors.length === 0, errors };
};

export const validateWatering = (value: string): ValidationResult =>
  validateCareField('Watering information', value);

export const validateLight = (value: string): ValidationResult =>
  validateCareField('Light information', value);

export const validateTemperature = (value: string): ValidationResult =>
  validateCareField('Temperature information', value);

export const validateHumidity = (value: string): ValidationResult =>
  validateCareField('Humidity information', value);

export const validateSoil = (value: string): ValidationResult =>
  validateCareField('Soil information', value);

export const validateFertilizing = (value: string): ValidationResult =>
  validateCareField('Fertilizing information', value);

// ============================================================================
// Common Issues Validators
// ============================================================================

export const validateIssue = (issue: string, index: number): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(issue)) {
    errors.push(`Issue ${index + 1} description is required`);
  } else if (!maxLength(issue, 5000)) {
    errors.push(`Issue ${index + 1} description must not exceed 5,000 characters`);
  }

  return { isValid: errors.length === 0, errors };
};

export const validateSolution = (solution: string, index: number): ValidationResult => {
  const errors: string[] = [];

  if (!isNotBlank(solution)) {
    errors.push(`Issue ${index + 1} solution is required`);
  } else if (!maxLength(solution, 5000)) {
    errors.push(`Issue ${index + 1} solution must not exceed 5,000 characters`);
  }

  return { isValid: errors.length === 0, errors };
};

export const validateCommonIssues = (
  issues: Array<{ issue: string; solution: string }>
): ValidationResult => {
  const errors: string[] = [];

  if (!issues || issues.length === 0) {
    errors.push('At least one common issue is required');
  } else if (!arraySize(issues, 2, 4)) {
    errors.push('Must have between 2 and 4 common issues');
  } else {
    // Validate each issue and solution
    issues.forEach((item, index) => {
      const issueResult = validateIssue(item.issue, index);
      const solutionResult = validateSolution(item.solution, index);

      errors.push(...issueResult.errors);
      errors.push(...solutionResult.errors);
    });
  }

  return { isValid: errors.length === 0, errors };
};

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Combine multiple validation results into one.
 */
export const combineValidationResults = (
  ...results: ValidationResult[]
): ValidationResult => {
  const allErrors = results.flatMap(r => r.errors);
  return {
    isValid: allErrors.length === 0,
    errors: allErrors,
  };
};

/**
 * Get character count display string.
 * Useful for showing "X / Y characters" in forms.
 */
export const getCharacterCount = (
  value: string | null | undefined,
  max: number
): string => {
  const count = value?.length || 0;
  return `${count} / ${max}`;
};
