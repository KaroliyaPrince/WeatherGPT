import { useState } from 'react';
import { 
  MapPin, 
  Clock, 
  Navigation, 
  AlertTriangle, 
  CloudOff, 
  ChevronDown, 
  ChevronUp, 
  Sun,
  Cloud,
  CloudSun,
  CloudRain,
  CloudDrizzle,
  CloudLightning,
  Snowflake,
  CloudFog,
  Wind,
  Droplets,
  Eye,
  Umbrella,
  ArrowRight
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useUserProfile } from '../../hooks/useUserProfile';
import { 
  transformRouteWeatherResponse, 
  type NormalizedRouteWeatherResponse
} from '../../services/routeWeatherNormalizer';
import { rawBackendRouteWeatherResponse } from '../../data/mockRouteWeather';
import { RouteMapLeaflet } from './RouteMapLeaflet';

interface RouteWeatherProps {
  rawResponse?: any;
  loading?: boolean;
  error?: string | null;
  onRefresh?: () => void;
}

// Map condition text/icon to Lucide icons dynamically
export function getWeatherIcon(conditionText?: string, iconName?: string) {
  const text = (conditionText || '').toLowerCase();
  const icon = (iconName || '').toLowerCase();

  if (text.includes('thunder') || icon.includes('lightning')) {
    return <CloudLightning className="w-5 h-5 text-amber-400 shrink-0" />;
  }
  if (text.includes('heavy rain') || text.includes('torrential') || icon.includes('heavy-rain')) {
    return <CloudRain className="w-5 h-5 text-blue-400 shrink-0" />;
  }
  if (text.includes('drizzle') || icon.includes('drizzle')) {
    return <CloudDrizzle className="w-5 h-5 text-cyan-300 shrink-0" />;
  }
  if (text.includes('rain') || text.includes('shower') || icon.includes('rain')) {
    return <CloudRain className="w-5 h-5 text-sky-400 shrink-0" />;
  }
  if (text.includes('snow') || icon.includes('snow')) {
    return <Snowflake className="w-5 h-5 text-indigo-200 shrink-0" />;
  }
  if (text.includes('fog') || text.includes('mist') || text.includes('haze') || icon.includes('fog')) {
    return <CloudFog className="w-5 h-5 text-slate-300 shrink-0" />;
  }
  if (text.includes('overcast') || text.includes('cloudy') || icon.includes('cloud')) {
    return <Cloud className="w-5 h-5 text-slate-300 shrink-0" />;
  }
  if (text.includes('partly') || icon.includes('cloud-sun')) {
    return <CloudSun className="w-5 h-5 text-amber-300 shrink-0" />;
  }
  if (text.includes('wind') || icon.includes('wind')) {
    return <Wind className="w-5 h-5 text-teal-300 shrink-0" />;
  }
  return <Sun className="w-5 h-5 text-amber-400 shrink-0" />;
}

// Format duration minutes (495 -> "8h 15m")
export function formatDuration(minutes: number): string {
  if (!minutes || minutes <= 0) return '0m';
  const hrs = Math.floor(minutes / 60);
  const mins = Math.round(minutes % 60);
  if (hrs === 0) return `${mins}m`;
  if (mins === 0) return `${hrs}h`;
  return `${hrs}h ${mins}m`;
}

// Format ISO timestamp to readable date/time ("Sep 12, 2026 • 11:34 PM")
export function formatDateTime(isoString: string): string {
  if (!isoString) return 'N/A';
  try {
    const d = new Date(isoString);
    if (isNaN(d.getTime())) return isoString;
    return d.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    }).replace(',', '');
  } catch {
    return isoString;
  }
}

// Format ISO timestamp to time only ("11:34 PM")
export function formatTimeOnly(isoString: string): string {
  if (!isoString) return 'N/A';
  try {
    const d = new Date(isoString);
    if (isNaN(d.getTime())) return isoString;
    return d.toLocaleString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  } catch {
    return isoString;
  }
}

export function RouteWeather({ 
  rawResponse = rawBackendRouteWeatherResponse, 
  loading = false, 
  error = null,
  onRefresh 
}: RouteWeatherProps) {
  const { convertTemp, tempUnitSymbol } = useUserProfile();
  const [expandedIndex, setExpandedIndex] = useState<number | null>(null);

  const toggleExpand = (idx: number) => {
    setExpandedIndex(expandedIndex === idx ? null : idx);
  };

  if (loading) {
    return (
      <div className="space-y-6 animate-pulse text-white">
        <div className="glass-panel p-6 sm:p-8 rounded-3xl h-48 bg-white/10" />
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 h-24 bg-white/10 rounded-2xl" />
        <div className="glass-panel p-6 rounded-3xl h-96 bg-white/10 space-y-4" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="glass-panel p-8 rounded-3xl text-center space-y-4 border border-rose-500/30 bg-rose-950/20 text-white">
        <AlertTriangle className="w-10 h-10 text-rose-400 mx-auto" />
        <h3 className="text-lg font-bold text-white">Unable to load route weather</h3>
        <p className="text-sm text-white/70">{error}</p>
        {onRefresh && (
          <button 
            onClick={onRefresh}
            className="px-5 py-2 bg-white text-slate-900 font-bold rounded-xl text-xs hover:bg-white/90 cursor-pointer"
          >
            Try Again
          </button>
        )}
      </div>
    );
  }

  // Transform raw backend response using normalizer
  const normalized: NormalizedRouteWeatherResponse | null = transformRouteWeatherResponse(rawResponse);

  if (!normalized || !normalized.places || normalized.places.length === 0) {
    return (
      <div className="glass-panel p-8 rounded-3xl text-center space-y-4 text-white">
        <Navigation className="w-10 h-10 text-sky-300 mx-auto" />
        <h3 className="text-lg font-bold text-white">No Journey Data Available</h3>
        <p className="text-sm text-white/70">
          Enter a source and destination to view weather along your journey.
        </p>
      </div>
    );
  }

  const { route, places, alerts, departureWeather, arrivalWeather } = normalized;
  const totalDistance = route.distanceKm || places[places.length - 1]?.distanceFromStartKm || 1;

  return (
    <div className="space-y-6 sm:space-y-8 animate-in fade-in duration-300 text-white">
      
      {/* ===================================================================== */}
      {/* 1. TOP ROUTE SUMMARY CARD                                             */}
      {/* ===================================================================== */}
      <motion.div 
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="glass-panel relative overflow-hidden p-6 sm:p-8 rounded-3xl border border-white/20 shadow-2xl backdrop-blur-xl bg-slate-900/50"
      >
        <div className="absolute -right-12 -top-12 w-64 h-64 bg-sky-500/10 rounded-full blur-3xl pointer-events-none" />
        
        <div className="relative z-10 space-y-6">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-white/10 pb-4">
            <div className="flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-sky-300">
              <Navigation className="w-4 h-4 text-sky-400" />
              <span>Highway & Trip Safety Planner</span>
            </div>
            <div className="flex items-center gap-2 text-xs text-white/75 font-medium">
              <Clock className="w-3.5 h-3.5 text-white/60" />
              <span>Departure: <strong className="text-white font-bold">{formatDateTime(route.departureTimeIso)}</strong></span>
            </div>
          </div>

          {/* Main Source -> Destination Metrics Row */}
          <div className="flex flex-col sm:flex-row items-center justify-between gap-6 py-2">
            {/* Source */}
            <div className="flex items-center gap-3.5 w-full sm:w-auto">
              <div className="w-12 h-12 rounded-2xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center shrink-0 shadow-xs">
                <MapPin className="w-6 h-6 text-emerald-400" />
              </div>
              <div>
                <span className="text-[10px] font-bold text-emerald-300 uppercase tracking-widest block">SOURCE</span>
                <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">{route.sourceName}</h2>
                <span className="text-[11px] text-white/60 font-medium">
                  {route.sourceLat.toFixed(2)}°, {route.sourceLon.toFixed(2)}°
                </span>
              </div>
            </div>

            {/* Connecting Corridor Metric */}
            <div className="flex-1 w-full sm:w-auto flex flex-col items-center justify-center px-4">
              <div className="flex items-center gap-3 text-xs font-bold text-sky-200 mb-2">
                <span className="px-3 py-1 rounded-full bg-white/10 border border-white/15 shadow-2xs">
                  {route.distanceKm} km
                </span>
                <span>•</span>
                <span className="px-3 py-1 rounded-full bg-white/10 border border-white/15 shadow-2xs">
                  {formatDuration(route.durationMinutes)}
                </span>
              </div>

              {/* Progress Line */}
              <div className="w-full relative flex items-center justify-between">
                <div className="w-3.5 h-3.5 rounded-full bg-emerald-400 border-2 border-slate-900 z-10 shadow-xs" />
                <div className="h-1.5 flex-1 bg-gradient-to-r from-emerald-500 via-sky-400 to-rose-500 rounded-full mx-1 relative overflow-hidden">
                  <div className="absolute inset-0 bg-white/30 animate-pulse" />
                </div>
                <div className="w-3.5 h-3.5 rounded-full bg-rose-400 border-2 border-slate-900 z-10 shadow-xs" />
              </div>
              <span className="text-[10px] text-white/50 font-medium mt-1">Planned Corridor Telemetry</span>
            </div>

            {/* Destination */}
            <div className="flex items-center gap-3.5 w-full sm:w-auto justify-start sm:justify-end">
              <div className="text-left sm:text-right order-2 sm:order-1">
                <span className="text-[10px] font-bold text-rose-300 uppercase tracking-widest block">DESTINATION</span>
                <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">{route.destinationName}</h2>
                <span className="text-[11px] text-white/60 font-medium">
                  {route.destinationLat.toFixed(2)}°, {route.destinationLon.toFixed(2)}°
                </span>
              </div>
              <div className="w-12 h-12 rounded-2xl bg-rose-500/20 border border-rose-500/40 flex items-center justify-center shrink-0 order-1 sm:order-2 shadow-xs">
                <MapPin className="w-6 h-6 text-rose-400" />
              </div>
            </div>
          </div>
        </div>
      </motion.div>

      {/* ===================================================================== */}
      {/* 2. INTERACTIVE ROUTE LEAFLET MAP                                      */}
      {/* ===================================================================== */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="space-y-3"
      >
        <div className="flex items-center justify-between px-1">
          <div className="flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-sky-300">
            <MapPin className="w-4 h-4 text-sky-400" />
            <span>Interactive Polyline Route & Trajectory Map</span>
          </div>
        </div>
        <RouteMapLeaflet route={route} places={places} />
      </motion.div>

      {/* ===================================================================== */}
      {/* 3. DEPARTURE → ARRIVAL WEATHER COMPARISON CARD                        */}
      {/* ===================================================================== */}
      {(departureWeather || arrivalWeather) && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.15 }}
          className="glass-panel p-5 sm:p-6 rounded-3xl border border-white/15 bg-slate-900/40 space-y-3"
        >
          <span className="text-xs font-extrabold uppercase tracking-wider text-sky-300 block">
            Departure ➔ Arrival Weather Comparison
          </span>

          <div className="grid grid-cols-1 sm:grid-cols-11 items-center gap-4 pt-1">
            {/* Departure Weather */}
            <div className="sm:col-span-5 flex items-center gap-3.5 bg-emerald-500/10 p-4 rounded-2xl border border-emerald-500/30">
              <div className="p-2.5 rounded-xl bg-emerald-500/20 border border-emerald-500/40 text-emerald-300 shrink-0">
                {getWeatherIcon(departureWeather?.condition.text, departureWeather?.condition.icon)}
              </div>
              <div className="min-w-0 flex-1">
                <span className="text-[10px] font-bold text-emerald-300 uppercase tracking-widest block">DEPARTURE • {route.sourceName}</span>
                <div className="text-xl font-black text-white flex items-center gap-2">
                  <span>{departureWeather ? `${convertTemp(departureWeather.temperatureC)}${tempUnitSymbol}` : 'N/A'}</span>
                  <span className="text-xs font-semibold text-white/80">{departureWeather?.condition.text || 'Clear'}</span>
                </div>
                {departureWeather?.humidity !== undefined && (
                  <span className="text-[11px] text-white/60">Humidity: {departureWeather.humidity}% • Wind: {departureWeather.windSpeedKph} km/h</span>
                )}
              </div>
            </div>

            {/* Connecting Arrow */}
            <div className="sm:col-span-1 flex justify-center py-1 sm:py-0">
              <div className="w-8 h-8 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-sky-300">
                <ArrowRight className="w-4 h-4 rotate-90 sm:rotate-0" />
              </div>
            </div>

            {/* Arrival Weather */}
            <div className="sm:col-span-5 flex items-center gap-3.5 bg-rose-500/10 p-4 rounded-2xl border border-rose-500/30">
              <div className="p-2.5 rounded-xl bg-rose-500/20 border border-rose-500/40 text-rose-300 shrink-0">
                {getWeatherIcon(arrivalWeather?.condition.text, arrivalWeather?.condition.icon)}
              </div>
              <div className="min-w-0 flex-1">
                <span className="text-[10px] font-bold text-rose-300 uppercase tracking-widest block">ARRIVAL • {route.destinationName}</span>
                <div className="text-xl font-black text-white flex items-center gap-2">
                  <span>{arrivalWeather ? `${convertTemp(arrivalWeather.temperatureC)}${tempUnitSymbol}` : 'N/A'}</span>
                  <span className="text-xs font-semibold text-white/80">{arrivalWeather?.condition.text || 'Clear'}</span>
                </div>
                {arrivalWeather?.humidity !== undefined && (
                  <span className="text-[11px] text-white/60">Humidity: {arrivalWeather.humidity}% • Wind: {arrivalWeather.windSpeedKph} km/h</span>
                )}
              </div>
            </div>
          </div>
        </motion.div>
      )}

      {/* ===================================================================== */}
      {/* 4. PROMINENT ALERTS SECTION (Rendered ONLY if alerts > 0)             */}
      {/* ===================================================================== */}
      {alerts && alerts.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="glass-panel p-6 rounded-3xl border border-amber-500/40 bg-amber-950/20 text-white space-y-4 shadow-xl"
        >
          <div className="flex items-center gap-2 text-amber-300 font-extrabold text-sm uppercase tracking-wider border-b border-amber-500/25 pb-3">
            <AlertTriangle className="w-5 h-5 text-amber-400" />
            <span>⚠ JOURNEY WEATHER ALERTS ({alerts.length})</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
            {alerts.map((alert, i) => (
              <div key={i} className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 space-y-1.5">
                <div className="flex items-center justify-between gap-2">
                  <h4 className="font-extrabold text-xs text-amber-200 flex items-center gap-1.5">
                    <span>{alert.title}</span>
                    {alert.place && <span className="text-amber-300">({alert.place})</span>}
                  </h4>
                  <span className="text-[9px] font-extrabold px-2 py-0.5 rounded-full bg-amber-500/25 text-amber-200 border border-amber-500/40 uppercase">
                    {alert.severity}
                  </span>
                </div>
                <p className="text-xs text-amber-100/90 leading-relaxed">
                  {alert.description}
                </p>
                {(alert.startTime || alert.endTime) && (
                  <span className="text-[10px] text-amber-300/80 font-medium block">
                    Time Window: {alert.startTime ? formatTimeOnly(alert.startTime) : 'Start'} – {alert.endTime ? formatTimeOnly(alert.endTime) : 'End'}
                  </span>
                )}
              </div>
            ))}
          </div>
        </motion.div>
      )}

      {/* ===================================================================== */}
      {/* 5. WEATHER ALONG YOUR JOURNEY TIMELINE                                */}
      {/* ===================================================================== */}
      <div className="space-y-4">
        <div className="flex items-center justify-between px-1">
          <div>
            <h3 className="text-xl font-black text-white tracking-tight flex items-center gap-2">
              <span>Weather Along Your Journey</span>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-white/15 text-sky-200 border border-white/20">
                {places.length} Waypoints
              </span>
            </h3>
            <p className="text-xs text-white/60 mt-0.5">
              Sequential travel corridor telemetry from {route.sourceName} to {route.destinationName}
            </p>
          </div>
        </div>

        {/* Vertical Journey Timeline Wrapper */}
        <div className="relative pl-6 sm:pl-8 space-y-4 sm:space-y-6 before:absolute before:left-3 sm:before:left-4 before:top-4 before:bottom-4 before:w-0.5 before:bg-gradient-to-b before:from-emerald-400 before:via-sky-400 before:to-rose-400">
          {places.map((place, index) => {
            const isSource = place.type === 'source' || index === 0;
            const isDestination = place.type === 'destination' || index === places.length - 1;
            const isExpanded = expandedIndex === index;
            const weather = place.weather;
            
            const progressPct = Math.min(100, Math.max(0, Math.round((place.distanceFromStartKm / totalDistance) * 100)));
            const wptNumber = (index + 1).toString().padStart(2, '0');

            return (
              <motion.div
                key={`${place.name}-${index}`}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.03 }}
                className="relative"
              >
                {/* Timeline Connector Marker Icon */}
                <div 
                  className={`absolute -left-6 sm:-left-8 top-5 -translate-x-1/2 w-6 h-6 sm:w-7 sm:h-7 rounded-full border-2 border-slate-900 flex items-center justify-center text-[10px] font-extrabold z-20 shadow-md ${
                    isSource 
                      ? 'bg-emerald-500 text-slate-950 ring-4 ring-emerald-500/20' 
                      : isDestination 
                      ? 'bg-rose-500 text-white ring-4 ring-rose-500/20'
                      : 'bg-sky-500 text-slate-950 ring-2 ring-sky-500/20'
                  }`}
                >
                  {wptNumber}
                </div>

                {/* Waypoint Card Container */}
                <div 
                  onClick={() => toggleExpand(index)}
                  className={`glass-panel p-4 sm:p-5 rounded-3xl border transition-all cursor-pointer hover:border-white/30 backdrop-blur-xl ${
                    isSource 
                      ? 'border-emerald-500/40 bg-emerald-950/10' 
                      : isDestination 
                      ? 'border-rose-500/40 bg-rose-950/10'
                      : 'border-white/15 bg-slate-900/35'
                  }`}
                >
                  <div className="space-y-3">
                    
                    {/* Header Row: [01] Morbi [SOURCE] | Distance & ETA */}
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-white/10 pb-2.5">
                      <div className="flex items-center gap-2.5 flex-wrap">
                        <span className="text-xs font-mono font-bold text-white/50">[{wptNumber}]</span>
                        <h4 className="text-base sm:text-lg font-extrabold text-white tracking-tight">
                          {place.name}
                        </h4>
                        
                        <span className={`text-[9px] font-extrabold px-2.5 py-0.5 rounded-full uppercase tracking-wider border ${
                          isSource 
                            ? 'bg-emerald-500/25 text-emerald-300 border-emerald-500/40' 
                            : isDestination 
                            ? 'bg-rose-500/25 text-rose-300 border-rose-500/40' 
                            : 'bg-sky-500/20 text-sky-200 border-sky-500/30'
                        }`}>
                          {isSource ? 'SOURCE' : isDestination ? 'DESTINATION' : 'ROUTE PLACE'}
                        </span>

                        {/* Cached Weather Badge */}
                        {weather?.isStale && (
                          <span className="text-[9px] font-extrabold px-2 py-0.5 rounded-full uppercase tracking-wider bg-amber-500/25 text-amber-200 border border-amber-500/40 flex items-center gap-1">
                            <CloudOff className="w-3 h-3 text-amber-300" /> Cached Weather
                          </span>
                        )}
                      </div>

                      <div className="flex items-center gap-3 text-xs text-white/80 font-medium">
                        <span className="font-semibold">{place.distanceFromStartKm} km</span>
                        <span>•</span>
                        <span className="text-sky-300 font-bold">
                          {isSource ? 'Departure ' : 'ETA '}{formatTimeOnly(place.estimatedArrivalIso)}
                        </span>
                      </div>
                    </div>

                    {/* Main Weather Information Display */}
                    {weather ? (
                      <div className="grid grid-cols-1 md:grid-cols-12 gap-4 items-center pt-1">
                        
                        {/* Left: Condition Icon, Large Temp & Condition Text */}
                        <div className="md:col-span-5 flex items-center gap-3.5">
                          <div className="p-3 rounded-2xl bg-white/10 border border-white/15 shrink-0 shadow-xs">
                            {getWeatherIcon(weather.condition.text, weather.condition.icon)}
                          </div>
                          <div>
                            <div className="flex items-baseline gap-2">
                              <span className="text-2xl sm:text-3xl font-black text-white tracking-tight">
                                {convertTemp(weather.temperatureC)}{tempUnitSymbol}
                              </span>
                              {weather.feelsLikeC !== undefined && (
                                <span className="text-xs text-white/60 font-medium">
                                  Feels like {convertTemp(weather.feelsLikeC)}{tempUnitSymbol}
                                </span>
                              )}
                            </div>
                            <span className="text-xs font-bold text-sky-200 block">
                              {weather.condition.text}
                            </span>
                          </div>
                        </div>

                        {/* Right: 4 Primary Metrics Grid (Humidity, Wind, Rain, Visibility) */}
                        <div className="md:col-span-7 grid grid-cols-2 sm:grid-cols-4 gap-2">
                          
                          {/* Humidity */}
                          {weather.humidity !== undefined && (
                            <div className="bg-white/5 px-3 py-2 rounded-xl border border-white/10 flex items-center gap-2">
                              <Droplets className="w-3.5 h-3.5 text-blue-400 shrink-0" />
                              <div>
                                <span className="text-[9px] text-white/50 block font-medium">Humidity</span>
                                <span className="text-xs font-bold text-white">{weather.humidity}%</span>
                              </div>
                            </div>
                          )}

                          {/* Wind */}
                          {weather.windSpeedKph !== undefined && (
                            <div className="bg-white/5 px-3 py-2 rounded-xl border border-white/10 flex items-center gap-2">
                              <Wind className="w-3.5 h-3.5 text-teal-300 shrink-0" />
                              <div>
                                <span className="text-[9px] text-white/50 block font-medium">Wind</span>
                                <span className="text-xs font-bold text-white">{weather.windSpeedKph} km/h</span>
                              </div>
                            </div>
                          )}

                          {/* Rain Chance */}
                          {weather.rainProbability !== undefined && (
                            <div className="bg-white/5 px-3 py-2 rounded-xl border border-white/10 flex items-center gap-2">
                              <Umbrella className="w-3.5 h-3.5 text-amber-300 shrink-0" />
                              <div>
                                <span className="text-[9px] text-white/50 block font-medium">Rain Chance</span>
                                <span className="text-xs font-bold text-amber-200">{weather.rainProbability}%</span>
                              </div>
                            </div>
                          )}

                          {/* Visibility */}
                          {weather.visibilityKm !== undefined && (
                            <div className="bg-white/5 px-3 py-2 rounded-xl border border-white/10 flex items-center gap-2">
                              <Eye className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                              <div>
                                <span className="text-[9px] text-white/50 block font-medium">Visibility</span>
                                <span className="text-xs font-bold text-white">{weather.visibilityKm} km</span>
                              </div>
                            </div>
                          )}

                        </div>

                      </div>
                    ) : (
                      /* Weather Unavailable Clean Placeholder */
                      <div className="flex items-center justify-between p-3 rounded-2xl bg-white/5 border border-white/10 text-white/60">
                        <div className="flex items-center gap-2.5 text-xs">
                          <CloudOff className="w-4 h-4 text-white/40" />
                          <span className="font-semibold italic">Weather data not available for this waypoint</span>
                        </div>
                        <span className="text-[10px] text-white/40">ETA {formatTimeOnly(place.estimatedArrivalIso)}</span>
                      </div>
                    )}

                    {/* Drawer Expander Toggle */}
                    <div className="flex items-center justify-between pt-1 border-t border-white/5">
                      <span className="text-[10px] text-white/50 font-medium">
                        {progressPct}% route distance completed
                      </span>
                      <button className="text-[11px] font-semibold text-sky-300 hover:underline flex items-center gap-1">
                        <span>{isExpanded ? 'Hide Details' : 'More Details'}</span>
                        {isExpanded ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
                      </button>
                    </div>

                  </div>

                  {/* Expanded Waypoint Details Drawer */}
                  <AnimatePresence>
                    {isExpanded && (
                      <motion.div
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: 'auto' }}
                        exit={{ opacity: 0, height: 0 }}
                        className="mt-3 pt-3 border-t border-white/10 text-xs text-white/80 space-y-2 overflow-hidden"
                      >
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                          <div className="bg-white/5 p-2.5 rounded-xl border border-white/10">
                            <span className="text-[10px] text-white/50 block font-medium">Coordinates</span>
                            <span className="font-bold text-white">{place.latitude.toFixed(4)}°, {place.longitude.toFixed(4)}°</span>
                          </div>

                          <div className="bg-white/5 p-2.5 rounded-xl border border-white/10">
                            <span className="text-[10px] text-white/50 block font-medium">Estimated Arrival</span>
                            <span className="font-bold text-white">{formatDateTime(place.estimatedArrivalIso)}</span>
                          </div>

                          {weather?.uvIndex !== undefined && (
                            <div className="bg-white/5 p-2.5 rounded-xl border border-white/10">
                              <span className="text-[10px] text-white/50 block font-medium">UV Index</span>
                              <span className="font-bold text-amber-300">UV {weather.uvIndex}</span>
                            </div>
                          )}

                          {weather?.pressureMb !== undefined && (
                            <div className="bg-white/5 p-2.5 rounded-xl border border-white/10">
                              <span className="text-[10px] text-white/50 block font-medium">Pressure</span>
                              <span className="font-bold text-white">{weather.pressureMb} mb</span>
                            </div>
                          )}

                          {weather?.precipitationMm !== undefined && (
                            <div className="bg-white/5 p-2.5 rounded-xl border border-white/10">
                              <span className="text-[10px] text-white/50 block font-medium">Precipitation</span>
                              <span className="font-bold text-sky-300">{weather.precipitationMm} mm</span>
                            </div>
                          )}
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>

                </div>
              </motion.div>
            );
          })}
        </div>
      </div>

    </div>
  );
}
