import { Plant } from "@/types/api";
import { Card } from "@/components/ui/card";
import PlantImage from "@/components/PlantImage";

interface PlantListProps {
  plants: Plant[];
  selectedPlantId: string | null;
  onSelectPlant: (plantId: string) => void;
}

const PlantList = ({ plants, selectedPlantId, onSelectPlant }: PlantListProps) => {
  return (
    <div className="space-y-3">
      {plants.map((plant) => (
        <Card
          key={plant.id}
          onClick={() => onSelectPlant(plant.id)}
          className={`group cursor-pointer overflow-hidden transition-all duration-200 hover:shadow-card-hover ${
            selectedPlantId === plant.id
              ? "ring-2 ring-primary bg-secondary"
              : "bg-card hover:bg-secondary/50"
          }`}
        >
          <div className="flex items-center gap-4 p-3">
            <div className="h-16 w-16 flex-shrink-0 overflow-hidden rounded-md bg-muted">
              <PlantImage
                imageId={plant.thumbnailId}
                alt={plant.name}
                className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
              />
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="font-medium text-foreground truncate group-hover:text-primary transition-colors">
                {plant.name}
              </h4>
              <p className="text-sm text-muted-foreground italic truncate">
                {plant.scientificName}
              </p>
            </div>
          </div>
        </Card>
      ))}
    </div>
  );
};

export default PlantList;
