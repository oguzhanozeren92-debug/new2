import { useRef, useState } from 'react';
import { analyzeFieldSatellite } from '../../../lib/satelliteService';
import type { Field, FieldSatelliteState } from '../../../types';
import {
  readFieldMapLayerCache,
  writeFieldMapLayerCache,
} from '../../home-map/services/fieldMapLayerCache';

const SATELLITE_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const SATELLITE_CACHE_NAMESPACE = 'satellite-analysis-v2';
const SATELLITE_INFLIGHT = new Map<string, Promise<void>>();

export function useFieldSatellite() {
  const [satelliteByField, setSatelliteByField] = useState<
    Record<string, FieldSatelliteState>
  >({});

  const stateRef = useRef(satelliteByField);
  stateRef.current = satelliteByField;

  const loadFieldSatellite = async (field: Field, force = false) => {
    const key = String(field.id);
    const currentState = stateRef.current[key];

    if (currentState?.status === 'loading') return;
    if (!force && currentState?.status === 'ready') return;

    const existingRequest = SATELLITE_INFLIGHT.get(key);
    if (existingRequest) {
      await existingRequest;
      return;
    }

    if (!field.parcelGeometry) {
      setSatelliteByField((current) => ({
        ...current,
        [key]: {
          status: 'error',
          message: 'Uydu analizi için önce gerçek ada/parsel sınırı bulunmalı.',
        },
      }));
      return;
    }

    const request = (async () => {
      if (!force) {
        const cached = await readFieldMapLayerCache<any>(
          key,
          SATELLITE_CACHE_NAMESPACE,
          `${key}:latest`,
          SATELLITE_CACHE_TTL_MS,
        );

        if (cached?.success && cached?.ndviImage) {
          setSatelliteByField((current) => ({
            ...current,
            [key]: {
              status: 'ready',
              data: cached,
            },
          }));
          return;
        }
      }

      setSatelliteByField((current) => ({
        ...current,
        [key]: {
          status: 'loading',
          data: current[key]?.data,
        },
      }));

      try {
        const data = await analyzeFieldSatellite(field.parcelGeometry);

        setSatelliteByField((current) => ({
          ...current,
          [key]: { status: 'ready', data },
        }));

        void writeFieldMapLayerCache(
          key,
          SATELLITE_CACHE_NAMESPACE,
          `${key}:latest`,
          data,
          SATELLITE_CACHE_TTL_MS,
        );
      } catch (error) {
        setSatelliteByField((current) => ({
          ...current,
          [key]: {
            status: 'error',
            data: current[key]?.data,
            message:
              error instanceof Error
                ? error.message
                : 'Uydu analizi yüklenemedi.',
          },
        }));
      }
    })();

    SATELLITE_INFLIGHT.set(key, request);

    try {
      await request;
    } finally {
      SATELLITE_INFLIGHT.delete(key);
    }
  };

  return { satelliteByField, loadFieldSatellite };
}
