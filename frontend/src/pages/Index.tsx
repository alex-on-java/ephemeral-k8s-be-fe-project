import { useState } from "react";
import { usePlantGroups, usePlantsByGroup, usePlant } from "@/hooks/usePlants";
import PlantGroupCard from "@/components/PlantGroupCard";
import PlantList from "@/components/PlantList";
import PlantDetail from "@/components/PlantDetail";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Leaf, AlertCircle } from "lucide-react";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";

const Index = () => {
  const [selectedGroupId, setSelectedGroupId] = useState<string | null>(null);
  const [selectedPlantId, setSelectedPlantId] = useState<string | null>(null);

  // Fetch data using React Query hooks
  const { data: plantGroups = [], isLoading: isLoadingGroups, error: groupsError } = usePlantGroups();
  const { data: groupPlants = [], isLoading: isLoadingPlants, error: plantsError } = usePlantsByGroup(selectedGroupId);
  const { data: selectedPlant, isLoading: isLoadingPlant, error: plantError } = usePlant(selectedPlantId);

  const selectedGroup = plantGroups.find((g) => g.id === selectedGroupId);

  const handleGroupClick = (groupId: string) => {
    setSelectedGroupId(groupId);
    setSelectedPlantId(null);
  };

  const handleBackToGroups = () => {
    setSelectedGroupId(null);
    setSelectedPlantId(null);
  };

  const handleBackToPlants = () => {
    setSelectedPlantId(null);
  };

  return (
    <div className="min-h-screen bg-gradient-soft">
      {/* Header */}
      <header className="border-b border-border bg-card/80 backdrop-blur-sm sticky top-0 z-10 shadow-sm">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center gap-3">
            <Leaf className="h-8 w-8 text-primary" />
            <h1 className="text-3xl font-bold text-foreground">Green Haven</h1>
          </div>
          <p className="text-muted-foreground mt-2">Your comprehensive plant care companion</p>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        {/* Home View - Plant Groups */}
        {!selectedGroupId && (
          <div>
            <h2 className="text-2xl font-semibold text-foreground mb-6">
              Explore Plant Collections
            </h2>

            {/* Error State */}
            {groupsError && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertTitle>Error</AlertTitle>
                <AlertDescription>
                  Failed to load plant groups. Please try again later.
                </AlertDescription>
              </Alert>
            )}

            {/* Loading State */}
            {isLoadingGroups && (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {[...Array(6)].map((_, i) => (
                  <div key={i} className="h-64 animate-pulse bg-muted rounded-lg" />
                ))}
              </div>
            )}

            {/* Plant Groups Grid */}
            {!isLoadingGroups && !groupsError && (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {plantGroups.map((group) => (
                  <PlantGroupCard
                    key={group.id}
                    name={group.name}
                    imageId={group.imageId}
                    onClick={() => handleGroupClick(group.id)}
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {/* Group View - Plants List + Detail */}
        {selectedGroupId && (
          <div>
            <Button
              variant="ghost"
              onClick={selectedPlantId ? handleBackToPlants : handleBackToGroups}
              className="mb-6 hover:bg-secondary"
            >
              <ArrowLeft className="mr-2 h-4 w-4" />
              {selectedPlantId ? "Back to Plants" : "Back to Collections"}
            </Button>

            <div className="flex flex-col lg:flex-row gap-6">
              {/* Plants List Sidebar */}
              <aside className="w-full lg:w-80 flex-shrink-0">
                <div className="sticky top-24">
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    {selectedGroup?.name}
                  </h2>

                  {/* Loading State for Plants List */}
                  {isLoadingPlants && (
                    <div className="space-y-3">
                      {[...Array(4)].map((_, i) => (
                        <div key={i} className="h-20 animate-pulse bg-muted rounded-lg" />
                      ))}
                    </div>
                  )}

                  {/* Error State for Plants List */}
                  {plantsError && (
                    <Alert variant="destructive">
                      <AlertCircle className="h-4 w-4" />
                      <AlertDescription>
                        Failed to load plants for this group.
                      </AlertDescription>
                    </Alert>
                  )}

                  {/* Plants List */}
                  {!isLoadingPlants && !plantsError && (
                    <>
                      {groupPlants.length > 0 ? (
                        <PlantList
                          plants={groupPlants}
                          selectedPlantId={selectedPlantId}
                          onSelectPlant={setSelectedPlantId}
                        />
                      ) : (
                        <p className="text-muted-foreground">No plants available in this collection yet.</p>
                      )}
                    </>
                  )}
                </div>
              </aside>

              {/* Plant Detail */}
              <div className="flex-1">
                {/* Loading State for Plant Detail */}
                {isLoadingPlant && selectedPlantId && (
                  <div className="space-y-4">
                    <div className="h-96 animate-pulse bg-muted rounded-lg" />
                    <div className="h-64 animate-pulse bg-muted rounded-lg" />
                  </div>
                )}

                {/* Error State for Plant Detail */}
                {plantError && selectedPlantId && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertTitle>Error</AlertTitle>
                    <AlertDescription>
                      Failed to load plant details. Please try again.
                    </AlertDescription>
                  </Alert>
                )}

                {/* Plant Detail Content */}
                {!isLoadingPlant && selectedPlant && (
                  <PlantDetail plant={selectedPlant} />
                )}

                {/* Empty State - No Plant Selected */}
                {!selectedPlantId && (
                  <div className="flex items-center justify-center h-96">
                    <div className="text-center">
                      <Leaf className="h-16 w-16 text-muted-foreground mx-auto mb-4 opacity-50" />
                      <p className="text-muted-foreground text-lg">
                        Select a plant to view detailed care information
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-border bg-card/80 backdrop-blur-sm mt-16">
        <div className="container mx-auto px-4 py-6">
          <p className="text-center text-muted-foreground text-sm">
            © 2025 Green Haven. Your trusted plant care resource.
          </p>
        </div>
      </footer>
    </div>
  );
};

export default Index;
