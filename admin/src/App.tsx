import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Toaster } from "@/components/ui/sonner";
import { Layout } from "@/components/Layout";
import PlantGroups from "./pages/PlantGroups";
import Plants from "./pages/Plants";
import Images from "./pages/Images";
import "./App.css";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Navigate to="/plant-groups" replace />} />
          <Route path="/plant-groups" element={<PlantGroups />} />
          <Route path="/plants" element={<Plants />} />
          <Route path="/images" element={<Images />} />
        </Routes>
      </Layout>
      <Toaster />
    </BrowserRouter>
  </QueryClientProvider>
);

export default App;
