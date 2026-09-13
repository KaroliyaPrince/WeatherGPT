import { Link, useLocation } from 'react-router-dom';
import { 
  CloudRain, 
  Map, 
  LayoutDashboard, 
  Bell, 
  BarChart2, 
  User, 
  Menu, 
  X, 
  Sparkles, 
  CheckCheck, 
  BellRing,
  Navigation
} from 'lucide-react';
import { cn } from '../utils/cn';
import { useWeatherAlerts } from '../hooks/useWeatherAlerts';
import { useUserProfile } from '../hooks/useUserProfile';
import { useLanguage } from '../hooks/useLanguage';
import { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { useMagnetic } from '../utils/gsapEffects';

export default function Navbar() {
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const { profile, isAuthenticated } = useUserProfile();
  const { t } = useLanguage();
  const [notifOpen, setNotifOpen] = useState(false);

  const notifRef = useRef<HTMLDivElement>(null);
  const askAIBtnRef = useMagnetic<HTMLAnchorElement>(0.3);

  const mainNavItems = [
    { icon: LayoutDashboard, label: t('nav_dashboard', 'Dashboard'), path: '/' },
    { icon: Navigation, label: t('nav_trip_planner', 'Route Weather'), path: '/travel' },
    { icon: CloudRain, label: t('nav_alerts', 'Alerts'), path: '/alerts' },
    { icon: Map, label: t('nav_map', 'Map'), path: '/map' },
    { icon: BarChart2, label: t('nav_climate', 'Climate'), path: '/climate' },
  ];

  const { 
    alerts, 
    unreadCount, 
    permissionStatus, 
    requestNotificationPermission, 
    triggerHeavyRainTestAlert, 
    markAsRead, 
    markAllAsRead 
  } = useWeatherAlerts();

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        setNotifOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <nav className="sticky top-0 z-50 w-full border-b border-white/15 bg-white/10 backdrop-blur-xl text-white shadow-xs">
      <div className="flex h-16 items-center px-2 sm:px-4 lg:px-6 w-full mx-auto">
        <Link to="/" className="flex items-center gap-2.5 group flex-shrink-0">
          <div className="w-8 h-8 rounded-xl bg-white/20 border border-white/30 flex items-center justify-center text-white shadow-xs backdrop-blur-md">
            <CloudRain className="h-4 h-4 text-sky-200" />
          </div>
          <span className="text-lg font-black tracking-tight text-white">
            Weather<span className="text-sky-300">GPT</span>
          </span>
        </Link>
        
        {/* Desktop Nav */}
        <div className="hidden md:flex items-center ml-6 space-x-1">
          {mainNavItems.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={cn(
                  "relative px-3.5 py-1.5 rounded-xl text-xs sm:text-sm font-semibold transition-all flex-shrink-0",
                  isActive 
                    ? "bg-white/20 text-white border border-white/25 shadow-xs" 
                    : "text-white/75 hover:text-white hover:bg-white/10"
                )}
              >
                {isActive && (
                  <motion.div 
                    layoutId="activeNavTab"
                    className="absolute inset-0 bg-white/10 rounded-xl -z-10"
                    transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                  />
                )}
                {item.label}
              </Link>
            );
          })}
        </div>

        <div className="ml-auto flex items-center space-x-2.5 sm:space-x-3">





          
          {/* Notifications Bell Dropdown */}
          <div className="relative" ref={notifRef}>
            <motion.button
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => setNotifOpen(!notifOpen)}
              className="p-2 rounded-full hover:bg-white/15 text-white transition-colors relative cursor-pointer"
              title="Weather Alerts & Notifications"
            >
              <Bell className="w-4 h-4 text-white" />
              {unreadCount > 0 && (
                <motion.span 
                  initial={{ scale: 0 }}
                  animate={{ scale: [1, 1.25, 1] }}
                  transition={{ repeat: Infinity, duration: 2 }}
                  className="absolute top-1 right-1 flex items-center justify-center min-w-[16px] h-[16px] px-1 bg-red-500 text-white text-[9px] font-extrabold rounded-full border-2 border-slate-900"
                >
                  {unreadCount}
                </motion.span>
              )}
            </motion.button>

            {/* Notifications Popover Dropdown */}
            <AnimatePresence>
              {notifOpen && (
                <motion.div 
                  initial={{ opacity: 0, y: 10, scale: 0.95 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: 10, scale: 0.95 }}
                  transition={{ duration: 0.2 }}
 className="glass-panel absolute right-0 mt-2 w-80 sm:w-96 backdrop-blur-2xl border border-white/20 rounded-2xl shadow-2xl overflow-hidden z-50 text-white" 
                >
                  {/* Header */}
                  <div className="p-3.5 border-b border-white/15 bg-white/5 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <BellRing className="w-4 h-4 text-amber-300" />
                      <h3 className="font-bold text-xs text-white uppercase tracking-wider">Weather Alerts</h3>
                      {unreadCount > 0 && (
                        <span className="px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-red-500/25 text-red-200 border border-red-500/30">
                          {unreadCount} New
                        </span>
                      )}
                    </div>
                    {unreadCount > 0 && (
                      <button
                        onClick={markAllAsRead}
                        className="text-[11px] font-semibold text-sky-300 hover:underline flex items-center gap-1 cursor-pointer"
                      >
                        <CheckCheck className="w-3.5 h-3.5" />
                        Mark all read
                      </button>
                    )}
                  </div>

                  {/* Push Notification Permission Quick-Bar */}
                  <div className="px-3.5 py-2.5 bg-white/10 border-b border-white/15 flex items-center justify-between gap-2">
                    <div className="text-[11px] font-medium text-white/90">
                      <span className="font-bold">Desktop Push Alerts: </span>
                      <span className={permissionStatus === 'granted' ? "text-emerald-300 font-semibold" : "text-amber-300 font-semibold"}>
                        {permissionStatus === 'granted' ? "Active ✓" : "Off"}
                      </span>
                    </div>
                    {permissionStatus !== 'granted' ? (
                      <button
                        onClick={requestNotificationPermission}
                        className="px-2.5 py-1 bg-white text-[#1D4ED8] text-[10px] font-bold rounded-lg hover:bg-white/90 transition-colors cursor-pointer shadow-2xs"
                      >
                        Enable Push
                      </button>
                    ) : (
                      <button
                        onClick={() => triggerHeavyRainTestAlert()}
                        className="px-2.5 py-1 bg-white/15 hover:bg-white/25 border border-white/20 text-white text-[10px] font-bold rounded-lg transition-colors cursor-pointer shadow-2xs"
                      >
                        ⚡ Test Alert
                      </button>
                    )}
                  </div>

                  {/* Alerts List */}
                  <div className="max-h-72 overflow-y-auto divide-y divide-white/10">
                    {alerts.map((alert) => (
                      <div
                        key={alert.id}
                        onClick={() => markAsRead(alert.id)}
                        className={cn(
                          "p-3 hover:bg-white/10 transition-colors cursor-pointer space-y-1",
                          !alert.read && "bg-white/8"
                        )}
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className={cn(
                            "px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider border",
                            alert.severity === 'Critical' ? "bg-red-500/25 text-red-200 border-red-500/40" :
                            alert.severity === 'High' ? "bg-orange-500/25 text-orange-200 border-orange-500/40" :
                            "bg-amber-500/25 text-amber-200 border-amber-500/40"
                          )}>
                            {alert.severity} • {alert.type}
                          </span>
                          <span className="text-[10px] text-white/60">{alert.timestamp}</span>
                        </div>

                        <h4 className={cn("text-xs font-bold text-white line-clamp-1", !alert.read && "text-sky-300")}>
                          {alert.title}
                        </h4>

                        <p className="text-[11px] text-white/75 line-clamp-2 leading-relaxed">
                          {alert.description}
                        </p>
                      </div>
                    ))}
                  </div>

                  {/* Footer Link */}
                  <div className="p-2.5 bg-white/5 border-t border-white/15 flex items-center justify-between">
                    <button
                      onClick={() => triggerHeavyRainTestAlert()}
                      className="text-[11px] font-bold text-rose-300 hover:text-rose-200 hover:underline cursor-pointer flex items-center gap-1"
                      title="Simulate a real-time heavy rain warning with sound & notification"
                    >
                      <span>⛈️ Test Heavy Rain Alert</span>
                    </button>
                    <Link
                      to="/alerts"
                      onClick={() => setNotifOpen(false)}
                      className="text-[11px] font-bold text-sky-300 hover:underline"
                    >
                      View All Advisories →
                    </Link>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
          
          {/* WeatherGPT AI Voice Assistant Link */}
          <Link
            ref={askAIBtnRef}
            to="/assistant"
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold bg-white text-[#1D4ED8] shadow-md hover:bg-white/95 hover:scale-105 transition-all cursor-pointer flex-shrink-0"
            title="Open WeatherGPT Voice Assistant"
          >
            <Sparkles className="w-3.5 h-3.5 text-amber-500 animate-pulse" />
            <span className="hidden sm:inline">Ask AI</span>
          </Link>

          {/* User Profile Avatar Link */}
          <Link 
            to="/profile" 
            className="hidden md:flex items-center justify-center w-8 h-8 rounded-full bg-white/15 hover:bg-white/25 text-white text-xs font-bold transition-all border border-white/25 shadow-2xs hover:scale-110 flex-shrink-0 backdrop-blur-md"
            title={isAuthenticated ? `Profile & Settings: ${profile.name}` : 'Settings'}
          >
            {isAuthenticated ? (profile.avatarInitials || 'SD') : <User className="w-4 h-4" />}
          </Link>

          <button 
            className="md:hidden p-2 rounded-lg hover:bg-white/15 text-white cursor-pointer"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile Nav with Motion */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div 
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
 className="glass-panel md:hidden border-t border-white/15 p-4 backdrop-blur-2xl text-white overflow-hidden space-y-1" 
          >
            <div className="flex flex-col space-y-1">
              {mainNavItems.map((item) => (
                <Link
                  key={item.path}
                  to={item.path}
                  onClick={() => setMobileMenuOpen(false)}
                  className={cn(
                    "flex items-center px-4 py-2.5 rounded-xl text-sm font-semibold transition-colors",
                    location.pathname === item.path ? "bg-white/20 text-white font-bold" : "text-white/80 hover:bg-white/10"
                  )}
                >
                  <item.icon className="w-5 h-5 mr-3" />
                  {item.label}
                </Link>
              ))}

              <div className="pt-2 space-y-1 border-t border-white/10">
                <Link
                  to="/profile"
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center px-4 py-2.5 rounded-xl text-sm font-semibold text-white/90 hover:bg-white/10"
                >
                  <User className="w-5 h-5 mr-3 text-sky-300" />
                  <span>{t('nav_profile', 'Profile & Settings')}</span>
                </Link>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
}
