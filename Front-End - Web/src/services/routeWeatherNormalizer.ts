export interface NormalizedWeatherCondition {
  text: string;
  icon: string;
  code?: number;
}

export interface NormalizedPlaceWeather {
  temperatureC: number;
  condition: NormalizedWeatherCondition;
  feelsLikeC?: number;
  humidity?: number;
  windSpeedKph?: number;
  windDirection?: number;
  rainProbability?: number;
  precipitationMm?: number;
  visibilityKm?: number;
  uvIndex?: number;
  pressureMb?: number;
  isStale?: boolean;
}

export interface NormalizedRoutePlace {
  name: string;
  type: 'source' | 'route_place' | 'destination';
  latitude: number;
  longitude: number;
  distanceFromStartKm: number;
  estimatedArrivalIso: string;
  weather: NormalizedPlaceWeather | null;
}

export interface NormalizedRouteAlert {
  type?: string;
  title?: string;
  place?: string;
  location?: string;
  startTime?: string;
  endTime?: string;
  severity?: string;
  description?: string;
  message?: string;
}

export interface NormalizedRouteSummary {
  sourceName: string;
  sourceLat: number;
  sourceLon: number;
  destinationName: string;
  destinationLat: number;
  destinationLon: number;
  distanceKm: number;
  durationMinutes: number;
  departureTimeIso: string;
  polyline?: string;
}

export interface NormalizedRouteWeatherResponse {
  success: boolean;
  route: NormalizedRouteSummary;
  places: NormalizedRoutePlace[];
  alerts: NormalizedRouteAlert[];
  
  overview: {
    totalWaypoints: number;
    totalAlerts: number;
    tempMin: number | null;
    tempMax: number | null;
    maxWindKph: number | null;
    minVisibilityKm: number | null;
    rainAlertsCount: number;
    waypointsWithWeather: number;
  };
  
  departureWeather: NormalizedPlaceWeather | null;
  arrivalWeather: NormalizedPlaceWeather | null;
}

// Normalize individual place weather object safely
export function normalizePlaceWeather(rawWeather: any): NormalizedPlaceWeather | null {
  if (!rawWeather || typeof rawWeather !== 'object') return null;

  const tempVal = rawWeather.temperature_c ?? rawWeather.temp_c;
  if (tempVal === undefined || tempVal === null || isNaN(Number(tempVal))) {
    return null;
  }
  const temperatureC = Math.round(Number(tempVal) * 10) / 10;

  let text = 'Clear';
  let icon = 'sun';
  let code: number | undefined = undefined;

  if (typeof rawWeather.condition === 'string') {
    text = rawWeather.condition;
  } else if (rawWeather.condition && typeof rawWeather.condition === 'object') {
    text = rawWeather.condition.text ?? rawWeather.condition.condition ?? 'Clear';
    icon = rawWeather.condition.icon ?? rawWeather.icon ?? 'sun';
    code = rawWeather.condition.code ?? rawWeather.weather_code;
  } else if (rawWeather.conditionText) {
    text = rawWeather.conditionText;
  }

  const feelsLikeVal = rawWeather.feelslike_c ?? rawWeather.feels_like_c ?? rawWeather.feelslike;
  const feelsLikeC = feelsLikeVal !== undefined && feelsLikeVal !== null && !isNaN(Number(feelsLikeVal))
    ? Math.round(Number(feelsLikeVal) * 10) / 10
    : undefined;

  const humidityVal = rawWeather.humidity;
  const humidity = humidityVal !== undefined && humidityVal !== null && !isNaN(Number(humidityVal))
    ? Math.round(Number(humidityVal))
    : undefined;

  const windVal = rawWeather.wind_speed_kph ?? rawWeather.wind_kph ?? rawWeather.windSpeed;
  const windSpeedKph = windVal !== undefined && windVal !== null && !isNaN(Number(windVal))
    ? Math.round(Number(windVal) * 10) / 10
    : undefined;

  const windDirVal = rawWeather.wind_direction ?? rawWeather.windDirection;
  const windDirection = windDirVal !== undefined && windDirVal !== null && !isNaN(Number(windDirVal))
    ? Math.round(Number(windDirVal))
    : undefined;

  const rainProbVal = rawWeather.rain_probability ?? rawWeather.rainProbability;
  const rainProbability = rainProbVal !== undefined && rainProbVal !== null && !isNaN(Number(rainProbVal))
    ? Math.round(Number(rainProbVal))
    : undefined;

  const precipVal = rawWeather.precipitation_mm ?? rawWeather.precip_mm ?? rawWeather.rainfall_mm;
  const precipitationMm = precipVal !== undefined && precipVal !== null && !isNaN(Number(precipVal))
    ? Math.round(Number(precipVal) * 10) / 10
    : undefined;

  const visVal = rawWeather.visibility_km ?? rawWeather.visibilityKm;
  const visibilityKm = visVal !== undefined && visVal !== null && !isNaN(Number(visVal))
    ? Math.round(Number(visVal) * 10) / 10
    : undefined;

  const uvVal = rawWeather.uv_index ?? rawWeather.uv;
  const uvIndex = uvVal !== undefined && uvVal !== null && !isNaN(Number(uvVal))
    ? Math.round(Number(uvVal) * 10) / 10
    : undefined;

  const pressureVal = rawWeather.pressure_mb ?? rawWeather.pressureMb;
  const pressureMb = pressureVal !== undefined && pressureVal !== null && !isNaN(Number(pressureVal))
    ? Math.round(Number(pressureVal))
    : undefined;

  const isStale = Boolean(rawWeather.is_stale ?? rawWeather.isStale ?? false);

  return {
    temperatureC,
    condition: { text, icon, code },
    feelsLikeC,
    humidity,
    windSpeedKph,
    windDirection,
    rainProbability,
    precipitationMm,
    visibilityKm,
    uvIndex,
    pressureMb,
    isStale
  };
}

// Master normalization function for raw API route response
export function transformRouteWeatherResponse(rawResponse: any): NormalizedRouteWeatherResponse | null {
  if (!rawResponse || typeof rawResponse !== 'object') return null;

  const routeRaw = rawResponse.route || {};
  const sourceRaw = routeRaw.source || {};
  const destRaw = routeRaw.destination || {};

  const route: NormalizedRouteSummary = {
    sourceName: sourceRaw.name || 'Source',
    sourceLat: Number(sourceRaw.latitude) || 0,
    sourceLon: Number(sourceRaw.longitude) || 0,
    destinationName: destRaw.name || 'Destination',
    destinationLat: Number(destRaw.latitude) || 0,
    destinationLon: Number(destRaw.longitude) || 0,
    distanceKm: Number(routeRaw.distance_km ?? routeRaw.distanceKm ?? 0),
    durationMinutes: Number(routeRaw.duration_minutes ?? routeRaw.durationMinutes ?? 0),
    departureTimeIso: routeRaw.departure_time ?? routeRaw.departureTime ?? new Date().toISOString(),
    polyline: routeRaw.polyline || ''
  };

  const rawPlaces = Array.isArray(rawResponse.places) ? rawResponse.places : [];
  const places: NormalizedRoutePlace[] = rawPlaces.map((p: any, idx: number) => {
    const isFirst = idx === 0 || p.type === 'source';
    const isLast = idx === rawPlaces.length - 1 || p.type === 'destination';

    return {
      name: p.name || `Waypoint ${idx + 1}`,
      type: isFirst ? 'source' : isLast ? 'destination' : 'route_place',
      latitude: Number(p.latitude) || 0,
      longitude: Number(p.longitude) || 0,
      distanceFromStartKm: Number(p.distance_from_start_km ?? p.distanceFromStartKm ?? 0),
      estimatedArrivalIso: p.estimated_arrival ?? p.estimatedArrival ?? route.departureTimeIso,
      weather: normalizePlaceWeather(p.weather)
    };
  });

  const rawAlerts = Array.isArray(rawResponse.alerts) ? rawResponse.alerts : [];
  const alerts: NormalizedRouteAlert[] = rawAlerts.map((a: any) => ({
    type: a.type,
    title: a.title ?? a.type ?? 'Route Warning',
    place: a.place ?? a.location,
    location: a.location ?? a.place,
    startTime: a.startTime ?? a.start_time,
    endTime: a.endTime ?? a.end_time,
    severity: a.severity ?? 'Warning',
    description: a.description ?? a.message ?? 'Weather alert along route corridor.',
    message: a.message ?? a.description
  }));

  let tempMin: number | null = null;
  let tempMax: number | null = null;
  let maxWindKph: number | null = null;
  let minVisibilityKm: number | null = null;
  let rainAlertsCount = alerts.length;
  let waypointsWithWeather = 0;

  for (const place of places) {
    if (place.weather) {
      waypointsWithWeather++;
      const t = place.weather.temperatureC;
      if (tempMin === null || t < tempMin) tempMin = t;
      if (tempMax === null || t > tempMax) tempMax = t;

      if (place.weather.windSpeedKph !== undefined) {
        const w = place.weather.windSpeedKph;
        if (maxWindKph === null || w > maxWindKph) maxWindKph = w;
      }

      if (place.weather.visibilityKm !== undefined) {
        const v = place.weather.visibilityKm;
        if (minVisibilityKm === null || v < minVisibilityKm) minVisibilityKm = v;
      }

      const condLower = place.weather.condition.text.toLowerCase();
      const prob = place.weather.rainProbability ?? 0;
      if (prob >= 50 || condLower.includes('rain') || condLower.includes('thunder') || condLower.includes('drizzle')) {
        rainAlertsCount++;
      }
    }
  }

  const sourcePlace = places.find(p => p.type === 'source') || places[0];
  const destPlace = places.find(p => p.type === 'destination') || places[places.length - 1];

  return {
    success: rawResponse.success ?? true,
    route,
    places,
    alerts,
    overview: {
      totalWaypoints: places.length,
      totalAlerts: alerts.length,
      tempMin,
      tempMax,
      maxWindKph,
      minVisibilityKm,
      rainAlertsCount,
      waypointsWithWeather
    },
    departureWeather: sourcePlace?.weather || null,
    arrivalWeather: destPlace?.weather || null
  };
}
