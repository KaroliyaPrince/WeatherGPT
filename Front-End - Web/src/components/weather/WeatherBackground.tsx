import React from 'react';

interface WeatherBackgroundProps {
  condition?: string;
  isNight?: boolean;
  children: React.ReactNode;
  className?: string;
}

export const WeatherBackground: React.FC<WeatherBackgroundProps> = ({
  condition = '',
  isNight = false,
  children,
  className = '',
}) => {
  const getGradientClass = () => {
    if (isNight) return 'sky-gradient-night';
    const c = (condition || '').toLowerCase();
    if (c.includes('thunder') || c.includes('storm')) return 'sky-gradient-thunderstorm';
    if (c.includes('rain') || c.includes('drizzle')) return 'sky-gradient-rain';
    if (c.includes('cloud')) return 'sky-gradient-cloudy';
    if (c.includes('sun') || c.includes('clear')) return 'sky-gradient-sunny';
    return 'sky-gradient-default';
  };

  return (
    <div className={`relative min-h-screen w-full transition-all duration-700 ${getGradientClass()} ${className}`}>
      {/* Soft Floating Atmospheric Clouds / Lighting Layer */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden z-0">
        {/* Top-right ambient sunlight / moon glow */}
        <div className="absolute -top-24 -right-24 w-96 h-96 rounded-full bg-white/10 blur-3xl" />
        
        {/* Soft cloud shapes in upper atmosphere */}
        <div className="absolute top-10 left-1/4 w-[500px] h-[180px] bg-white/[0.08] rounded-full blur-3xl animate-cloud-drift pointer-events-none" />
        <div className="absolute top-36 -left-20 w-[600px] h-[220px] bg-white/[0.05] rounded-full blur-3xl animate-cloud-drift-slow pointer-events-none" />
        <div className="absolute top-64 right-10 w-[450px] h-[160px] bg-white/[0.06] rounded-full blur-3xl animate-cloud-drift pointer-events-none" />
      </div>

      {/* Main Content Layer */}
      <div className="relative z-10">
        {children}
      </div>
    </div>
  );
};
