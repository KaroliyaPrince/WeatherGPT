import React, { createContext, useContext, useState, useEffect } from 'react';

export type TemperatureUnit = 'celsius' | 'fahrenheit';

export interface UserProfile {
  name: string;
  email: string;
  location: string;
  avatarInitials: string;
}

export interface UserPreferences {
  tempUnit: TemperatureUnit;
  weatherAlertsNotification: boolean;
  dailyForecastNotification: boolean;
}

interface UserProfileContextType {
  isAuthenticated: boolean;
  login: (userData?: Partial<UserProfile>) => void;
  logout: () => void;
  signup: (userData?: Partial<UserProfile>) => void;
  profile: UserProfile;
  preferences: UserPreferences;
  updateProfile: (data: Partial<UserProfile>) => void;
  updatePreferences: (data: Partial<UserPreferences>) => void;
  setTempUnit: (unit: TemperatureUnit) => void;
  convertTemp: (celsiusVal: number | string) => number;
  formatTemp: (celsiusVal: number | string, includeUnit?: boolean) => string;
  tempUnitSymbol: string;
  tempUnitLabel: string;
  saveChanges: (newProfile?: UserProfile, newPreferences?: UserPreferences) => void;
  lastSavedNotification: string | null;
  dismissNotification: () => void;
}

const DEFAULT_PROFILE: UserProfile = {
  name: 'Sharad Detroja',
  email: 'sharad.detroja@example.com',
  location: 'Rajkot, Gujarat',
  avatarInitials: 'SD',
};

const DEFAULT_PREFERENCES: UserPreferences = {
  tempUnit: 'celsius',
  weatherAlertsNotification: true,
  dailyForecastNotification: true,
};

const UserProfileContext = createContext<UserProfileContextType | undefined>(undefined);

export const UserProfileProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(() => {
    try {
      const saved = localStorage.getItem('weathergpt_auth_v2');
      if (saved) return JSON.parse(saved);
    } catch (e) {
      console.error('Error loading auth from localStorage:', e);
    }
    return false;
  });

  const [profile, setProfile] = useState<UserProfile>(() => {
    try {
      const saved = localStorage.getItem('weathergpt_user_profile');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed.name === 'John Doe') {
          parsed.name = 'Sharad Detroja';
          parsed.email = 'sharad.detroja@example.com';
          parsed.avatarInitials = 'SD';
          localStorage.setItem('weathergpt_user_profile', JSON.stringify(parsed));
        }
        return parsed;
      }
    } catch (e) {
      console.error('Error loading profile from localStorage:', e);
    }
    return DEFAULT_PROFILE;
  });

  const [preferences, setPreferences] = useState<UserPreferences>(() => {
    try {
      const saved = localStorage.getItem('weathergpt_user_preferences');
      if (saved) return JSON.parse(saved);
    } catch (e) {
      console.error('Error loading preferences from localStorage:', e);
    }
    return DEFAULT_PREFERENCES;
  });

  const [lastSavedNotification, setLastSavedNotification] = useState<string | null>(null);

  // Sync to localStorage when states update
  useEffect(() => {
    try {
      localStorage.setItem('weathergpt_auth_v2', JSON.stringify(isAuthenticated));
    } catch (e) {
      console.error('Error saving auth:', e);
    }
  }, [isAuthenticated]);

  useEffect(() => {
    try {
      localStorage.setItem('weathergpt_user_profile', JSON.stringify(profile));
    } catch (e) {
      console.error('Error saving profile:', e);
    }
  }, [profile]);

  useEffect(() => {
    try {
      localStorage.setItem('weathergpt_user_preferences', JSON.stringify(preferences));
    } catch (e) {
      console.error('Error saving preferences:', e);
    }
  }, [preferences]);

  const login = (userData?: Partial<UserProfile>) => {
    setIsAuthenticated(true);
    if (userData) {
      updateProfile(userData);
    }
  };
  const logout = () => {
    setIsAuthenticated(false);
    setProfile(DEFAULT_PROFILE);
    localStorage.removeItem('weathergpt_user_profile');
  };
  const signup = (userData?: Partial<UserProfile>) => login(userData);

  const updateProfile = (data: Partial<UserProfile>) => {
    setProfile((prev) => {
      const updated = { ...prev, ...data };
      if (data.name && !data.avatarInitials) {
        const parts = data.name.trim().split(/\s+/);
        const initials = parts.length > 1 
          ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
          : (parts[0].slice(0, 2)).toUpperCase();
        updated.avatarInitials = initials;
      }
      return updated;
    });
  };

  const updatePreferences = (data: Partial<UserPreferences>) => {
    setPreferences((prev) => ({ ...prev, ...data }));
  };

  const setTempUnit = (unit: TemperatureUnit) => {
    setPreferences((prev) => ({ ...prev, tempUnit: unit }));
  };

  // Temperature conversion helper: Celsius -> Fahrenheit: Math.round(C * 1.8 + 32)
  const convertTemp = (celsiusVal: number | string): number => {
    const numeric = typeof celsiusVal === 'string' ? parseFloat(celsiusVal) : celsiusVal;
    if (isNaN(numeric)) return 0;
    if (preferences.tempUnit === 'fahrenheit') {
      return Math.round(numeric * 1.8 + 32);
    }
    return Math.round(numeric);
  };

  const tempUnitSymbol = preferences.tempUnit === 'fahrenheit' ? '°F' : '°C';
  const tempUnitLabel = preferences.tempUnit === 'fahrenheit' ? 'Fahrenheit (°F)' : 'Celsius (°C)';

  const formatTemp = (celsiusVal: number | string, includeUnit: boolean = true): string => {
    const converted = convertTemp(celsiusVal);
    return includeUnit ? `${converted}${tempUnitSymbol}` : `${converted}°`;
  };

  const saveChanges = (newProfile?: UserProfile, newPreferences?: UserPreferences) => {
    const finalProfile = newProfile || profile;
    const finalPreferences = newPreferences || preferences;

    setProfile(finalProfile);
    setPreferences(finalPreferences);

    try {
      localStorage.setItem('weathergpt_user_profile', JSON.stringify(finalProfile));
      localStorage.setItem('weathergpt_user_preferences', JSON.stringify(finalPreferences));
    } catch (e) {
      console.error('Error saving changes to localStorage:', e);
    }

    const unitText = finalPreferences.tempUnit === 'fahrenheit' ? 'Fahrenheit (°F)' : 'Celsius (°C)';
    setLastSavedNotification(`Profile and preferences saved! Temperature unit set to ${unitText}.`);

    setTimeout(() => {
      setLastSavedNotification(null);
    }, 4000);
  };

  const dismissNotification = () => {
    setLastSavedNotification(null);
  };

  return (
    <UserProfileContext.Provider
      value={{
        isAuthenticated,
        login,
        logout,
        signup,
        profile,
        preferences,
        updateProfile,
        updatePreferences,
        setTempUnit,
        convertTemp,
        formatTemp,
        tempUnitSymbol,
        tempUnitLabel,
        saveChanges,
        lastSavedNotification,
        dismissNotification,
      }}
    >
      {children}
    </UserProfileContext.Provider>
  );
};

export const useUserProfile = () => {
  const context = useContext(UserProfileContext);
  if (!context) {
    throw new Error('useUserProfile must be used within a UserProfileProvider');
  }
  return context;
};
