import { useNavigate } from 'react-router-dom';
import { CloudRain, Wind, ThermometerSun, AlertTriangle, X, ChevronRight, BellRing } from 'lucide-react';
import { useWeatherAlerts } from '../hooks/useWeatherAlerts';
import { cn } from '../utils/cn';
import { useLanguage } from '../hooks/useLanguage';

export default function NotificationToast() {
  const { activeToast, dismissToast, markAsRead } = useWeatherAlerts();
  const navigate = useNavigate();
  const { t } = useLanguage();

  if (!activeToast) return null;

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'rain': return CloudRain;
      case 'wind': return Wind;
      case 'temp': return ThermometerSun;
      default: return AlertTriangle;
    }
  };

  const Icon = getTypeIcon(activeToast.type);

  const getSeverityStyles = (severity: string) => {
    switch (severity) {
      case 'Critical':
        return {
          bg: 'bg-red-500/15 border-red-500/40 text-red-600 dark:text-red-400',
          badge: 'bg-red-500 text-white',
          pulse: 'bg-red-500'
        };
      case 'High':
        return {
          bg: 'bg-orange-500/15 border-orange-500/40 text-orange-600 dark:text-orange-400',
          badge: 'bg-orange-500 text-white',
          pulse: 'bg-orange-500'
        };
      case 'Moderate':
        return {
          bg: 'bg-amber-500/15 border-amber-500/40 text-amber-600 dark:text-amber-400',
          badge: 'bg-amber-500 text-white',
          pulse: 'bg-amber-500'
        };
      default:
        return {
          bg: 'bg-blue-500/15 border-blue-500/40 text-blue-600 dark:text-blue-400',
          badge: 'bg-blue-500 text-white',
          pulse: 'bg-blue-500'
        };
    }
  };

  const styles = getSeverityStyles(activeToast.severity);

  const handleOpenAlerts = () => {
    markAsRead(activeToast.id);
    dismissToast();
    navigate('/alerts');
  };

  return (
    <div className="fixed top-20 right-4 md:right-8 z-[120] max-w-md w-[calc(100vw-32px)] sm:w-[420px] animate-in slide-in-from-top-4 duration-300">
      <div className={cn(
        "relative rounded-2xl border backdrop-blur-xl shadow-2xl p-4 transition-all bg-card/95 overflow-hidden",
        styles.bg
      )}>
        {/* Animated Accent Top Line */}
        <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-red-500 via-amber-500 to-primary animate-pulse" />

        <div className="flex items-start gap-3">
          {/* Pulsing Icon */}
          <div className="relative p-2.5 rounded-xl bg-card shadow-xs border border-border flex-shrink-0">
            <Icon className="w-6 h-6 text-red-500 animate-bounce" />
            <span className="absolute -top-1 -right-1 flex h-3 w-3">
              <span className={cn("animate-ping absolute inline-flex h-full w-full rounded-full opacity-75", styles.pulse)}></span>
              <span className={cn("relative inline-flex rounded-full h-3 w-3", styles.pulse)}></span>
            </span>
          </div>

          {/* Content */}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1 flex-wrap">
              <span className={cn("px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider shadow-2xs", styles.badge)}>
                {activeToast.severity} ALERT
              </span>
              <span className="text-xs font-semibold text-muted-foreground flex items-center gap-1">
                <BellRing className="w-3 h-3" />
                {activeToast.expected}
              </span>
            </div>

            <h4 className="font-bold text-sm text-foreground tracking-tight line-clamp-1">
              {activeToast.title}
            </h4>

            <p className="text-xs text-muted-foreground mt-1 line-clamp-2 leading-relaxed">
              {activeToast.description}
            </p>

            {/* Quick Actions */}
            <div className="flex items-center gap-2 mt-3">
              <button
                onClick={handleOpenAlerts}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-bold bg-primary text-primary-foreground hover:bg-primary/90 transition-all shadow-xs cursor-pointer"
              >
                <span>{t('toast_view_advisory', 'View Full Advisory')}</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={() => {
                  dismissToast();
                  navigate('/map');
                }}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold border border-border bg-card hover:bg-muted text-foreground transition-colors cursor-pointer"
              >
                {t('toast_radar_map', 'Radar Map')}
              </button>
            </div>
          </div>

          {/* Dismiss Button */}
          <button
            onClick={dismissToast}
            className="p-1 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted transition-colors cursor-pointer"
            title="Dismiss notification"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
