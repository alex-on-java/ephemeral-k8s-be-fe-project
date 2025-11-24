// API Response Types matching backend structure

export interface PlantGroup {
  id: string;
  name: string;
  imageId: string;
}

export interface CareGuide {
  watering: string;
  light: string;
  temperature: string;
  humidity: string;
  soil: string;
  fertilizing: string;
}

export interface CommonIssue {
  issue: string;
  solution: string;
}

export interface Plant {
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
  commonIssues: CommonIssue[];
}

// API Error Response
export interface ApiError {
  message: string;
  status: number;
}
