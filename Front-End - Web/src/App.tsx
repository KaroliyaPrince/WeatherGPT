import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import MainLayout from './layouts/MainLayout';
import Dashboard from './pages/Dashboard';
import WeatherMapPage from './pages/WeatherMapPage';
import AlertsPage from './pages/AlertsPage';
import ClimatePage from './pages/ClimatePage';
import ProfilePage from './pages/ProfilePage';
import VoiceAssistantPage from './pages/VoiceAssistantPage';
import AgriculturePage from './pages/AgriculturePage';
import TravelPlannerPage from './pages/TravelPlannerPage';
import MarineSafetyPage from './pages/MarineSafetyPage';
import LanguageSelectionPage from './pages/LanguageSelectionPage';
import AuthPage from './pages/AuthPage';
import { ThemeProvider } from './hooks/useTheme';
import { WeatherAlertsProvider } from './hooks/useWeatherAlerts';
import { UserProfileProvider, useUserProfile } from './hooks/useUserProfile';
import { LanguageProvider } from './hooks/useLanguage';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useUserProfile();
  const location = useLocation();
  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  }
  return <>{children}</>;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<MainLayout />}>
        <Route index element={<Dashboard />} />
        <Route path="map" element={<WeatherMapPage />} />
        <Route path="alerts" element={<AlertsPage />} />
        <Route path="climate" element={<ClimatePage />} />
        <Route path="agriculture" element={<AgriculturePage />} />
        <Route path="travel" element={<TravelPlannerPage />} />
        <Route path="marine" element={<MarineSafetyPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="language" element={<LanguageSelectionPage />} />
        <Route path="login" element={<AuthPage />} />
        <Route path="assistant" element={<ProtectedRoute><VoiceAssistantPage /></ProtectedRoute>} />
        <Route path="chat" element={<ProtectedRoute><VoiceAssistantPage /></ProtectedRoute>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}

function App() {
  return (
    <ThemeProvider>
      <UserProfileProvider>
        <LanguageProvider>
          <WeatherAlertsProvider>
            <AppRoutes />
          </WeatherAlertsProvider>
        </LanguageProvider>
      </UserProfileProvider>
    </ThemeProvider>
  );
}

export default App;
