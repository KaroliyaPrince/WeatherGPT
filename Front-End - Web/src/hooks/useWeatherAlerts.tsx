import React, { createContext, useContext, useState, useEffect, useRef } from 'react';
import { fetchWeatherAlertsApi } from '../services/weatherGptApi';

export interface WeatherAlertItem {
  id: number;
  title: string;
  severity: 'Critical' | 'High' | 'Moderate' | 'Low';
  expected: string;
  description: string;
  type: 'rain' | 'wind' | 'temp' | 'storm';
  location?: string;
  timestamp: string;
  read?: boolean;
}

/**
 * Maps raw backend alert objects from /api/weather/alerts?city=... into WeatherAlertItem
 */
export function mapBackendAlertToItem(item: any, city: string, index: number): WeatherAlertItem {
  const rawSev = (item.severity || item.level || 'Moderate').toString().toLowerCase();
  let severity: 'Critical' | 'High' | 'Moderate' | 'Low' = 'Moderate';
  if (rawSev.includes('extreme') || rawSev.includes('critical') || rawSev.includes('severe')) {
    severity = 'Critical';
  } else if (rawSev.includes('high') || rawSev.includes('warning')) {
    severity = 'High';
  } else if (rawSev.includes('moderate') || rawSev.includes('advisory')) {
    severity = 'Moderate';
  } else if (rawSev.includes('minor') || rawSev.includes('low') || rawSev.includes('watch')) {
    severity = 'Low';
  }

  const rawTitle = item.headline || item.event || item.title || `Weather Warning for ${city}`;
  const rawDesc = item.description || item.instruction || item.summary || `Weather advisory active for ${city} area.`;

  let expectedTime = item.expires
    ? `Until ${new Date(item.expires).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`
    : (item.effective || item.expected || 'Ongoing');

  let alertType: 'rain' | 'wind' | 'temp' | 'storm' = 'storm';
  const titleLower = rawTitle.toLowerCase();
  if (titleLower.includes('rain') || titleLower.includes('flood')) alertType = 'rain';
  else if (titleLower.includes('wind') || titleLower.includes('gale')) alertType = 'wind';
  else if (titleLower.includes('heat') || titleLower.includes('temp') || titleLower.includes('cold')) alertType = 'temp';

  return {
    id: Date.now() + index,
    title: rawTitle,
    severity,
    expected: expectedTime,
    description: rawDesc,
    type: alertType,
    location: item.area || `${city} Region`,
    timestamp: "Just now",
    read: false
  };
}

/**
 * Dynamically generates realistic weather alerts tailored to a specific city and live weather data
 */
export function generateDynamicAlerts(locationStr: string = 'Rajkot', weatherData?: any): WeatherAlertItem[] {
  const city = (locationStr || 'Rajkot').split(',')[0].trim() || 'Rajkot';
  
  const current = weatherData?.current || {};
  const forecast0 = weatherData?.forecast?.[0] || {};
  
  const tempC = Number(current.temp_c ?? 28);
  const feelsLikeC = Number(current.feelslike_c ?? tempC + 1.5);
  const humidity = Number(current.humidity ?? 65);
  const windKph = Number(current.wind_kph ?? 15);
  const precipMm = Number(current.precip_mm ?? 0);
  const rainChance = Number(forecast0.chance_of_rain ?? (precipMm > 0 ? 80 : 20));
  const condText = (current.condition?.text || forecast0.condition || 'Partly Cloudy').toLowerCase();

  const isRainy = rainChance >= 40 || precipMm > 0.5 || condText.includes('rain') || condText.includes('thunder') || condText.includes('shower');
  const isHighWind = windKph >= 18 || condText.includes('thunder') || condText.includes('wind') || condText.includes('squall');
  const isHot = tempC >= 32 || feelsLikeC >= 35;

  const alerts: WeatherAlertItem[] = [];

  // Alert 1: Rain / Hydrological Warning
  if (isRainy) {
    alerts.push({
      id: 1,
      title: rainChance > 70 ? "Heavy Rain & Flash Flood Warning" : "Rain Showers Advisory",
      severity: rainChance > 70 ? "Critical" : "High",
      expected: `Next 2-4 Hours (${rainChance}% rain expected)`,
      description: `Severe downpour detected over ${city}. High risk of localized waterlogging on major roads. Stay indoors and carry waterproof gear!`,
      type: "rain",
      location: `${city} Urban Area`,
      timestamp: "Just now",
      read: false
    });
  } else {
    alerts.push({
      id: 1,
      title: "Normal Weather Watch",
      severity: "Low",
      expected: "Next 24 Hours",
      description: `No severe weather hazards currently active for ${city}. Atmospheric conditions remain stable and clear.`,
      type: "rain",
      location: `${city}`,
      timestamp: "Just now",
      read: true
    });
  }

  // Alert 2: Wind & Thunderstorm Advisory
  if (isHighWind) {
    alerts.push({
      id: 2,
      title: "Strong Wind & Thunderstorm Advisory",
      severity: windKph > 25 ? "High" : "Moderate",
      expected: "Ongoing until 10:00 PM",
      description: `Severe wind gusts up to ${Math.round(windKph * 1.4)} km/h with thunderstorm activity near ${city}. Secure loose rooftop objects and outdoor equipment.`,
      type: "wind",
      location: `${city} Surrounding Area`,
      timestamp: "25 mins ago",
      read: false
    });
  } else {
    alerts.push({
      id: 2,
      title: "Moderate Wind Advisory",
      severity: "Low",
      expected: "Throughout Today",
      description: `Gentle breeze recorded at ${Math.round(windKph)} km/h in ${city}. Wind speeds remain within safe limits.`,
      type: "wind",
      location: `${city}`,
      timestamp: "30 mins ago",
      read: true
    });
  }

  // Alert 3: Temperature & Heat Advisory
  if (isHot) {
    alerts.push({
      id: 3,
      title: "Extreme Temperature Advisory",
      severity: tempC >= 36 ? "Critical" : "High",
      expected: "Peak Hours (12:00 PM – 4:00 PM)",
      description: `Heat index in ${city} expected to touch ${Math.round(feelsLikeC)}°C with ${humidity}% humidity. Ensure hydration during afternoon outdoor work.`,
      type: "temp",
      location: `${city} Region`,
      timestamp: "1 hour ago",
      read: false
    });
  } else {
    alerts.push({
      id: 3,
      title: "Comfortable Thermal Watch",
      severity: "Low",
      expected: "Today",
      description: `Current temperature in ${city} is ${Math.round(tempC)}°C with ${humidity}% relative humidity. Comfortable thermal conditions overall.`,
      type: "temp",
      location: `${city}`,
      timestamp: "2 hours ago",
      read: true
    });
  }

  return alerts;
}

export const DEFAULT_ALERTS: WeatherAlertItem[] = generateDynamicAlerts('Rajkot');

interface WeatherAlertsContextType {
  alerts: WeatherAlertItem[];
  apiMessage: string;
  activeLocation: string;
  unreadCount: number;
  permissionStatus: NotificationPermission;
  activeToast: WeatherAlertItem | null;
  requestNotificationPermission: () => Promise<boolean>;
  sendAlertNotification: (alert: WeatherAlertItem) => void;
  triggerHeavyRainTestAlert: (targetCity?: string) => void;
  updateAlertsForLocation: (city: string, weatherData?: any) => Promise<void>;
  markAsRead: (id: number) => void;
  markAllAsRead: () => void;
  dismissToast: () => void;
}

const WeatherAlertsContext = createContext<WeatherAlertsContextType | undefined>(undefined);

// Synthesize pleasant two-tone weather alert chime via Web Audio API
export const playAlertChime = () => {
  try {
    const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioCtx) return;
    const ctx = new AudioCtx();
    
    // Note 1: High alert tone
    const osc1 = ctx.createOscillator();
    const gain1 = ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(587.33, ctx.currentTime); // D5
    osc1.frequency.setValueAtTime(880, ctx.currentTime + 0.12); // A5
    
    gain1.gain.setValueAtTime(0.2, ctx.currentTime);
    gain1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.7);
    
    osc1.connect(gain1);
    gain1.connect(ctx.destination);
    
    osc1.start();
    osc1.stop(ctx.currentTime + 0.7);
  } catch (e) {
    // AudioContext blocked by user gesture policy until clicked
  }
};

export const WeatherAlertsProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [activeLocation, setActiveLocation] = useState<string>('Morbi');
  const [apiMessage, setApiMessage] = useState<string>('');
  const [alerts, setAlerts] = useState<WeatherAlertItem[]>(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('weathergpt_alerts');
      if (saved) {
        try {
          const parsed = JSON.parse(saved);
          const hasStaleStaticData = Array.isArray(parsed) && parsed.some((item: any) => 
            item.location === 'Rajkot, Gujarat' || 
            item.location === 'Saurashtra Coastline' || 
            item.location === 'Gujarat Inland' ||
            (item.description && item.description.includes('Doppler radar over Rajkot'))
          );
          if (hasStaleStaticData) {
            localStorage.removeItem('weathergpt_alerts');
          } else if (Array.isArray(parsed) && parsed.length > 0) {
            return parsed;
          }
        } catch {
          localStorage.removeItem('weathergpt_alerts');
        }
      }
    }
    return [];
  });

  const [permissionStatus, setPermissionStatus] = useState<NotificationPermission>(() => {
    if (typeof window !== 'undefined' && 'Notification' in window) {
      return Notification.permission;
    }
    return 'default';
  });

  const [activeToast, setActiveToast] = useState<WeatherAlertItem | null>(null);
  const toastTimeoutRef = useRef<any>(null);

  // Save alerts to localStorage
  useEffect(() => {
    localStorage.setItem('weathergpt_alerts', JSON.stringify(alerts));
  }, [alerts]);

  const updateAlertsForLocation = async (city: string, _weatherData?: any) => {
    if (!city) return;
    const cleanCity = city.split(',')[0].trim();
    setActiveLocation(cleanCity);

    try {
      const res = await fetchWeatherAlertsApi(cleanCity);
      if (res && res.success) {
        if (Array.isArray(res.alerts) && res.alerts.length > 0) {
          const mapped = res.alerts.map((a: any, idx: number) => mapBackendAlertToItem(a, cleanCity, idx));
          setAlerts(mapped);
          setApiMessage('');
          return;
        } else {
          setAlerts([]);
          setApiMessage(res.message || `No severe weather warnings reported for ${cleanCity}.`);
          return;
        }
      }
    } catch (e: any) {
      console.warn(`Backend alerts endpoint fetch error for ${cleanCity}:`, e);
      setApiMessage(`Unable to fetch live alerts for ${cleanCity}.`);
    }

    setAlerts([]);
  };

  // Request browser desktop notification permission
  const requestNotificationPermission = async (): Promise<boolean> => {
    if (typeof window === 'undefined' || !('Notification' in window)) {
      alert('Desktop notifications are not supported in this browser.');
      return false;
    }

    try {
      const permission = await Notification.requestPermission();
      setPermissionStatus(permission);
      if (permission === 'granted') {
        new Notification('🌧️ WeatherGPT Alerts Enabled', {
          body: 'You will receive real-time notifications for heavy rain, thunderstorms, and extreme weather warnings.',
          icon: '/favicon.ico'
        });
        return true;
      }
      return false;
    } catch (e) {
      console.error('Error requesting notification permission:', e);
      return false;
    }
  };

  // Dispatch real notification (Desktop Push + In-App Sound & Toast)
  const sendAlertNotification = (alert: WeatherAlertItem) => {
    playAlertChime();
    setActiveToast(alert);
    if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    toastTimeoutRef.current = setTimeout(() => {
      setActiveToast(null);
    }, 8000);

    if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'granted') {
      try {
        const notif = new Notification(`⛈️ ${alert.title}`, {
          body: `${alert.expected}: ${alert.description}`,
          tag: `alert-${alert.id}`,
          icon: '/favicon.ico'
        });

        notif.onclick = () => {
          window.focus();
          window.location.href = '/alerts';
        };
      } catch (err) {
        console.warn('Could not launch system notification:', err);
      }
    }
  };

  // Immediate Test Trigger for Heavy Rain Alert tailored to current active city
  const triggerHeavyRainTestAlert = (targetCity?: string) => {
    const city = (targetCity || activeLocation || 'Rajkot').split(',')[0].trim();
    const rainAlert: WeatherAlertItem = {
      id: Date.now(),
      title: "Heavy Rain & Flash Flood Warning",
      severity: "Critical",
      expected: "Next 2 Hours (80mm expected)",
      description: `Severe downpour detected on Doppler radar over ${city}. High risk of waterlogging on major roads. Stay indoors and carry waterproof gear!`,
      type: "rain",
      location: `${city} Urban Area`,
      timestamp: "Just now",
      read: false
    };

    setAlerts(prev => [rainAlert, ...prev]);
    sendAlertNotification(rainAlert);
  };



  const markAsRead = (id: number) => {
    setAlerts(prev => prev.map(a => a.id === id ? { ...a, read: true } : a));
  };

  const markAllAsRead = () => {
    setAlerts(prev => prev.map(a => ({ ...a, read: true })));
  };

  const dismissToast = () => {
    if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    setActiveToast(null);
  };

  const unreadCount = alerts.filter(a => !a.read).length;

  return (
    <WeatherAlertsContext.Provider
      value={{
        alerts,
        apiMessage,
        activeLocation,
        unreadCount,
        permissionStatus,
        activeToast,
        requestNotificationPermission,
        sendAlertNotification,
        triggerHeavyRainTestAlert,
        updateAlertsForLocation,
        markAsRead,
        markAllAsRead,
        dismissToast
      }}
    >
      {children}
    </WeatherAlertsContext.Provider>
  );
};

export const useWeatherAlerts = () => {
  const context = useContext(WeatherAlertsContext);
  if (!context) {
    throw new Error('useWeatherAlerts must be used within a WeatherAlertsProvider');
  }
  return context;
};
