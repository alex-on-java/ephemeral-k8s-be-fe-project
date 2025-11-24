import { Card } from "@/components/ui/card";
import PlantImage from "@/components/PlantImage";

interface PlantGroupCardProps {
  name: string;
  imageId: string;
  onClick: () => void;
}

const PlantGroupCard = ({ name, imageId, onClick }: PlantGroupCardProps) => {
  return (
    <Card
      onClick={onClick}
      className="group cursor-pointer overflow-hidden border-border bg-card transition-all duration-300 hover:shadow-card-hover hover:scale-[1.02] animate-fade-in"
    >
      <div className="aspect-square overflow-hidden bg-muted">
        <PlantImage
          imageId={imageId}
          alt={name}
          className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
        />
      </div>
      <div className="p-6">
        <h3 className="text-xl font-semibold text-foreground group-hover:text-primary transition-colors">
          {name}
        </h3>
      </div>
    </Card>
  );
};

export default PlantGroupCard;
