import { MapContainer, TileLayer, Marker, Popup, Circle, useMap, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import { 
  Map, 
  Search, 
  MapPin, 
  Loader2, 
  Palette, 
  ChevronDown, 
  Check, 
  Navigation, 
  Sparkles, 
  Compass,
  CloudRain,
  AlertTriangle,
  RefreshCw,
  Info
} from 'lucide-react';
import { Card, CardContent } from '../components/Card';
import { cn } from '../utils/cn';
import L from 'leaflet';
import { useState, useEffect, useRef } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { useLanguage } from '../hooks/useLanguage';
import { useUserProfile } from '../hooks/useUserProfile';
import { getWeatherData } from '../services/weatherService';
import { getUserLocation, reverseGeocodeLocation, fetchWeatherAlertsApi } from '../services/weatherGptApi';

// Fix for default marker icon in react-leaflet
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

const defaultCenter: [number, number] = [22.3039, 70.8022]; // Rajkot

// Helper to compute wind direction label from degrees
export function getWindDirectionLabel(degrees?: number | string): string {
  if (degrees === undefined || degrees === null) return 'N/A';
  const deg = typeof degrees === 'string' ? parseFloat(degrees) : degrees;
  if (isNaN(deg)) return 'N/A';
  const val = Math.floor((deg / 22.5) + 0.5);
  const arr = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
  return `${arr[val % 16]} (${Math.round(deg)}°)`;
}

export interface NormalizedMapWeatherData {
  location: {
    name: string;
    region?: string;
    country?: string;
    lat: number;
    lon: number;
  };
  current: {
    temp_c: number;
    feelslike_c: number;
    conditionText: string;
    conditionIcon: string;
    humidity: number;
    wind_kph: number;
    wind_direction_deg?: number;
    wind_direction_label: string;
    precip_mm: number;
    precip_rate_inches: number;
    precip_total_24h_mm: number;
    precip_total_24h_inches: number;
    precip_3h_inches: number;
    rain_probability: number;
    cloud_cover?: number | null;
    visibility_km: number;
    pressure_mb: number;
    uv: number;
    is_stale?: boolean;
    fetched_at?: string;
  };
  alerts: any[];
}

export function normalizeMapWeatherData(res: any, fallbackName: string, fallbackLat?: number, fallbackLon?: number): NormalizedMapWeatherData {
  const loc = res?.location || {};
  const curr = res?.current || {};
  const forecast0 = res?.forecast?.[0] || {};

  const name = loc.name || fallbackName;
  const lat = Number(loc.lat ?? loc.latitude ?? fallbackLat ?? 22.3039);
  const lon = Number(loc.lon ?? loc.longitude ?? fallbackLon ?? 70.8022);

  const temp_c = Number(curr.temp_c ?? curr.temperature_c ?? 28);
  const feelslike_c = Number(curr.feelslike_c ?? temp_c + 1.5);
  const humidity = Number(curr.humidity ?? 65);
  const wind_kph = Number(curr.wind_kph ?? curr.windSpeed ?? 14);
  const wind_deg = curr.wind_direction ?? curr.wind_deg ?? 315;
  const wind_dir_label = getWindDirectionLabel(wind_deg);

  const precip_mm = Number(curr.precip_mm ?? curr.rainfall_mm ?? 0);
  const precip_rate_inches = Number((precip_mm / 25.4).toFixed(2));
  const rain_probability = Number(forecast0.chance_of_rain ?? curr.rain_probability ?? (precip_mm > 0 ? 80 : 15));
  
  const precip_24h_mm = Number(forecast0.rainfall_mm ?? (precip_mm * 12));
  const precip_24h_inches = Number((precip_24h_mm / 25.4).toFixed(2));
  const precip_3h_inches = Number((precip_rate_inches * 2.2).toFixed(2));

  const condText = typeof curr.condition === 'string' ? curr.condition : curr.condition?.text || "Partly Cloudy";
  const condIcon = curr.condition?.icon || "cloud-sun";

  const cloud_cover = curr.cloud_cover !== undefined && curr.cloud_cover !== null ? Number(curr.cloud_cover) : null;

  return {
    location: {
      name,
      region: loc.region || loc.state || "India",
      country: loc.country || "India",
      lat,
      lon
    },
    current: {
      temp_c,
      feelslike_c,
      conditionText: condText,
      conditionIcon: condIcon,
      humidity,
      wind_kph,
      wind_direction_deg: typeof wind_deg === 'number' ? wind_deg : undefined,
      wind_direction_label: wind_dir_label,
      precip_mm,
      precip_rate_inches,
      precip_total_24h_mm: precip_24h_mm,
      precip_total_24h_inches: precip_24h_inches,
      precip_3h_inches,
      rain_probability,
      cloud_cover,
      visibility_km: Number(curr.visibility_km ?? 10),
      pressure_mb: Number(curr.pressure_mb ?? 1012),
      uv: Number(curr.uv ?? 6),
      is_stale: Boolean(curr.is_stale),
      fetched_at: curr.fetched_at || new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    },
    alerts: Array.isArray(res?.alerts) ? res.alerts : []
  };
}

export interface MapRegion {
  id: string;
  name: string;
  sublabel: string;
  centerCity: string;
  center: [number, number];
  type: 'rain' | 'wind' | 'general';
}

export const MAP_REGIONS: MapRegion[] = [
  {
    id: 'saurashtra',
    name: 'Rajkot & Central Saurashtra',
    sublabel: 'Central Saurashtra Hub',
    centerCity: 'Rajkot',
    center: [22.3039, 70.8022],
    type: 'rain',
  },
  {
    id: 'mumbai',
    name: 'Mumbai & Coastal Konkan',
    sublabel: 'Konkan Maritime Zone',
    centerCity: 'Mumbai',
    center: [19.0760, 72.8777],
    type: 'rain',
  },
  {
    id: 'ahmedabad',
    name: 'Ahmedabad - Gandhinagar',
    sublabel: 'Sabarmati Plain',
    centerCity: 'Ahmedabad',
    center: [23.0225, 72.5714],
    type: 'general',
  },
  {
    id: 'saurashtra-coast',
    name: 'Saurashtra Coast & Diu',
    sublabel: 'Southern Coastal Corridor',
    centerCity: 'Veraval',
    center: [20.9000, 70.3700],
    type: 'wind',
  },
  {
    id: 'kutch',
    name: 'Gulf of Kutch Belt',
    sublabel: 'Coastal Maritime Belt',
    centerCity: 'Kandla',
    center: [23.0000, 70.2200],
    type: 'wind',
  }
];

const createGpsUserMarkerIcon = (cityName: string) => {
  return L.divIcon({
    className: 'gps-user-location-marker',
    html: `
      <div style="position: relative; transform: translate(-50%, -100%); cursor: pointer;">
        <div style="display: flex; align-items: center; gap: 6px; background: rgba(255, 255, 255, 0.96); border: 2px solid #0d9488; color: #0f172a; padding: 5px 12px; border-radius: 9999px; box-shadow: 0 4px 18px rgba(0,0,0,0.3); backdrop-filter: blur(8px); white-space: nowrap; font-family: sans-serif;">
          <span style="font-size: 14px;">📍</span>
          <div style="display: flex; flex-direction: column; text-align: left;">
            <span style="font-size: 11px; font-weight: 800; color: #0d9488;">Your Location</span>
            <span style="font-size: 9.5px; font-weight: 700; color: #0f172a;">${cityName}</span>
          </div>
        </div>
        <div style="width: 0; height: 0; border-left: 6px solid transparent; border-right: 6px solid transparent; border-top: 8px solid #0d9488; margin: 0 auto;"></div>
      </div>
    `,
    iconSize: [0, 0],
    iconAnchor: [0, 0],
  });
};



const mapThemes = [
  {
    id: 'google-hybrid',
    name: 'Google Satellite Hybrid',
    subtitle: 'Crisp satellite with all cities & areas',
    url: 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
    subdomains: ['0', '1', '2', '3'],
    maxZoom: 21,
    maxNativeZoom: 20,
    attribution: '&copy; Google Maps',
    thumb: 'https://mt1.google.com/vt/lyrs=y&x=4&y=8&z=4',
    fallbackGradient: 'from-emerald-900 via-teal-800 to-green-950',
    hasOverlayLabels: false,
  },
  {
    id: 'osm-roads',
    name: 'Google Street / OSM',
    subtitle: 'Clear streets, colonies, towns & cities',
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    maxZoom: 20,
    maxNativeZoom: 19,
    attribution: '&copy; OpenStreetMap contributors',
    thumb: 'https://tile.openstreetmap.org/4/12/8.png',
    fallbackGradient: 'from-blue-200 via-emerald-100 to-yellow-100',
    hasOverlayLabels: false,
  },
  {
    id: 'voyager',
    name: 'Voyager Detailed Areas',
    subtitle: 'High-contrast cities, borders & districts',
    url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    maxZoom: 20,
    maxNativeZoom: 19,
    attribution: '&copy; CARTO Voyager',
    thumb: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/4/12/8.png',
    fallbackGradient: 'from-amber-200 via-rose-100 to-sky-200',
    hasOverlayLabels: false,
  },
  {
    id: 'satellite-pure',
    name: 'Esri Satellite + Labels',
    subtitle: 'Photographic aerial with city names',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    subdomains: ['server'],
    maxZoom: 20,
    maxNativeZoom: 18,
    attribution: '&copy; Esri World Imagery',
    thumb: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/4/8/12',
    fallbackGradient: 'from-emerald-900 via-teal-800 to-green-950',
    hasOverlayLabels: true,
  },
  {
    id: 'terrain',
    name: 'Terrain & Topo Relief',
    subtitle: 'Mountains, rivers & regional towns',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    subdomains: ['server'],
    maxZoom: 20,
    maxNativeZoom: 19,
    attribution: '&copy; Esri Topo',
    thumb: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/4/8/12',
    fallbackGradient: 'from-amber-600 via-orange-500 to-yellow-600',
    hasOverlayLabels: false,
  },
  {
    id: 'dark',
    name: 'Dark Mode Cities',
    subtitle: 'Night styling with illuminated roads',
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    maxZoom: 20,
    maxNativeZoom: 19,
    attribution: '&copy; CARTO Dark Matter',
    thumb: 'https://a.basemaps.cartocdn.com/dark_all/4/12/8.png',
    fallbackGradient: 'from-gray-900 via-slate-800 to-black',
    hasOverlayLabels: false,
  },
  {
    id: 'light',
    name: 'Clean Positron Light',
    subtitle: 'Minimalist clean roads & places',
    url: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    maxZoom: 20,
    maxNativeZoom: 19,
    attribution: '&copy; CARTO Positron',
    thumb: 'https://a.basemaps.cartocdn.com/light_all/4/12/8.png',
    fallbackGradient: 'from-gray-100 via-slate-200 to-zinc-300',
    hasOverlayLabels: false,
  },
];

function FlyToLocation({ position, zoom }: { position: [number, number]; zoom?: number }) {
  const map = useMap();
  const posKey = `${position[0]},${position[1]},${zoom}`;
  const prevKey = useRef(posKey);

  useEffect(() => {
    if (prevKey.current !== posKey) {
      prevKey.current = posKey;
      map.flyTo(position, zoom ?? 11, { duration: 1.5 });
    }
  }, [posKey, position, zoom, map]);

  return null;
}

function MapClickListener({ onMapClick }: { onMapClick: (lat: number, lon: number) => void }) {
  useMapEvents({
    click(e) {
      onMapClick(e.latlng.lat, e.latlng.lng);
    }
  });
  return null;
}

interface SearchResult {
  lat: number;
  lon: number;
  name: string;
}

export default function WeatherMapPage() {
  const { t } = useLanguage();
  const navigate = useNavigate();
  const { convertTemp, tempUnitSymbol, profile, updateProfile } = useUserProfile();
  const [searchParams] = useSearchParams();


  const [unitMode, setUnitMode] = useState<'inches' | 'mm'>('inches');
  const [mapStyle, setMapStyle] = useState('google-hybrid');
  const [styleDropdownOpen, setStyleDropdownOpen] = useState(false);

  const [searchQuery, setSearchQuery] = useState('');
  const [searching, setSearching] = useState(false);
  const [searchError, setSearchError] = useState('');
  const [searchResult, setSearchResult] = useState<SearchResult | null>(null);

  const [mapCenter, setMapCenter] = useState<[number, number]>(defaultCenter);
  const [mapZoom, setMapZoom] = useState(6);
  const [locating, setLocating] = useState(false);

  const [userGpsLocation, setUserGpsLocation] = useState<{ lat: number; lon: number; name: string } | null>(null);

  // Main Weather Map Data fetched from backend for active location
  const [weatherMapData, setWeatherMapData] = useState<NormalizedMapWeatherData | null>(null);
  const [loadingWeather, setLoadingWeather] = useState(false);
  const [weatherError, setWeatherError] = useState<string | null>(null);

  // Regional Map Weather Cache (cityName -> NormalizedMapWeatherData)
  const [regionalCache, setRegionalCache] = useState<Record<string, NormalizedMapWeatherData>>({});

  const dropdownRef = useRef<HTMLDivElement>(null);
  const currentTheme = mapThemes.find(t => t.id === mapStyle) || mapThemes[0];

  // Helper to fetch backend weather data for any city and normalize it
  const fetchBackendWeatherForCity = async (cityName: string, lat?: number, lon?: number) => {
    setLoadingWeather(true);
    setWeatherError(null);

    const cleanName = cityName.split(',')[0].trim();

    try {
      const rawWeather = await getWeatherData(cleanName);
      if (rawWeather) {
        const normalized = normalizeMapWeatherData(rawWeather, cleanName, lat, lon);
        
        try {
          const alertRes = await fetchWeatherAlertsApi(cleanName);
          if (alertRes && alertRes.success && Array.isArray(alertRes.alerts)) {
            normalized.alerts = alertRes.alerts;
          }
        } catch {
          // ignore alert endpoint failure gracefully
        }

        setWeatherMapData(normalized);
        setRegionalCache(prev => ({ ...prev, [cleanName.toLowerCase()]: normalized }));
        setLoadingWeather(false);
        return normalized;
      }
    } catch (err: any) {
      console.warn(`Failed to fetch weather from backend for "${cleanName}":`, err);
      setWeatherError(`Weather data temporarily unavailable for ${cleanName}.`);
    }

    setLoadingWeather(false);
    return null;
  };

  // Pre-fetch key regional cities concurrently to display live backend markers across Gujarat/India
  useEffect(() => {
    const keyCities = ['Rajkot', 'Mumbai', 'Ahmedabad', 'Surat', 'Morbi', 'Veraval'];
    keyCities.forEach(city => {
      if (!regionalCache[city.toLowerCase()]) {
        getWeatherData(city).then(res => {
          if (res) {
            const norm = normalizeMapWeatherData(res, city);
            setRegionalCache(prev => ({ ...prev, [city.toLowerCase()]: norm }));
          }
        }).catch(() => {});
      }
    });
  }, []);

  // Initial Load & URL Parameter handler
  useEffect(() => {
    const cityParam = searchParams.get('city');
    const locateParam = searchParams.get('locate');
    const regionParam = searchParams.get('region');

    if (locateParam === 'true') {
      handleUseMyLocation();
    } else if (cityParam) {
      setSearchQuery(cityParam);
      fetchBackendWeatherForCity(cityParam);
    } else if (regionParam) {
      fetchBackendWeatherForCity(regionParam);
    } else {
      const activeCity = profile?.location || 'Rajkot';
      fetchBackendWeatherForCity(activeCity);
    }
  }, [searchParams]);

  // Close custom dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setStyleDropdownOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Map Click Handler — fetches real weather for clicked point immediately
  const handleMapClick = async (lat: number, lon: number) => {
    setMapCenter([lat, lon]);
    setMapZoom(11);

    let placeName = `${lat.toFixed(3)}°, ${lon.toFixed(3)}°`;
    setSearchQuery(placeName);

    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=12`,
        { headers: { 'Accept': 'application/json' } }
      );
      if (res.ok) {
        const data = await res.json();
        const addr = data.address;
        placeName = addr?.city || addr?.town || addr?.village || addr?.suburb || addr?.county || addr?.state || placeName;
      }
    } catch {}

    setSearchQuery(placeName);
    setSearchResult({ lat, lon, name: placeName });
    await fetchBackendWeatherForCity(placeName, lat, lon);
  };

  const handleSearch = async () => {
    const query = searchQuery.trim();
    if (!query) return;

    setSearching(true);
    setSearchError('');

    try {
      const norm = await fetchBackendWeatherForCity(query);
      if (norm) {
        setSearchResult({
          lat: norm.location.lat,
          lon: norm.location.lon,
          name: norm.location.name
        });
        setMapCenter([norm.location.lat, norm.location.lon]);
        setMapZoom(11);
        
        if (updateProfile) {
          updateProfile({ location: norm.location.name });
        }
      } else {
        const res = await fetch(
          `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1`,
          { headers: { 'Accept': 'application/json' } }
        );
        if (res.ok) {
          const data = await res.json();
          if (data.length > 0) {
            const lat = parseFloat(data[0].lat);
            const lon = parseFloat(data[0].lon);
            const name = data[0].display_name.split(',').slice(0, 2).join(',');

            setSearchResult({ lat, lon, name });
            setMapCenter([lat, lon]);
            setMapZoom(11);
            await fetchBackendWeatherForCity(name, lat, lon);
          } else {
            setSearchError(`Location "${query}" not found.`);
          }
        } else {
          setSearchError(`Location "${query}" not found.`);
        }
      }
    } catch {
      setSearchError('Search request failed. Please try again.');
    } finally {
      setSearching(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      handleSearch();
    }
  };

  const handleUseMyLocation = async () => {
    if (!navigator.geolocation) {
      setSearchError('Geolocation is not supported by your browser.');
      return;
    }

    setLocating(true);
    setSearchError('');

    try {
      const coords = await getUserLocation();
      if (!coords) {
        setSearchError('Location permission denied. Please allow location access in your browser.');
        setLocating(false);
        return;
      }

      let detectedCity = 'My Location';
      try {
        const geoRes = await reverseGeocodeLocation(coords.latitude, coords.longitude);
        if (geoRes && geoRes.city) {
          detectedCity = geoRes.city;
        }
      } catch {
        try {
          const osmRes = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${coords.latitude}&lon=${coords.longitude}`);
          if (osmRes.ok) {
            const data = await osmRes.json();
            detectedCity = data.address?.city || data.address?.town || data.address?.village || data.address?.county || 'My Location';
          }
        } catch {}
      }

      setUserGpsLocation({
        lat: coords.latitude,
        lon: coords.longitude,
        name: detectedCity
      });

      setSearchResult({
        lat: coords.latitude,
        lon: coords.longitude,
        name: detectedCity
      });

      setMapCenter([coords.latitude, coords.longitude]);
      setMapZoom(13);

      await fetchBackendWeatherForCity(detectedCity, coords.latitude, coords.longitude);

      if (updateProfile && detectedCity !== 'My Location') {
        updateProfile({ location: detectedCity });
      }
    } catch (e: any) {
      setSearchError(e.message || 'Unable to determine your location.');
    } finally {
      setLocating(false);
    }
  };

  const getRainRatePercentage = (rateInches: number) => {
    return Math.min(100, Math.max(5, (rateInches / 2.5) * 100));
  };

  const currWeather = weatherMapData?.current;

  return (
    <div className="space-y-4 w-full mx-auto min-h-[calc(100vh-120px)] flex flex-col animate-in fade-in duration-500 text-white">
      {/* Top Header Controls */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Map className="w-8 h-8 text-primary" />
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t('map_title', 'Weather & Rainfall Map')}</h1>
            <p className="text-xs text-muted-foreground hidden sm:block">
              {t('map_subtitle', 'Live backend weather, precipitation & atmospheric radar inspector')}
            </p>
          </div>
        </div>
        
        {/* Search & Location Controls Toolbar */}
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <div className="flex items-center gap-2 bg-card border rounded-xl p-1.5 shadow-sm flex-1 sm:flex-initial focus-within:border-primary focus-within:ring-1 focus-within:ring-primary transition-all">
            <Search className="w-5 h-5 text-muted-foreground ml-2 flex-shrink-0" />
            <input 
              type="text" 
              placeholder={t('map_search_placeholder', 'Search city, area or country...')} 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={handleKeyDown}
              className="bg-transparent border-none outline-none text-sm px-2 py-1 w-full sm:w-60 text-foreground"
            />
            <button
              onClick={handleSearch}
              disabled={searching || !searchQuery.trim()}
              className="px-3.5 py-1.5 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-50 flex items-center gap-1.5 flex-shrink-0 cursor-pointer"
            >
              {searching ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <>
                  <Search className="w-3.5 h-3.5" />
                  <span>{t('map_search_btn', 'Search')}</span>
                </>
              )}
            </button>
          </div>

          {/* Integrated My Location Button right in toolbar */}
          <button
            onClick={handleUseMyLocation}
            disabled={locating}
            className="flex items-center gap-1.5 px-3.5 py-2.5 bg-card hover:bg-muted border border-border text-primary rounded-xl text-sm font-medium shadow-sm transition-all hover:border-primary/50 disabled:opacity-60 flex-shrink-0 cursor-pointer"
            title="Detect my current GPS location and inspect weather"
          >
            {locating ? (
              <Loader2 className="w-4 h-4 animate-spin text-primary" />
            ) : (
              <Navigation className="w-4 h-4 text-primary" />
            )}
            <span className="hidden md:inline text-xs font-semibold">{t('map_my_location', 'My Location')}</span>
          </button>
        </div>
      </div>

      {/* Search Error / Stale Warning Banners */}
      {searchError && (
        <div className="text-sm text-rose-300 bg-rose-500/15 border border-rose-500/30 px-4 py-2.5 rounded-xl flex items-center justify-between backdrop-blur-md">
          <span>{searchError}</span>
          <button onClick={() => setSearchError('')} className="text-xs font-semibold hover:underline ml-3">Dismiss</button>
        </div>
      )}

      {weatherError && (
        <div className="text-sm text-amber-300 bg-amber-500/15 border border-amber-500/30 px-4 py-2.5 rounded-xl flex items-center justify-between backdrop-blur-md">
          <div className="flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 text-amber-400" />
            <span>{weatherError}</span>
          </div>
          <button onClick={() => fetchBackendWeatherForCity(weatherMapData?.location.name || 'Rajkot')} className="text-xs font-bold bg-amber-500/20 hover:bg-amber-500/30 px-3 py-1 rounded-lg border border-amber-400/40 flex items-center gap-1">
            <RefreshCw className="w-3 h-3" /> Retry
          </button>
        </div>
      )}

      {currWeather?.is_stale && (
        <div className="text-xs text-sky-200 bg-sky-500/15 border border-sky-500/30 px-3.5 py-2 rounded-xl flex items-center gap-2 backdrop-blur-md">
          <Info className="w-3.5 h-3.5 text-sky-300" />
          <span>Showing recently cached weather data (Updated {currWeather.fetched_at})</span>
        </div>
      )}

      {/* Main Map + Sidebar Area */}
      <div className="flex flex-col md:flex-row gap-4 h-full flex-1">
        {/* Controls Sidebar */}
        <Card className="w-full md:w-96 lg:w-[380px] flex-shrink-0 h-fit max-h-[calc(100vh-140px)] overflow-y-auto border-border/80 shadow-lg">
          <CardContent className="p-4 sm:p-5 space-y-5">
            
            {/* Map Mode Selector */}
            <div className="relative" ref={dropdownRef}>
              <h3 className="text-xs font-bold text-muted-foreground uppercase tracking-wider mb-2 flex items-center gap-2">
                <Palette className="w-4 h-4 text-primary" />
                {t('map_mode', 'Map Mode')}
              </h3>

              <button
                type="button"
                onClick={() => setStyleDropdownOpen(!styleDropdownOpen)}
                className="w-full flex items-center gap-3 border border-border rounded-xl p-2.5 bg-background hover:bg-muted/60 transition-all focus:ring-2 focus:ring-primary outline-none cursor-pointer shadow-sm text-left"
              >
                <div className={`relative w-10 h-10 rounded-lg overflow-hidden flex-shrink-0 border border-border shadow-xs bg-gradient-to-br ${currentTheme.fallbackGradient}`}>
                  <img
                    src={currentTheme.thumb}
                    alt={currentTheme.name}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLElement).style.opacity = '0';
                    }}
                  />
                </div>

                <div className="flex-1 min-w-0">
                  <div className="text-xs font-bold text-foreground truncate">{currentTheme.name}</div>
                  <div className="text-[11px] text-muted-foreground truncate">{currentTheme.subtitle}</div>
                </div>

                <ChevronDown className={`w-4 h-4 text-muted-foreground transition-transform duration-200 flex-shrink-0 ${styleDropdownOpen ? 'rotate-180' : ''}`} />
              </button>

              {styleDropdownOpen && (
                <div className="absolute left-0 right-0 z-50 mt-1.5 bg-card border border-border rounded-xl shadow-2xl overflow-hidden animate-in fade-in slide-in-from-top-2 duration-150">
                  <div className="p-1.5 max-h-72 overflow-y-auto space-y-1">
                    {mapThemes.map((t) => {
                      const isSelected = mapStyle === t.id;
                      return (
                        <button
                          key={t.id}
                          type="button"
                          onClick={() => {
                            setMapStyle(t.id);
                            setStyleDropdownOpen(false);
                          }}
                          className={`w-full flex items-center gap-3 p-2 rounded-lg text-left transition-colors cursor-pointer ${
                            isSelected
                              ? 'bg-primary/10 text-primary'
                              : 'hover:bg-muted text-foreground'
                          }`}
                        >
                          <div className={`relative w-10 h-10 rounded-lg overflow-hidden flex-shrink-0 border shadow-xs bg-gradient-to-br ${t.fallbackGradient} ${
                            isSelected ? 'border-primary ring-2 ring-primary/40' : 'border-border/60'
                          }`}>
                            <img
                              src={t.thumb}
                              alt={t.name}
                              className="w-full h-full object-cover"
                              onError={(e) => {
                                (e.target as HTMLElement).style.opacity = '0';
                              }}
                            />
                          </div>

                          <div className="flex-1 min-w-0">
                            <div className={`text-xs font-bold truncate ${isSelected ? 'text-primary' : 'text-foreground'}`}>
                              {t.name}
                            </div>
                            <div className="text-[10px] text-muted-foreground truncate">
                              {t.subtitle}
                            </div>
                          </div>

                          {isSelected && (
                            <Check className="w-4 h-4 text-primary flex-shrink-0 ml-1" />
                          )}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>

            {/* Dedicated Live Weather & Rainfall Panel */}
            {currWeather && (
              <div className="p-3.5 bg-gradient-to-br from-blue-500/15 via-background to-blue-500/10 rounded-2xl border border-blue-400/40 space-y-3 shadow-sm pt-3 border-t border-border/60">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <CloudRain className="w-4 h-4 text-blue-400" />
                    <span className="text-xs font-bold text-foreground">{t('map_rainfall_measurement', 'Rainfall Measurement')}</span>
                  </div>

                  <div className="flex items-center bg-muted/80 p-0.5 rounded-lg border border-border text-[10px] font-bold">
                    <button
                      type="button"
                      onClick={() => setUnitMode('inches')}
                      className={cn(
                        "px-2 py-0.5 rounded-md transition-all cursor-pointer",
                        unitMode === 'inches' ? "bg-primary text-primary-foreground shadow-xs" : "text-muted-foreground hover:text-foreground"
                      )}
                    >
                      Inches (in)
                    </button>
                    <button
                      type="button"
                      onClick={() => setUnitMode('mm')}
                      className={cn(
                        "px-2 py-0.5 rounded-md transition-all cursor-pointer",
                        unitMode === 'mm' ? "bg-primary text-primary-foreground shadow-xs" : "text-muted-foreground hover:text-foreground"
                      )}
                    >
                      mm
                    </button>
                  </div>
                </div>

                <div>
                  <h4 className="text-xs font-extrabold text-foreground truncate flex items-center gap-1">
                    <MapPin className="w-3.5 h-3.5 text-primary flex-shrink-0" />
                    <span className="truncate">{weatherMapData?.location.name || 'Rajkot'}</span>
                  </h4>
                  <p className="text-[10px] text-muted-foreground mt-0.5">
                    {currWeather.conditionText} • Updated {currWeather.fetched_at}
                  </p>
                </div>

                  <div className="grid grid-cols-3 gap-1.5 p-2 bg-background/90 rounded-xl border border-border/80">
                    <div className="text-center p-1.5 rounded-lg bg-blue-500/10 border border-blue-500/20">
                      <div className="text-[9px] font-bold text-muted-foreground uppercase">{t('map_current_rate', 'Current Rate')}</div>
                      <div className="text-xs sm:text-sm font-extrabold text-blue-400 mt-0.5">
                        {unitMode === 'inches' 
                          ? `${currWeather.precip_rate_inches.toFixed(2)} in/h`
                          : `${currWeather.precip_mm} mm/h`}
                      </div>
                    </div>

                    <div className="text-center p-1.5 rounded-lg bg-indigo-500/10 border border-indigo-500/20">
                      <div className="text-[9px] font-bold text-muted-foreground uppercase">{t('map_24h_total', '24h Total')}</div>
                      <div className="text-xs sm:text-sm font-extrabold text-indigo-300 mt-0.5">
                        {unitMode === 'inches'
                          ? `${currWeather.precip_total_24h_inches.toFixed(2)} in`
                          : `${currWeather.precip_total_24h_mm.toFixed(1)} mm`}
                      </div>
                    </div>

                    <div className="text-center p-1.5 rounded-lg bg-sky-500/10 border border-sky-500/20">
                      <div className="text-[9px] font-bold text-muted-foreground uppercase">{t('map_next_3h', 'Next 3h')}</div>
                      <div className="text-xs sm:text-sm font-extrabold text-sky-300 mt-0.5">
                        {unitMode === 'inches'
                          ? `${currWeather.precip_3h_inches.toFixed(2)} in`
                          : `${Math.round(currWeather.precip_3h_inches * 25.4)} mm`}
                      </div>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <div className="flex justify-between text-[10px] font-semibold text-muted-foreground">
                      <span>{t('map_intensity', 'Intensity Level')}</span>
                      <span className="font-bold text-foreground">
                        {currWeather.precip_rate_inches >= 1.0 ? 'Cloudburst (>1.0 in/h)' :
                         currWeather.precip_rate_inches >= 0.3 ? 'Heavy (0.3-1.0 in/h)' :
                         currWeather.precip_rate_inches >= 0.1 ? 'Moderate (0.1-0.3 in/h)' :
                         currWeather.precip_rate_inches > 0 ? 'Light (<0.1 in/h)' : 'Dry & Clear'}
                      </span>
                    </div>
                    <div className="h-2 w-full bg-muted rounded-full overflow-hidden p-0.5 border border-border/60 flex">
                      <div 
                        className={cn(
                          "h-full rounded-full transition-all duration-500",
                          currWeather.precip_rate_inches >= 1.0 ? "bg-gradient-to-r from-orange-500 to-red-600" :
                          currWeather.precip_rate_inches >= 0.3 ? "bg-gradient-to-r from-blue-500 to-indigo-600" :
                          currWeather.precip_rate_inches >= 0.1 ? "bg-gradient-to-r from-sky-400 to-blue-500" :
                          currWeather.precip_rate_inches > 0 ? "bg-sky-300" : "bg-emerald-500"
                        )}
                        style={{ width: `${getRainRatePercentage(currWeather.precip_rate_inches)}%` }}
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2 text-[11px]">
                    <div className="p-2 bg-muted/60 rounded-xl border border-border/60 flex flex-col justify-between">
                      <span className="text-muted-foreground font-medium flex items-center justify-between text-[10px]">
                        <span>Temp</span>
                        <span className="text-[9px] opacity-75">Feels {convertTemp(currWeather.feelslike_c)}{tempUnitSymbol}</span>
                      </span>
                      <span className="font-extrabold text-sm text-foreground">{convertTemp(currWeather.temp_c)}{tempUnitSymbol}</span>
                    </div>

                    <div className="p-2 bg-muted/60 rounded-xl border border-border/60 flex flex-col justify-between">
                      <span className="text-muted-foreground font-medium text-[10px]">Cloud Coverage</span>
                      <span className="font-extrabold text-sm text-sky-300">
                        {currWeather.cloud_cover !== null && currWeather.cloud_cover !== undefined ? `${currWeather.cloud_cover}%` : 'N/A'}
                      </span>
                    </div>

                    <div className="p-2 bg-muted/60 rounded-xl border border-border/60 flex flex-col justify-between">
                      <span className="text-muted-foreground font-medium text-[10px]">Rain Chance</span>
                      <span className="font-extrabold text-sm text-blue-300">{currWeather.rain_probability}%</span>
                    </div>

                    <div className="p-2 bg-muted/60 rounded-xl border border-border/60 flex flex-col justify-between">
                      <span className="text-muted-foreground font-medium text-[10px]">Wind</span>
                      <span className="font-extrabold text-xs text-teal-300 truncate">{currWeather.wind_kph} km/h {currWeather.wind_direction_label}</span>
                    </div>

                    <div className="p-2 bg-muted/60 rounded-xl border border-border/60 flex flex-col justify-between">
                      <span className="text-muted-foreground font-medium text-[10px]">Humidity</span>
                      <span className="font-extrabold text-sm text-indigo-300">{currWeather.humidity}%</span>
                    </div>

                    <div className="p-2 bg-muted/60 rounded-xl border border-border/60 flex flex-col justify-between">
                      <span className="text-muted-foreground font-medium text-[10px]">Pressure / UV</span>
                      <span className="font-extrabold text-xs text-amber-300">{currWeather.pressure_mb} hPa • UV {currWeather.uv}</span>
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => navigate(`/assistant?prompt=${encodeURIComponent(`What is the weather and rainfall forecast for ${weatherMapData?.location.name}? Current temp is ${convertTemp(currWeather.temp_c)}${tempUnitSymbol}, rain rate is ${currWeather.precip_rate_inches} in/hr, wind is ${currWeather.wind_kph} km/h ${currWeather.wind_direction_label}.`)}`)}
                    className="w-full flex items-center justify-center gap-1.5 py-2.5 px-3 text-xs font-bold bg-primary text-primary-foreground rounded-xl hover:bg-primary/90 transition-all shadow-sm cursor-pointer"
                  >
                    <Sparkles className="w-3.5 h-3.5 text-amber-300" />
                    <span>{t('map_ask_ai_rainfall', 'Ask AI About This Weather')}</span>
                  </button>
                </div>
              )}

            {searchResult && (
              <div className="pt-2 border-t border-border">
                <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-2 flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-primary" />
                  Active Search Result
                </h3>
                <div className="p-2.5 bg-primary/10 rounded-xl border border-primary/20 space-y-1.5">
                  <p className="text-xs font-bold text-primary">{searchResult.name}</p>
                  <p className="text-[11px] text-muted-foreground">
                    {searchResult.lat.toFixed(4)}°, {searchResult.lon.toFixed(4)}°
                  </p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Interactive Leaflet Map Container */}
        <div className="flex-1 rounded-2xl border bg-muted overflow-hidden relative shadow-sm min-h-[450px]">
          {loadingWeather && (
            <div className="absolute top-4 left-4 z-[400] bg-background/90 backdrop-blur-md border border-border px-3.5 py-2 rounded-xl text-xs font-bold text-foreground flex items-center gap-2 shadow-lg">
              <Loader2 className="w-4 h-4 animate-spin text-primary" />
              <span>Loading backend weather data...</span>
            </div>
          )}

          <MapContainer center={defaultCenter} zoom={6} maxZoom={21} className="w-full h-full z-0">
            <TileLayer
              key={currentTheme.id}
              attribution={currentTheme.attribution}
              url={currentTheme.url}
              subdomains={currentTheme.subdomains}
              maxZoom={currentTheme.maxZoom || 20}
              maxNativeZoom={currentTheme.maxNativeZoom || 19}
            />

            {currentTheme.hasOverlayLabels && (
              <TileLayer
                attribution="&copy; Esri Reference"
                url="https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}"
                maxZoom={20}
                maxNativeZoom={18}
                opacity={0.9}
              />
            )}

            <FlyToLocation position={mapCenter} zoom={mapZoom} />
            <MapClickListener onMapClick={handleMapClick} />

            {/* Render User GPS Location Pin */}
            {userGpsLocation && (
              <Marker
                position={[userGpsLocation.lat, userGpsLocation.lon]}
                icon={createGpsUserMarkerIcon(userGpsLocation.name)}
              >
                <Popup>
                  <div className="text-center font-sans p-1.5 space-y-1">
                    <div className="font-bold text-xs text-primary flex items-center justify-center gap-1">
                      <span>📍</span>
                      <span>Your GPS Location</span>
                    </div>
                    <div className="text-xs font-semibold text-foreground">{userGpsLocation.name}</div>
                    <div className="text-[10px] text-muted-foreground">
                      {userGpsLocation.lat.toFixed(4)}°, {userGpsLocation.lon.toFixed(4)}°
                    </div>
                  </div>
                </Popup>
              </Marker>
            )}



            {/* Render Weather Location Radius Zone Circle */}
            {weatherMapData && (
              <Circle
                center={[weatherMapData.location.lat, weatherMapData.location.lon]}
                radius={weatherMapData.current.precip_mm > 0 ? 35000 : 25000}
                pathOptions={{
                  fillColor: weatherMapData.current.precip_mm > 0 ? '#3b82f6' : '#10b981',
                  fillOpacity: weatherMapData.current.precip_mm > 0 ? 0.15 : 0.08,
                  color: weatherMapData.current.precip_mm > 0 ? '#2563eb' : '#059669',
                  weight: 2,
                  dashArray: '6, 6'
                }}
              />
            )}
          </MapContainer>

          {/* Clean Map Compass / Target Icon at top-right of map */}
          <button 
            onClick={handleUseMyLocation}
            disabled={locating}
            className="absolute top-4 right-4 z-[400] bg-background/95 backdrop-blur-sm border border-border p-2.5 rounded-xl shadow-md text-primary hover:bg-muted transition-all hover:scale-105 disabled:opacity-70 cursor-pointer"
            title="Locate me on map and calculate rainfall"
          >
            {locating ? (
              <Loader2 className="w-5 h-5 animate-spin text-primary" />
            ) : (
              <Compass className="w-5 h-5 text-primary" />
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
