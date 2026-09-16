export type PusulaPdfSatellitePoint = {
  date: string;
  ndvi: number | null;
  ndmi: number | null;
  ndre: number | null;
  savi: number | null;
  gndvi: number | null;
  ndviImage: string | null;
  trueColorImage: string | null;
};

export type PusulaPdfSnapshot = {
  schemaVersion: 1;
  field: {
    id: string; name: string; city: string | null; district: string | null; village: string | null;
    areaDecare: number | null; crop: string | null; cropSubtype: string | null; season: number | null;
    irrigationStatus: string | null; irrigationMethod: string | null; geometry: unknown | null;
    latitude: number | null; longitude: number | null;
  };
  period: { start: string; end: string; createdAt: string };
  satellite: { points: PusulaPdfSatellitePoint[]; availableDates: string[] };
  weather: unknown | null;
  irrigation: { kcSnapshots: unknown[] };
  activities: unknown[];
  soilAnalyses: unknown[];
  diagnoses: unknown[];
  missing: string[];
};

export type WeeklyPusulaReport = {
  id: string; field_id: string; period_start: string; period_end: string;
  status: 'snapshot' | 'generating' | 'ready' | 'failed';
  report_data: PusulaPdfSnapshot; pdf_bucket: string | null; pdf_path: string | null; generated_at: string | null;
};
