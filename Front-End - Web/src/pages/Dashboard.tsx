import { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Calendar, 
  Clock, 
  Search, 
  Compass, 
  Download, 
  RefreshCw, 
  AlertTriangle,
  MapPin,
  Loader2
} from 'lucide-react';
import { getWeatherData } from '../services/weatherService';
import { getUserLocation, reverseGeocodeLocation } from '../services/weatherGptApi';
import { format } from 'date-fns';
import { useUserProfile } from '../hooks/useUserProfile';
import { useWeatherAlerts } from '../hooks/useWeatherAlerts';
import { exportWeatherPDF } from '../utils/exportReports';
import { useMagnetic } from '../utils/gsapEffects';
import { motion, AnimatePresence } from 'motion/react';
import { INDIAN_CITIES } from '../data/indianCities';

// New Glass Weather Components
import { WeatherHero } from '../components/weather/WeatherHero';
import { HourlyTemperatureChart } from '../components/weather/HourlyTemperatureChart';
import { DailyForecastGlass } from '../components/weather/DailyForecastGlass';
import { WeatherDetailsGrid } from '../components/weather/WeatherDetailsGrid';
import { WeatherAlertsGlass } from '../components/weather/WeatherAlertsGlass';
import { Last7DaysHistoryGlass } from '../components/weather/Last7DaysHistoryGlass';

function DashboardSkeleton() {
  return (
    <div className="space-y-6 pb-8 animate-pulse text-white">
      <div className="flex flex-col sm:flex-row justify-between gap-4">
        <div className="space-y-2">
          <div className="h-8 w-56 bg-white/15 rounded-2xl" />
          <div className="h-4 w-40 bg-white/10 rounded-lg" />
        </div>
        <div className="flex gap-2">
          <div className="h-10 w-28 bg-white/15 rounded-xl" />
          <div className="h-10 w-36 bg-white/15 rounded-xl" />
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-4 h-96 bg-white/15 rounded-3xl" />
        <div className="lg:col-span-8 h-96 bg-white/15 rounded-3xl" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-6 h-80 bg-white/15 rounded-3xl" />
        <div className="lg:col-span-6 h-80 bg-white/15 rounded-3xl" />
      </div>
    </div>
  );
}

function DashboardErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="my-16 p-8 sm:p-12 glass-panel rounded-4xl max-w-md mx-auto text-center space-y-5 text-white">
      <div className="w-16 h-16 bg-white/15 text-rose-300 rounded-3xl flex items-center justify-center mx-auto border border-white/20">
        <AlertTriangle className="w-8 h-8" />
      </div>
      <div>
        <h3 className="text-xl font-bold text-white">Weather data unavailable</h3>
        <p className="text-sm text-white/70 mt-1 leading-relaxed">
          Unable to fetch latest forecast details. Please try again.
        </p>
      </div>
      <button
        onClick={onRetry}
        className="px-6 py-2.5 bg-white text-[#1D4ED8] font-bold rounded-2xl hover:bg-white/90 transition-all shadow-md cursor-pointer inline-flex items-center gap-2 text-sm"
      >
        <RefreshCw className="w-4 h-4" />
        <span>Retry</span>
      </button>
    </div>
  );
}

export default function Dashboard() {
  const navigate = useNavigate();
  const { convertTemp, tempUnitSymbol, profile, updateProfile } = useUserProfile();
  const { alerts, apiMessage, activeLocation, updateAlertsForLocation } = useWeatherAlerts();

  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [citySearch, setCitySearch] = useState('');
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [timelineTab, setTimelineTab] = useState<'forecast' | 'history'>('forecast');
  const [isLocating, setIsLocating] = useState(false);
  const [locateError, setLocateError] = useState('');
  const searchContainerRef = useRef<HTMLDivElement>(null);

  const handleDetectLocation = async () => {
    setIsLocating(true);
    setLocateError('');

    try {
      const coords = await getUserLocation();
      if (!coords) {
        setLocateError('Unable to access GPS location. Please check location permissions.');
        setIsLocating(false);
        return;
      }

      let detectedCity = '';
      try {
        const geoRes = await reverseGeocodeLocation(coords.latitude, coords.longitude);
        if (geoRes && geoRes.city) {
          detectedCity = geoRes.city;
        }
      } catch (e) {
        console.warn('Backend reverse geocode failed, using Nominatim fallback:', e);
      }

      if (!detectedCity) {
        try {
          const osmRes = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${coords.latitude}&lon=${coords.longitude}`);
          if (osmRes.ok) {
            const data = await osmRes.json();
            detectedCity = data.address?.city || data.address?.town || data.address?.village || data.address?.county || data.address?.state_district || '';
          }
        } catch (e) {
          console.warn('Nominatim reverse geocode failed:', e);
        }
      }

      if (detectedCity) {
        updateProfile({ location: detectedCity });
      } else {
        const coordStr = `${coords.latitude.toFixed(4)},${coords.longitude.toFixed(4)}`;
        updateProfile({ location: coordStr });
      }
    } catch (err: any) {
      setLocateError(err.message || 'Geolocation detection failed.');
    } finally {
      setIsLocating(false);
    }
  };

  // Filter suggestions dynamically from the comprehensive Indian cities dataset
  const filteredSuggestions = citySearch.trim()
    ? (() => {
        const query = citySearch.trim().toLowerCase();
        // Exact prefix match on name first, then name contains, then state contains
        const startsWithName: typeof INDIAN_CITIES = [];
        const containsInName: typeof INDIAN_CITIES = [];
        const containsInRegion: typeof INDIAN_CITIES = [];

        for (const city of INDIAN_CITIES) {
          const nameLower = city.name.toLowerCase();
          const regionLower = city.region.toLowerCase();

          if (nameLower.startsWith(query)) {
            startsWithName.push(city);
          } else if (nameLower.includes(query)) {
            containsInName.push(city);
          } else if (regionLower.includes(query)) {
            containsInRegion.push(city);
          }
        }

        return [...startsWithName, ...containsInName, ...containsInRegion].slice(0, 8);
      })()
    : [];

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        searchContainerRef.current &&
        !searchContainerRef.current.contains(event.target as Node)
      ) {
        setShowSuggestions(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Magnetic button hook via GSAP
  const locationBtnRef = useMagnetic(0.25);

  const fetchWeather = () => {
    setLoading(true);
    setError(false);
    const city = profile.location || 'Rajkot';
    getWeatherData(city)
      .then((res) => {
        if (!res || !res.current) {
          setError(true);
          setLoading(false);
          return;
        }
        setData(res);
        setLoading(false);
        updateAlertsForLocation(city, res);
      })
      .catch(() => {
        setError(true);
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchWeather();
  }, [profile.location]);

  const handleSelectCity = (cityName: string) => {
    updateProfile({ location: cityName });
    setCitySearch('');
    setShowSuggestions(false);
  };

  const handleCitySearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!citySearch.trim()) return;
    if (filteredSuggestions.length > 0) {
      handleSelectCity(filteredSuggestions[0].name);
    } else {
      updateProfile({ location: citySearch.trim() });
      setCitySearch('');
      setShowSuggestions(false);
    }
  };

  if (loading) {
    return <DashboardSkeleton />;
  }

  if (error || !data) {
    return <DashboardErrorState onRetry={fetchWeather} />;
  }

  const displayLocation = profile.location || `${data.location.name}, ${data.location.region || data.location.country}`;
  const currentLocationName = profile.location?.split(',')[0] || data.location.name || 'Morvi';

  return (
    <div className="relative space-y-6 sm:space-y-8 pb-12 animate-in fade-in duration-500">
      {locateError && (
        <div className="p-3 bg-rose-500/20 border border-rose-400/30 rounded-2xl text-xs text-rose-200 flex items-center justify-between gap-2 backdrop-blur-md">
          <span>{locateError}</span>
          <button 
            onClick={() => setLocateError('')}
            className="text-rose-300 hover:text-white font-bold cursor-pointer px-1.5 py-0.5 rounded-md hover:bg-rose-500/30"
          >
            ✕
          </button>
        </div>
      )}
      
      {/* Top Header & Search Bar Row */}
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 text-white"
      >
        {/* Date, Time & Coordinates */}
        <div className="flex items-center gap-4 text-xs sm:text-sm text-white/80 font-medium">
          <div className="flex items-center gap-1.5">
            <Calendar className="w-3.5 h-3.5 text-white/70" />
            <span>{format(new Date(), 'EEEE, do MMM')}</span>
          </div>
          <div className="flex items-center gap-1.5">
            <Clock className="w-3.5 h-3.5 text-white/70" />
            <span>{format(new Date(), 'h:mm a')}</span>
          </div>
        </div>

        {/* Action Controls: Search, My Location, 3D Radar, Export PDF */}
        <div className="flex items-center gap-2.5 flex-wrap w-full md:w-auto justify-start md:justify-end">
          {/* Quick City Search Bar with Suggestions */}
          <div ref={searchContainerRef} className="relative flex-1 sm:flex-initial">
            <form onSubmit={handleCitySearchSubmit} className="relative flex items-center">
              <Search className="absolute left-3.5 w-3.5 h-3.5 text-white/50 pointer-events-none" />
              <input
                type="text"
                value={citySearch}
                onFocus={() => setShowSuggestions(true)}
                onChange={(e) => {
                  setCitySearch(e.target.value);
                  setShowSuggestions(true);
                }}
                placeholder="Search city..."
                className="w-full sm:w-44 lg:w-56 pl-9 pr-3 py-1.5 text-xs rounded-full glass-input transition-all"
              />
            </form>

            {/* Suggestions Dropdown */}
            <AnimatePresence>
              {showSuggestions && filteredSuggestions.length > 0 && (
                <motion.div
                  initial={{ opacity: 0, y: 6, scale: 0.96 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: 6, scale: 0.96 }}
                  transition={{ duration: 0.15 }}
                  className="absolute left-0 right-0 mt-2 py-1.5 bg-slate-900/95 backdrop-blur-2xl border border-white/20 rounded-2xl shadow-2xl overflow-hidden z-50 min-w-[220px] max-h-64 overflow-y-auto"
                >
                  <div className="px-3 py-1.5 flex items-center justify-between text-[10px] font-semibold text-white/40 uppercase tracking-wider border-b border-white/10">
                    <span>Indian Cities</span>
                    <span>{filteredSuggestions.length} found</span>
                  </div>
                  {filteredSuggestions.map((item) => (
                    <button
                      key={`${item.name}-${item.region}`}
                      type="button"
                      onClick={() => handleSelectCity(item.name)}
                      className="w-full px-3 py-2 text-left text-xs text-white/90 hover:bg-white/15 flex items-center justify-between transition-colors cursor-pointer group"
                    >
                      <div className="flex items-center gap-2 min-w-0">
                        <MapPin className="w-3.5 h-3.5 text-sky-400 shrink-0 group-hover:scale-110 transition-transform" />
                        <span className="font-semibold text-white truncate">{item.name}</span>
                      </div>
                      <span className="text-[10px] text-white/50 ml-2 shrink-0 truncate">
                        {item.region}
                      </span>
                    </button>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Detect Current Location Button */}
          <button
            ref={locationBtnRef}
            onClick={handleDetectLocation}
            disabled={isLocating}
            className="px-3.5 py-1.5 rounded-full text-xs font-bold transition-all glass-pill hover:bg-white/20 text-white flex items-center gap-1.5 cursor-pointer shadow-xs disabled:opacity-50 disabled:cursor-not-allowed"
            title="Detect current location"
          >
            {isLocating ? (
              <Loader2 className="w-3.5 h-3.5 text-sky-200 animate-spin" />
            ) : (
              <Compass className="w-3.5 h-3.5 text-sky-200" />
            )}
            <span className="hidden sm:inline">{isLocating ? 'Detecting...' : 'My Location'}</span>
          </button>

          {/* Export PDF Weather Report */}
          <button
            onClick={() => exportWeatherPDF({
              location: displayLocation,
              date: format(new Date(), 'EEEE, do MMM yyyy'),
              temp: `${convertTemp(data.current.temp_c)}${tempUnitSymbol}`,
              condition: data.current.condition.text,
              humidity: data.current.humidity,
              wind: `${data.current.wind_kph} km/h NW`,
              pressure: `${data.current.pressure_mb} mb`,
              uv: data.current.uv,
              rainChance: data.forecast[0].chance_of_rain,
              forecast: data.forecast.map((f: any) => ({
                day: f.day,
                date: f.date,
                maxTemp: `${convertTemp(f.max_temp)}°`,
                minTemp: `${convertTemp(f.min_temp)}°`,
                condition: f.condition,
                rainChance: f.chance_of_rain
              }))
            })}
            className="px-3.5 py-1.5 glass-pill hover:bg-white/20 text-white rounded-full text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer"
            title="Download formatted PDF weather report"
          >
            <Download className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Export PDF</span>
          </button>
        </div>
      </motion.div>

      {/* ===================================================================== */}
      {/* FEATURE PROMO BANNER: SOURCE -> DESTINATION WEATHER FEATURE           */}
      {/* ===================================================================== */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="glass-panel p-4 sm:p-5 rounded-3xl border border-sky-400/30 bg-gradient-to-r from-sky-900/40 via-blue-900/30 to-indigo-900/40 backdrop-blur-xl flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-white shadow-xl cursor-pointer hover:border-sky-400/50 transition-all"
        onClick={() => navigate('/travel')}
      >
        <div className="flex items-center gap-3.5">
          <div className="w-12 h-12 rounded-2xl bg-sky-500/20 border border-sky-400/40 flex items-center justify-center text-sky-300 shrink-0 shadow-xs">
            <Compass className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-sky-400/25 text-sky-200 border border-sky-400/30 uppercase tracking-wider">
                New Feature
              </span>
              <h3 className="text-base sm:text-lg font-extrabold text-white tracking-tight">
                Source ➔ Destination Weather
              </h3>
            </div>
            <p className="text-xs text-white/80 mt-0.5">
              Plan your travel corridor with live arrival-time weather forecasts along Morbi ➔ Surat, Mumbai ➔ Pune, & all Indian routes.
            </p>
          </div>
        </div>
        <button
          onClick={(e) => {
            e.stopPropagation();
            navigate('/travel');
          }}
          className="px-4 py-2 bg-white text-slate-900 font-extrabold rounded-2xl text-xs hover:bg-white/90 transition-all cursor-pointer shrink-0 shadow-md flex items-center gap-1.5"
        >
          <span>View Route Weather</span>
          <span className="text-sm">→</span>
        </button>
      </motion.div>

      {/* ===================================================================== */}
      {/* ROW 1: CURRENT WEATHER HERO & HOURLY FORECAST + TEMPERATURE CHART     */}
      {/* ===================================================================== */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        
        {/* LEFT: Current Weather Hero (Seamless Sky Blend) */}
        <div className="lg:col-span-4 h-full">
          <WeatherHero
            className="h-full"
            locationName={currentLocationName}
            region={data.location.region || data.location.country}
            condition={data.current.condition.text}
            temp={convertTemp(data.current.temp_c)}
            tempUnit={tempUnitSymbol}
            minTemp={convertTemp(data.forecast[0].min_temp)}
            maxTemp={convertTemp(data.forecast[0].max_temp)}
            feelsLike={convertTemp(data.current.feelslike_c)}
            pm25={13}
            isStale={Boolean(data.current?.is_stale)}
          />
        </div>

        {/* CENTER / RIGHT: Hourly Forecast & Smooth Temperature Spline Curve */}
        <div className="lg:col-span-8 h-full">
          <HourlyTemperatureChart
            className="h-full"
            hourlyData={data.hourly}
            convertTemp={convertTemp}
            tempUnit={tempUnitSymbol}
          />
        </div>
      </div>

      {/* ===================================================================== */}
      {/* ROW 2: TIMELINE (7-DAY FORECAST / LAST 7 DAYS HISTORY) & METRICS      */}
      {/* ===================================================================== */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        
        {/* 7-Day Forecast or Past 7 Days History */}
        <div className="lg:col-span-7 h-full">
          <AnimatePresence mode="wait">
            {timelineTab === 'forecast' ? (
              <motion.div
                key="forecast"
                className="h-full"
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -6 }}
                transition={{ duration: 0.2 }}
              >
                <DailyForecastGlass
                  forecastData={data.forecast}
                  convertTemp={convertTemp}
                  tempUnit={tempUnitSymbol}
                  timelineTab={timelineTab}
                  onSelectTab={setTimelineTab}
                />
              </motion.div>
            ) : (
              <motion.div
                key="history"
                className="h-full"
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -6 }}
                transition={{ duration: 0.2 }}
              >
                <Last7DaysHistoryGlass
                  historyData={data.history7Days || []}
                  convertTemp={convertTemp}
                  tempUnit={tempUnitSymbol}
                  timelineTab={timelineTab}
                  onSelectTab={setTimelineTab}
                />
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Weather Details */}
        <div className="lg:col-span-5 h-full">
          {/* 8 Compact Glass Metric Details */}
          <WeatherDetailsGrid
            feelsLike={convertTemp(data.current.feelslike_c)}
            tempUnit={tempUnitSymbol}
            humidity={data.current.humidity}
            windSpeed={data.current.wind_kph}
            windDirection="NW"
            uvIndex={data.current.uv}
            visibilityKm={data.current.visibility_km}
            pressureMb={data.current.pressure_mb}
            precipMm={data.current.precip_mm || 0.0}
            rainProbability={data.forecast[0].chance_of_rain}
          />
        </div>
      </div>

      {/* ===================================================================== */}
      {/* ROW 3: WEATHER ALERTS                                                 */}
      {/* ===================================================================== */}
      <div className="w-full">
        <WeatherAlertsGlass 
          alerts={alerts} 
          apiMessage={apiMessage} 
          activeLocation={activeLocation || profile.location} 
          className="w-full" 
        />
      </div>



    </div>
  );
}
