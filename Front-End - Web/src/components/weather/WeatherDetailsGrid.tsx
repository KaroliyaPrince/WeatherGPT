import React from 'react';
import { 
  Droplets, 
  Wind, 
  Sun, 
  Eye, 
  Gauge, 
  CloudRain, 
  Thermometer, 
  Compass 
} from 'lucide-react';

interface WeatherDetailsGridProps {
  feelsLike: number | string;
  tempUnit: string;
  humidity: number;
  windSpeed: number;
  windDirection?: string;
  uvIndex: number;
  visibilityKm: number;
  pressureMb: number;
  precipMm?: number;
  rainProbability?: number;
  className?: string;
}

export const WeatherDetailsGrid: React.FC<WeatherDetailsGridProps> = ({
  feelsLike,
  tempUnit,
  humidity,
  windSpeed,
  windDirection = 'NW',
  uvIndex,
  visibilityKm,
  pressureMb,
  precipMm = 0.0,
  rainProbability = 10,
  className = '',
}) => {
  const getUVDescription = (uv: number) => {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  };

  const getHumidityDescription = (hum: number) => {
    if (hum < 30) return 'Dry';
    if (hum <= 60) return 'Comfortable';
    if (hum <= 80) return 'Humid';
    return 'Very Humid';
  };

  const formattedUnit = tempUnit.startsWith('°') ? tempUnit : `°${tempUnit}`;

  const metrics = [
    {
      label: 'Feels Like',
      value: `${feelsLike}${formattedUnit}`,
      subtext: 'Similar to actual temp',
      icon: Thermometer,
      accent: 'text-orange-300',
    },
    {
      label: 'Humidity',
      value: `${humidity}%`,
      subtext: getHumidityDescription(humidity),
      icon: Droplets,
      accent: 'text-sky-300',
    },
    {
      label: 'Wind',
      value: `${windSpeed} km/h`,
      subtext: `${windDirection} Direction`,
      icon: Wind,
      accent: 'text-teal-300',
    },
    {
      label: 'UV Index',
      value: `${uvIndex}`,
      subtext: getUVDescription(uvIndex),
      icon: Sun,
      accent: 'text-amber-300',
    },
    {
      label: 'Visibility',
      value: `${visibilityKm} km`,
      subtext: visibilityKm >= 10 ? 'Clear distance' : 'Hazy',
      icon: Eye,
      accent: 'text-emerald-300',
    },
    {
      label: 'Pressure',
      value: `${pressureMb} hPa`,
      subtext: 'Steady barometric',
      icon: Gauge,
      accent: 'text-purple-300',
    },
    {
      label: 'Precipitation',
      value: `${precipMm} mm`,
      subtext: 'In last 24 hours',
      icon: CloudRain,
      accent: 'text-blue-300',
    },
    {
      label: 'Rain Probability',
      value: `${rainProbability}%`,
      subtext: rainProbability > 50 ? 'Rain expected' : 'Low chance',
      icon: Compass,
      accent: 'text-cyan-300',
    },
  ];

  return (
    <div className={`glass-panel rounded-3xl p-5 sm:p-6 text-white h-full flex flex-col justify-between ${className}`}>
      <div>
        <h2 className="text-sm sm:text-base font-bold text-white tracking-wide mb-4 flex items-center justify-between">
          <span>Weather Details</span>
          <span className="text-xs font-semibold text-white/60">Live Sensor Feed</span>
        </h2>

        <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-2 gap-3 sm:gap-3.5">
          {metrics.map((m, idx) => {
            const Icon = m.icon;
            return (
              <div
                key={idx}
                className="glass-panel glass-panel-hover p-3.5 rounded-2xl flex flex-col justify-between"
              >
                <div className="flex items-center justify-between text-white/70">
                  <span className="text-xs font-semibold text-white/75">{m.label}</span>
                  <Icon className={`w-4 h-4 ${m.accent}`} />
                </div>
                <div className="mt-2.5">
                  <div className="text-lg sm:text-xl font-extrabold text-white tracking-tight">
                    {m.value}
                  </div>
                  <div className="text-[11px] font-medium text-white/60 truncate mt-0.5">
                    {m.subtext}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
