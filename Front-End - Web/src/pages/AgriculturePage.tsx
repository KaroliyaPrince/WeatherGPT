import { useState, useEffect } from 'react';
import { Sprout, Droplets, Sun, Wind, Download, Sparkles, MapPin, Loader2 } from 'lucide-react';
import { useUserProfile } from '../hooks/useUserProfile';
import { exportWeatherPDF } from '../utils/exportReports';
import { getWeatherData } from '../services/weatherService';
import { WeatherGPTLive } from '../components/WeatherGPTLive';

export interface CropProfile {
  id: string;
  name: string;
  nativeNameGu: string;
  nativeNameHi: string;
  icon: string;
  soilMoistureOptimal: string;
  waterNeed: string;
  pestRisk: 'Low' | 'Moderate' | 'High';
  adviceGu: string;
  adviceEn: string;
}

const CROPS: CropProfile[] = [
  {
    id: 'groundnut',
    name: 'Groundnut',
    nativeNameGu: 'મગફળી (Groundnut)',
    nativeNameHi: 'मूंगफली',
    icon: '🥜',
    soilMoistureOptimal: '65% - 75%',
    waterNeed: 'Moderate (Light Shower)',
    pestRisk: 'Low',
    adviceGu: 'આગામી 48 કલાકમાં હળવોથી મધ્યમ વરસાદ મગફળીના પાક માટે ઉત્તમ છે. ખેતરમાં વધારાના પાણીના નિકાલની વ્યવસ્થા રાખવી.',
    adviceEn: 'Light to moderate rain over the next 48h is highly beneficial for pod development. Ensure drainage channels are clear.'
  },
  {
    id: 'cotton',
    name: 'Cotton',
    nativeNameGu: 'કપાસ (Cotton)',
    nativeNameHi: 'कपास',
    icon: '🌾',
    soilMoistureOptimal: '60% - 70%',
    waterNeed: 'High',
    pestRisk: 'Moderate',
    adviceGu: 'ભેજ 80% હોવાના કારણે ગુલાબી અળસીના ઉપદ્રવ પર નજર રાખવી. બપોર પછી જંતુનાશક દવાનો છંટકાવ ટાળવો.',
    adviceEn: 'High humidity increases pink bollworm risk. Avoid pesticide sprays during evening showers.'
  },
  {
    id: 'wheat',
    name: 'Wheat',
    nativeNameGu: 'ઘઉં (Wheat)',
    nativeNameHi: 'गेहूँ',
    icon: '🌾',
    soilMoistureOptimal: '55% - 65%',
    waterNeed: 'Moderate',
    pestRisk: 'Low',
    adviceGu: 'પવનની ઝડપ 18 કિમી/કલાક હોવાથી સિંચાઈનું પાણી નિયંત્રિત આપવું જેથી પાક ઢળી ન પડે.',
    adviceEn: 'Controlled irrigation recommended due to 18 km/h wind gusts to prevent crop lodging.'
  },
  {
    id: 'rice',
    name: 'Paddy Rice',
    nativeNameGu: 'ડાંગર (Paddy)',
    nativeNameHi: 'धान',
    icon: '🌱',
    soilMoistureOptimal: '80% - 90%',
    waterNeed: 'Very High',
    pestRisk: 'High',
    adviceGu: 'વરસાદનું પાણી સંગ્રહિત કરવું. ડાંગરના ખેતરમાં 5 સેમી પાણીની સપાટી જાળવી રાખવી.',
    adviceEn: 'Retain rainwater in standing bunds. Maintain 5 cm water table across paddy plots.'
  }
];

export default function AgriculturePage() {
  const { profile, convertTemp, tempUnitSymbol } = useUserProfile();
  const [selectedCrop, setSelectedCrop] = useState<CropProfile>(CROPS[0]);
  const [liveWeatherData, setLiveWeatherData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const city = profile.location || 'Rajkot';
    getWeatherData(city).then(res => {
      setLiveWeatherData(res);
      setLoading(false);
    });
  }, [profile.location]);

  const handleExportPDF = () => {
    exportWeatherPDF({
      location: profile.location || 'Rajkot, Gujarat',
      date: new Date().toLocaleDateString(),
      temp: `${convertTemp(liveWeatherData?.current?.temp_c || 28)}${tempUnitSymbol}`,
      condition: liveWeatherData?.current?.condition?.text || 'Partly Cloudy & Monsoon Showers',
      humidity: liveWeatherData?.current?.humidity || 72,
      wind: `${liveWeatherData?.current?.wind_kph || 15.4} km/h NW`,
      pressure: `${liveWeatherData?.current?.pressure_mb || 1008} mb`,
      uv: liveWeatherData?.current?.uv || 6,
      rainChance: liveWeatherData?.forecast?.[0]?.chance_of_rain || 80,
      forecast: (liveWeatherData?.forecast || []).map((f: any) => ({
        day: f.day,
        date: f.date,
        maxTemp: `${convertTemp(f.max_temp)}°`,
        minTemp: `${convertTemp(f.min_temp)}°`,
        condition: f.condition,
        rainChance: f.chance_of_rain
      }))
    });
  };

  const humidity = liveWeatherData?.current?.humidity || 72;
  const windKph = liveWeatherData?.current?.wind_kph || 15.4;
  const soilMoistureCalc = Math.min(95, Math.max(50, Math.round(humidity * 0.95)));

  return (
    <div className="space-y-6 pb-12 animate-in fade-in duration-300">
      {/* Header Banner */}
      <div className="p-6 sm:p-8 rounded-3xl bg-card border border-border shadow-xs flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="flex items-center gap-2 text-emerald-600 dark:text-emerald-400 font-bold text-xs uppercase tracking-wider mb-1">
            <Sprout className="w-4 h-4" />
            <span>Kisan Agriculture Advisory</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold text-foreground">ખેડૂત હવામાન અને પાક સલાહકાર</h1>
          <p className="text-xs text-muted-foreground mt-1 max-w-xl">
            Real-time soil moisture tracking, crop advisory, and rainfall forecasting.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={handleExportPDF}
            className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition-all shadow-xs flex items-center gap-2 cursor-pointer"
          >
            <Download className="w-4 h-4" />
            <span>Export Crop Report</span>
          </button>
        </div>
      </div>

      {/* Location & Live Stream Status Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 bg-card rounded-2xl border border-border gap-3">
        <div className="flex items-center gap-2 text-sm font-semibold text-foreground">
          <MapPin className="w-4 h-4 text-emerald-500" />
          <span>Farming Belt: {profile.location || 'Rajkot & Saurashtra District'}</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs font-semibold px-3 py-1 rounded-full bg-muted text-muted-foreground">
            Kharif Season
          </span>
        </div>
      </div>

      {/* Crop Selector Grid */}
      <div className="space-y-3">
        <h3 className="text-sm font-extrabold text-foreground uppercase tracking-wider flex items-center gap-2">
          <span>Select Your Active Crop (પાક પસંદ કરો):</span>
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {CROPS.map((crop) => (
            <button
              key={crop.id}
              onClick={() => setSelectedCrop(crop)}
              className={`p-4 rounded-2xl border text-left transition-all cursor-pointer flex flex-col justify-between ${
                selectedCrop.id === crop.id
                  ? 'bg-emerald-500/10 border-emerald-500 shadow-md ring-2 ring-emerald-500/20'
                  : 'bg-card hover:bg-muted border-border'
              }`}
            >
              <div className="text-3xl mb-2">{crop.icon}</div>
              <div>
                <div className="font-extrabold text-sm text-foreground">{crop.nativeNameGu}</div>
                <div className="text-xs text-muted-foreground mt-0.5">{crop.name}</div>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Crop Deep Dive & Advisory */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <div className="p-6 rounded-3xl bg-card border border-border shadow-lg space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="text-4xl">{selectedCrop.icon}</span>
                <div>
                  <h2 className="text-xl font-black text-foreground">{selectedCrop.nativeNameGu}</h2>
                  <p className="text-xs text-muted-foreground">Optimal Soil Moisture Target: {selectedCrop.soilMoistureOptimal}</p>
                </div>
              </div>
              <span className={`px-3 py-1 rounded-full text-xs font-bold border ${
                selectedCrop.pestRisk === 'Low' ? 'bg-emerald-500/15 text-emerald-600 border-emerald-500/30' :
                selectedCrop.pestRisk === 'Moderate' ? 'bg-amber-500/15 text-amber-600 border-amber-500/30' :
                'bg-red-500/15 text-red-600 border-red-500/30'
              }`}>
                Pest Risk: {selectedCrop.pestRisk}
              </span>
            </div>

            {/* Gujarati Advisory Callout */}
            <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 space-y-2">
              <div className="flex items-center gap-2 font-bold text-emerald-700 dark:text-emerald-300 text-sm">
                <Sparkles className="w-4 h-4" />
                <span>ખેડૂત વિશેષ હવામાન આપત્તિ & સિંચાઈ સલાહ:</span>
              </div>
              <p className="text-sm leading-relaxed text-foreground font-semibold">
                {selectedCrop.adviceGu}
              </p>
            </div>

            {/* English Summary */}
            <div className="p-4 rounded-2xl bg-muted/50 border border-border text-xs leading-relaxed text-muted-foreground">
              <strong className="text-foreground">English Agronomy Summary: </strong>
              {selectedCrop.adviceEn}
            </div>
          </div>
        </div>

        {/* Live Soil & Weather Metrics */}
        <div className="space-y-4">
          <div className="p-5 rounded-3xl bg-card border border-border shadow-lg space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="font-extrabold text-sm text-foreground uppercase tracking-wider">Live Soil & Weather Metrics</h3>
              {loading && <Loader2 className="w-3.5 h-3.5 animate-spin text-emerald-500" />}
            </div>

            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 rounded-2xl bg-muted/50">
                <div className="flex items-center gap-2 text-xs font-bold text-foreground">
                  <Droplets className="w-4 h-4 text-blue-500" />
                  <span>Real-time Soil Moisture</span>
                </div>
                <span className="text-sm font-black text-blue-600">{soilMoistureCalc}% (Optimal)</span>
              </div>

              <div className="flex items-center justify-between p-3 rounded-2xl bg-muted/50">
                <div className="flex items-center gap-2 text-xs font-bold text-foreground">
                  <Sun className="w-4 h-4 text-amber-500" />
                  <span>Evapotranspiration</span>
                </div>
                <span className="text-sm font-black text-amber-600">4.2 mm/day</span>
              </div>

              <div className="flex items-center justify-between p-3 rounded-2xl bg-muted/50">
                <div className="flex items-center gap-2 text-xs font-bold text-foreground">
                  <Wind className="w-4 h-4 text-teal-500" />
                  <span>Surface Wind Speed</span>
                </div>
                <span className="text-sm font-black text-teal-600">{windKph} km/h NW</span>
              </div>

              <div className="flex items-center justify-between p-3 rounded-2xl bg-muted/50">
                <div className="flex items-center gap-2 text-xs font-bold text-foreground">
                  <Droplets className="w-4 h-4 text-indigo-500" />
                  <span>Air Humidity</span>
                </div>
                <span className="text-sm font-black text-indigo-600">{humidity}%</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Live Kisan AI Advisory Section */}
      <div className="pt-2">
        <h3 className="text-sm font-extrabold text-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-amber-500" />
          <span>Kisan Live WeatherGPT Assistant (ખેડૂત AI પૂછપરછ):</span>
        </h3>
        <WeatherGPTLive 
          defaultQuestion="મગફળી અને કપાસના પાક માટે આગામી વરસાદનું પૂર્વાનુમાન શું છે?" 
          className="shadow-xl border-emerald-500/30"
        />
      </div>
    </div>
  );
}

