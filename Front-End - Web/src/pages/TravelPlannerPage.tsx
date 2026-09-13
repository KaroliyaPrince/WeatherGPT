import { useState, useEffect, useRef } from 'react';
import { 
  Car, 
  AlertTriangle, 
  Navigation, 
  ArrowLeftRight, 
  MapPin, 
  Loader2, 
  Sparkles,
  RefreshCw
} from 'lucide-react';
import { useLanguage } from '../hooks/useLanguage';
import { INDIAN_CITIES } from '../data/indianCities';
import { 
  calculateRouteWeather, 
  getLiveRouteWeatherBackend,
  type RouteCalculationResult 
} from '../services/routeWeatherService';
import { RouteWeather } from '../components/route/RouteWeather';
import { rawBackendRouteWeatherResponse } from '../data/mockRouteWeather';

const PRESET_ROUTES = [
  { source: 'Morbi', destination: 'Surat', label: 'Morbi ➔ Surat (Backend Data)' },
  { source: 'Morbi', destination: 'Rajkot', label: 'Morbi ➔ Rajkot (NH27)' },
  { source: 'Rajkot', destination: 'Ahmedabad', label: 'Rajkot ➔ Ahmedabad (NH47)' },
  { source: 'Mumbai', destination: 'Pune', label: 'Mumbai ➔ Pune (Expressway)' },
  { source: 'Delhi', destination: 'Jaipur', label: 'Delhi ➔ Jaipur (NH48)' }
];

export default function TravelPlannerPage() {
  const { t } = useLanguage();

  const [sourceInput, setSourceInput] = useState('Morbi');
  const [destInput, setDestInput] = useState('Surat');

  const [sourceSuggestions, setSourceSuggestions] = useState<string[]>([]);
  const [destSuggestions, setDestSuggestions] = useState<string[]>([]);
  const [showSourceDropdown, setShowSourceDropdown] = useState(false);
  const [showDestDropdown, setShowDestDropdown] = useState(false);

  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [rawBackendRes, setRawBackendRes] = useState<any>(null);
  const [routeResult, setRouteResult] = useState<RouteCalculationResult | null>(null);

  const sourceRef = useRef<HTMLDivElement>(null);
  const destRef = useRef<HTMLDivElement>(null);

  // Initialize with default route calculation
  useEffect(() => {
    handleCalculateRoute('Morbi', 'Surat');
  }, []);

  // Handle source suggestions
  const handleSourceChange = (val: string) => {
    setSourceInput(val);
    if (!val.trim()) {
      setSourceSuggestions([]);
      setShowSourceDropdown(false);
      return;
    }
    const q = val.toLowerCase().trim();
    const matches = INDIAN_CITIES
      .filter(c => c.name.toLowerCase().includes(q))
      .slice(0, 5)
      .map(c => c.name);
    setSourceSuggestions(matches);
    setShowSourceDropdown(matches.length > 0);
  };

  // Handle destination suggestions
  const handleDestChange = (val: string) => {
    setDestInput(val);
    if (!val.trim()) {
      setDestSuggestions([]);
      setShowDestDropdown(false);
      return;
    }
    const q = val.toLowerCase().trim();
    const matches = INDIAN_CITIES
      .filter(c => c.name.toLowerCase().includes(q))
      .slice(0, 5)
      .map(c => c.name);
    setDestSuggestions(matches);
    setShowDestDropdown(matches.length > 0);
  };

  // Swap Source and Destination
  const handleSwap = () => {
    const temp = sourceInput;
    setSourceInput(destInput);
    setDestInput(temp);
  };

  // Main Route Submit Handler calling live Express API
  const handleCalculateRoute = async (
    src = sourceInput,
    dst = destInput
  ) => {
    if (!src.trim() || !dst.trim()) {
      setErrorMsg('Please enter both source and destination locations.');
      return;
    }

    setLoading(true);
    setErrorMsg('');
    setShowSourceDropdown(false);
    setShowDestDropdown(false);
    setRawBackendRes(null);
    setRouteResult(null);

    try {
      // 1. First attempt fetching live route weather from Express backend
      const liveRes = await getLiveRouteWeatherBackend(src, dst);
      setRawBackendRes(liveRes);
    } catch (err: any) {
      console.warn('Live API fetch failed, using fallback route calculator:', err.message);
      // 2. Fallback to client route calculation
      try {
        const fallbackRes = await calculateRouteWeather(src, dst, undefined, 'driving');
        setRouteResult(fallbackRes);
      } catch (fallbackErr: any) {
        setErrorMsg(fallbackErr.message || 'Unable to calculate route weather.');
      }
    } finally {
      setLoading(false);
    }
  };

  // Construct active raw response for RouteWeather component
  const activeRawResponse = rawBackendRes 
    ? rawBackendRes 
    : routeResult 
    ? {
        success: true,
        route: {
          source: { name: routeResult.source.name, latitude: routeResult.source.latitude, longitude: routeResult.source.longitude },
          destination: { name: routeResult.destination.name, latitude: routeResult.destination.latitude, longitude: routeResult.destination.longitude },
          distance_km: routeResult.distanceKm,
          duration_minutes: routeResult.durationMinutes,
          departure_time: routeResult.departureTimeIso
        },
        places: routeResult.waypoints.map(w => ({
          name: w.name,
          type: w.name === routeResult.source.name ? 'source' : w.name === routeResult.destination.name ? 'destination' : 'route_place',
          latitude: w.latitude,
          longitude: w.longitude,
          distance_from_start_km: w.distanceFromStartKm,
          estimated_arrival: w.estimatedArrivalIso,
          weather: {
            temp_c: w.weather.temperatureC,
            temperature_c: w.weather.temperatureC,
            condition: {
              text: w.weather.condition,
              icon: w.weather.icon
            },
            humidity: w.weather.humidity,
            wind_kph: w.weather.windSpeedKph,
            wind_speed_kph: w.weather.windSpeedKph,
            rain_probability: w.weather.rainProbability,
            visibility_km: w.weather.visibilityKm,
            is_stale: w.weather.isStale
          }
        })),
        alerts: routeResult.hazardAlert ? [{ type: routeResult.hazardAlert.type, title: 'Route Warning', place: routeResult.hazardAlert.place, severity: 'Warning', description: routeResult.hazardAlert.message }] : []
      }
    : rawBackendRouteWeatherResponse;

  return (
    <div className="space-y-6 pb-12 animate-in fade-in duration-300">
      
      {/* Header Banner */}
      <div className="p-6 sm:p-8 rounded-3xl bg-card border border-border shadow-xs flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-2 text-sky-400 font-bold text-xs uppercase tracking-wider mb-1">
            <Car className="w-4 h-4" />
            <span>Highway & Journey Weather</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-foreground">
            {t('travel_title', 'Source ➔ Destination Weather')}
          </h1>
          <p className="text-xs text-muted-foreground mt-1 max-w-xl">
            {t('travel_subtitle', 'Live arrival-time weather forecasts, highway hazard alerts, and route telemetry along your travel corridor.')}
          </p>
        </div>

        {/* Preset Quick Buttons */}
        <div className="flex items-center gap-1.5 flex-wrap">
          {PRESET_ROUTES.map((preset, idx) => (
            <button
              key={idx}
              onClick={() => {
                setSourceInput(preset.source);
                setDestInput(preset.destination);
                handleCalculateRoute(preset.source, preset.destination);
              }}
              className="px-3 py-1.5 rounded-xl bg-muted/60 hover:bg-muted border border-border text-xs font-semibold text-foreground transition-all cursor-pointer shadow-2xs"
            >
              {preset.label}
            </button>
          ))}
        </div>
      </div>

      {/* Main Interactive Route Search Form Card */}
      <div className="p-5 sm:p-6 rounded-3xl bg-card border border-border shadow-lg space-y-4">
        <h2 className="text-sm font-extrabold text-foreground uppercase tracking-wider flex items-center gap-2">
          <Navigation className="w-4 h-4 text-primary" />
          <span>Plan Your Journey Weather</span>
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-3.5 items-end">
          
          {/* Source Input */}
          <div className="md:col-span-5 relative" ref={sourceRef}>
            <label className="text-xs font-bold text-muted-foreground block mb-1.5">
              Source Location
            </label>
            <div className="relative">
              <MapPin className="w-4 h-4 text-emerald-500 absolute left-3 top-3" />
              <input
                type="text"
                placeholder="e.g. Morbi"
                value={sourceInput}
                onChange={e => handleSourceChange(e.target.value)}
                onFocus={() => sourceSuggestions.length > 0 && setShowSourceDropdown(true)}
                className="w-full bg-background border border-border rounded-xl pl-9 pr-3 py-2 text-sm font-semibold text-foreground focus:ring-2 focus:ring-primary outline-none"
              />
            </div>

            {/* Source Suggestions Dropdown */}
            {showSourceDropdown && (
              <div className="absolute left-0 right-0 z-50 mt-1 bg-card border border-border rounded-xl shadow-xl overflow-hidden animate-in fade-in">
                {sourceSuggestions.map((cityName, idx) => (
                  <button
                    key={idx}
                    onClick={() => {
                      setSourceInput(cityName);
                      setShowSourceDropdown(false);
                    }}
                    className="w-full px-3 py-2 text-left text-xs font-semibold hover:bg-muted text-foreground flex items-center gap-2"
                  >
                    <MapPin className="w-3.5 h-3.5 text-emerald-500" />
                    <span>{cityName}</span>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Swap Button */}
          <div className="md:col-span-1 flex justify-center py-1 md:py-0">
            <button
              onClick={handleSwap}
              type="button"
              className="p-2.5 rounded-xl bg-muted hover:bg-muted/80 border border-border text-muted-foreground hover:text-foreground transition-all cursor-pointer"
              title="Swap Source and Destination"
            >
              <ArrowLeftRight className="w-4 h-4" />
            </button>
          </div>

          {/* Destination Input */}
          <div className="md:col-span-4 relative" ref={destRef}>
            <label className="text-xs font-bold text-muted-foreground block mb-1.5">
              Destination Location
            </label>
            <div className="relative">
              <MapPin className="w-4 h-4 text-rose-500 absolute left-3 top-3" />
              <input
                type="text"
                placeholder="e.g. Surat"
                value={destInput}
                onChange={e => handleDestChange(e.target.value)}
                onFocus={() => destSuggestions.length > 0 && setShowDestDropdown(true)}
                className="w-full bg-background border border-border rounded-xl pl-9 pr-3 py-2 text-sm font-semibold text-foreground focus:ring-2 focus:ring-primary outline-none"
              />
            </div>

            {/* Destination Suggestions Dropdown */}
            {showDestDropdown && (
              <div className="absolute left-0 right-0 z-50 mt-1 bg-card border border-border rounded-xl shadow-xl overflow-hidden animate-in fade-in">
                {destSuggestions.map((cityName, idx) => (
                  <button
                    key={idx}
                    onClick={() => {
                      setDestInput(cityName);
                      setShowDestDropdown(false);
                    }}
                    className="w-full px-3 py-2 text-left text-xs font-semibold hover:bg-muted text-foreground flex items-center gap-2"
                  >
                    <MapPin className="w-3.5 h-3.5 text-rose-500" />
                    <span>{cityName}</span>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Action Submit Button */}
          <div className="md:col-span-2">
            <button
              onClick={() => handleCalculateRoute()}
              disabled={loading}
              className="w-full px-4 py-2 bg-primary text-primary-foreground font-extrabold text-xs sm:text-sm rounded-xl hover:bg-primary/90 transition-all shadow-md cursor-pointer flex items-center justify-center gap-2 disabled:opacity-50 h-[38px]"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>Calculating...</span>
                </>
              ) : (
                <>
                  <Sparkles className="w-4 h-4 text-amber-300 shrink-0" />
                  <span className="truncate">Check Route</span>
                </>
              )}
            </button>
          </div>
        </div>

        {/* Error message banner */}
        {errorMsg && (
          <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-xs text-red-500 font-semibold flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 flex-shrink-0" />
              <span>{errorMsg}</span>
            </div>
            <button 
              onClick={() => handleCalculateRoute()} 
              className="px-2.5 py-1 bg-red-500/20 hover:bg-red-500/30 rounded-lg text-[11px] font-bold text-red-400 flex items-center gap-1 cursor-pointer"
            >
              <RefreshCw className="w-3 h-3" /> Retry
            </button>
          </div>
        )}
      </div>

      {/* Main Route Weather Display */}
      <RouteWeather 
        rawResponse={activeRawResponse} 
        loading={loading} 
        error={errorMsg}
        onRefresh={() => handleCalculateRoute()} 
      />
    </div>
  );
}
