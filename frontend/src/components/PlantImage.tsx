import { useState } from "react";
import { getImageUrl } from "@/lib/api";
import { Leaf } from "lucide-react";

interface PlantImageProps {
  imageId: string;
  alt: string;
  className?: string;
}

export const PlantImage = ({ imageId, alt, className = "" }: PlantImageProps) => {
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  const imageUrl = getImageUrl(imageId);

  if (hasError) {
    return (
      <div
        className={`flex items-center justify-center bg-muted ${className}`}
        aria-label={`Failed to load image: ${alt}`}
      >
        <Leaf className="h-12 w-12 text-muted-foreground opacity-50" />
      </div>
    );
  }

  return (
    <>
      {isLoading && (
        <div
          className={`animate-pulse bg-muted ${className}`}
          aria-label="Loading image"
        />
      )}
      <img
        src={imageUrl}
        alt={alt}
        className={`${className} ${isLoading ? "hidden" : "block"}`}
        onLoad={() => setIsLoading(false)}
        onError={() => {
          setIsLoading(false);
          setHasError(true);
        }}
      />
    </>
  );
};

export default PlantImage;
