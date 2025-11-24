import { useState } from "react";
import { Plant } from "@/types/api";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ChevronLeft, ChevronRight, Droplets, Sun, Thermometer, Wind, Leaf, Sparkles, AlertCircle, Ruler, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";
import PlantImage from "@/components/PlantImage";

interface PlantDetailProps {
  plant: Plant;
}

const PlantDetail = ({ plant }: PlantDetailProps) => {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);

  const nextImage = () => {
    setCurrentImageIndex((prev) => (prev + 1) % plant.imageIds.length);
  };

  const prevImage = () => {
    setCurrentImageIndex((prev) => (prev - 1 + plant.imageIds.length) % plant.imageIds.length);
  };

  const careIcons: Record<string, any> = {
    watering: Droplets,
    light: Sun,
    temperature: Thermometer,
    humidity: Wind,
    soil: Leaf,
    fertilizing: Sparkles,
  };

  return (
    <div className="space-y-6 animate-scale-in">
      {/* Image Carousel */}
      <Card className="overflow-hidden bg-card shadow-card">
        <div className="relative aspect-[3/2] bg-muted">
          <PlantImage
            imageId={plant.imageIds[currentImageIndex]}
            alt={`${plant.name} - Image ${currentImageIndex + 1}`}
            className="h-full w-full object-cover"
          />
          {plant.imageIds.length > 1 && (
            <>
              <Button
                variant="secondary"
                size="icon"
                onClick={prevImage}
                className="absolute left-4 top-1/2 -translate-y-1/2 h-10 w-10 rounded-full shadow-lg"
              >
                <ChevronLeft className="h-5 w-5" />
              </Button>
              <Button
                variant="secondary"
                size="icon"
                onClick={nextImage}
                className="absolute right-4 top-1/2 -translate-y-1/2 h-10 w-10 rounded-full shadow-lg"
              >
                <ChevronRight className="h-5 w-5" />
              </Button>
              <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2">
                {plant.imageIds.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => setCurrentImageIndex(index)}
                    className={`h-2 w-2 rounded-full transition-all ${
                      index === currentImageIndex
                        ? "bg-primary w-6"
                        : "bg-primary/30 hover:bg-primary/50"
                    }`}
                  />
                ))}
              </div>
            </>
          )}
        </div>
      </Card>

      {/* Plant Header */}
      <div>
        <h2 className="text-3xl font-bold text-foreground mb-2">{plant.name}</h2>
        <p className="text-lg text-muted-foreground italic">{plant.scientificName}</p>
        <p className="mt-4 text-foreground leading-relaxed">{plant.description}</p>
      </div>

      {/* Quick Info */}
      <Card className="p-6 bg-secondary/50 border-border">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="flex items-center gap-3">
            <Ruler className="h-5 w-5 text-primary" />
            <div>
              <p className="text-sm text-muted-foreground">Size</p>
              <p className="font-medium text-foreground">{plant.size}</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <AlertTriangle className="h-5 w-5 text-primary" />
            <div>
              <p className="text-sm text-muted-foreground">Toxicity</p>
              <p className="font-medium text-foreground">{plant.toxicity}</p>
            </div>
          </div>
        </div>
      </Card>

      {/* Care Instructions */}
      <Card className="p-6 bg-card shadow-card">
        <h3 className="text-2xl font-semibold text-foreground mb-6 flex items-center gap-2">
          <Leaf className="h-6 w-6 text-primary" />
          Care Guide
        </h3>
        <div className="space-y-6">
          {Object.entries(plant.care).map(([key, value]) => {
            const Icon = careIcons[key];
            return (
              <div key={key} className="flex gap-4">
                <div className="flex-shrink-0 mt-1">
                  <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center">
                    <Icon className="h-5 w-5 text-primary" />
                  </div>
                </div>
                <div className="flex-1">
                  <h4 className="font-semibold text-foreground capitalize mb-2">{key}</h4>
                  <p className="text-muted-foreground leading-relaxed">{value}</p>
                </div>
              </div>
            );
          })}
        </div>
      </Card>

      {/* Benefits */}
      <Card className="p-6 bg-gradient-soft shadow-card">
        <h3 className="text-2xl font-semibold text-foreground mb-4 flex items-center gap-2">
          <Sparkles className="h-6 w-6 text-primary" />
          Benefits
        </h3>
        <ul className="space-y-3">
          {plant.benefits.map((benefit, index) => (
            <li key={index} className="flex items-start gap-3">
              <Badge variant="secondary" className="mt-1 h-6 w-6 p-0 flex items-center justify-center flex-shrink-0">
                ✓
              </Badge>
              <span className="text-foreground leading-relaxed">{benefit}</span>
            </li>
          ))}
        </ul>
      </Card>

      {/* Common Issues */}
      <Card className="p-6 bg-card shadow-card">
        <h3 className="text-2xl font-semibold text-foreground mb-6 flex items-center gap-2">
          <AlertCircle className="h-6 w-6 text-primary" />
          Common Issues & Solutions
        </h3>
        <div className="space-y-6">
          {plant.commonIssues.map((item, index) => (
            <div key={index} className="border-l-4 border-primary pl-4 py-2">
              <h4 className="font-semibold text-foreground mb-2">{item.issue}</h4>
              <p className="text-muted-foreground leading-relaxed">{item.solution}</p>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
};

export default PlantDetail;
