import { useState } from 'react';
import { User, Settings, Bell, MapPin, Moon, Sun, Save, Check, X, Edit3, Mail, Sparkles, CheckCircle2, LogOut } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '../components/Card';
import { useTheme } from '../hooks/useTheme';
import { useUserProfile, type TemperatureUnit, type UserProfile, type UserPreferences } from '../hooks/useUserProfile';
import { useLanguage } from '../hooks/useLanguage';

export default function ProfilePage() {
  const { theme, setTheme } = useTheme();
  const { t } = useLanguage();
  const { 
    profile, 
    preferences, 
    saveChanges, 
    lastSavedNotification, 
    dismissNotification,
    logout,
    isAuthenticated
  } = useUserProfile();

  // Local form states for editing
  const [formProfile, setFormProfile] = useState<UserProfile>(profile);
  const [formPreferences, setFormPreferences] = useState<UserPreferences>(preferences);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isLogoutModalOpen, setIsLogoutModalOpen] = useState(false);
  const [isSavedRecently, setIsSavedRecently] = useState(false);

  // Sync with context if context updates externally
  const handleOpenEditModal = () => {
    setFormProfile(profile);
    setIsEditModalOpen(true);
  };

  const handleSaveModalProfile = (e: React.FormEvent) => {
    e.preventDefault();
    // Compute initials from name
    const parts = formProfile.name.trim().split(/\s+/);
    const initials = parts.length > 1 
      ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
      : (parts[0].slice(0, 2)).toUpperCase();
    
    const updatedProfile = { ...formProfile, avatarInitials: initials || 'SD' };
    setFormProfile(updatedProfile);
    saveChanges(updatedProfile, formPreferences);
    setIsEditModalOpen(false);
    triggerSaveEffect();
  };

  const handleSaveAll = () => {
    saveChanges(formProfile, formPreferences);
    triggerSaveEffect();
  };

  const triggerSaveEffect = () => {
    setIsSavedRecently(true);
    setTimeout(() => {
      setIsSavedRecently(false);
    }, 2500);
  };

  return (
    <div className="w-full mx-auto space-y-6 animate-in fade-in duration-500 relative">
      {/* Save Success Banner Notification */}
      {lastSavedNotification && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-2xl flex items-center justify-between gap-3 text-emerald-700 dark:text-emerald-400 shadow-sm animate-in slide-in-from-top-2">
          <div className="flex items-center gap-2.5">
            <CheckCircle2 className="w-5 h-5 flex-shrink-0 text-emerald-600 dark:text-emerald-400" />
            <span className="text-sm font-semibold">{lastSavedNotification}</span>
          </div>
          <button 
            onClick={dismissNotification}
            className="p-1 hover:bg-emerald-500/20 rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <User className="w-8 h-8 text-primary" />
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t('profile_title', 'Profile & Settings')}</h1>
            <p className="text-xs text-muted-foreground">{t('profile_subtitle', 'Manage your personal preferences and weather units')}</p>
          </div>
        </div>
      </div>

      {/* Profile Overview Card */}
      <Card>
        <CardContent className="p-6">
          {!isAuthenticated ? (
            <div className="flex flex-col items-center justify-center text-center space-y-4 py-4">
              <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center">
                <User className="w-8 h-8 text-primary" />
              </div>
              <div>
                <h2 className="text-xl font-bold text-foreground">Not Logged In</h2>
                <p className="text-sm text-muted-foreground mt-1">Log in to sync your weather preferences and access the AI Chat.</p>
              </div>
              <button 
                onClick={() => window.location.href = '/assistant'}
                className="mt-2 px-6 py-2.5 bg-primary hover:bg-primary/90 text-primary-foreground font-semibold rounded-xl shadow-md transition-all hover:scale-105"
              >
                Log In / Sign Up
              </button>
            </div>
          ) : (
            <div className="flex flex-col md:flex-row items-center gap-6">
              <div className="w-24 h-24 bg-gradient-to-br from-primary/20 to-primary/10 border-2 border-primary/30 rounded-full flex items-center justify-center text-primary text-3xl font-extrabold shadow-inner">
                {profile.avatarInitials || 'JD'}
              </div>
              <div className="flex-1 text-center md:text-left space-y-2">
                <h2 className="text-2xl font-bold text-foreground">{profile.name}</h2>
                <p className="text-muted-foreground flex items-center justify-center md:justify-start gap-1.5 text-sm">
                  <Mail className="w-3.5 h-3.5 text-muted-foreground" />
                  {profile.email}
                </p>
                <div className="flex items-center justify-center md:justify-start gap-2 text-sm font-medium text-primary bg-primary/10 w-fit mx-auto md:mx-0 px-3.5 py-1 rounded-full border border-primary/20">
                  <MapPin className="w-4 h-4 text-primary" />
                  <span>{profile.location}</span>
                </div>
              </div>
              <button 
                onClick={handleOpenEditModal}
                className="flex items-center gap-2 px-4 py-2.5 border border-border bg-card hover:bg-muted font-medium rounded-xl transition-all cursor-pointer shadow-2xs hover:scale-105"
              >
                <Edit3 className="w-4 h-4 text-primary" />
                <span>Edit Profile</span>
              </button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Preferences & Notifications Cards */}
      <div className="grid md:grid-cols-2 gap-6">
        {/* Preferences Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="w-5 h-5 text-primary" />
              <span>Preferences</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Temperature Unit Preference */}
            <div className="flex items-center justify-between gap-4">
              <div>
                <p className="font-semibold text-foreground">Temperature Unit</p>
                <p className="text-xs text-muted-foreground">Select Celsius (°C) or Fahrenheit (°F)</p>
              </div>
              <select 
                value={formPreferences.tempUnit}
                onChange={(e) => {
                  const newUnit = e.target.value as TemperatureUnit;
                  const updated = { ...formPreferences, tempUnit: newUnit };
                  setFormPreferences(updated);
                  saveChanges(formProfile, updated);
                }}
                className="glass-input rounded-xl px-3.5 py-2 font-medium cursor-pointer"
              >
                <option value="celsius">Celsius (°C)</option>
                <option value="fahrenheit">Fahrenheit (°F)</option>
              </select>
            </div>
            
            {/* Appearance Preference */}
            <div className="flex items-center justify-between gap-4">
              <div>
                <p className="font-semibold text-foreground">Appearance</p>
                <p className="text-xs text-muted-foreground">Light or dark interface theme</p>
              </div>
              <div className="flex bg-muted rounded-xl p-1 border border-border/50">
                <button 
                  onClick={() => setTheme('light')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                    theme === 'light' 
                      ? 'bg-background text-foreground shadow-xs' 
                      : 'text-muted-foreground hover:text-foreground'
                  }`}
                >
                  <Sun className="w-4 h-4" />
                  Light
                </button>
                <button 
                  onClick={() => setTheme('dark')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                    theme === 'dark' 
                      ? 'bg-background text-foreground shadow-xs' 
                      : 'text-muted-foreground hover:text-foreground'
                  }`}
                >
                  <Moon className="w-4 h-4" />
                  Dark
                </button>
              </div>
            </div>

          </CardContent>
        </Card>

        {/* Notifications Card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Bell className="w-5 h-5 text-primary" />
              <span>Notifications</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex items-center justify-between gap-4">
              <div>
                <p className="font-semibold text-foreground">Weather Alerts</p>
                <p className="text-xs text-muted-foreground">Severe rain & storm warnings</p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input 
                  type="checkbox" 
                  className="sr-only peer" 
                  checked={formPreferences.weatherAlertsNotification}
                  onChange={(e) => {
                    const updated = { ...formPreferences, weatherAlertsNotification: e.target.checked };
                    setFormPreferences(updated);
                    saveChanges(formProfile, updated);
                  }}
                />
                <div className="w-11 h-6 bg-muted peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
              </label>
            </div>

            <div className="flex items-center justify-between gap-4">
              <div>
                <p className="font-semibold text-foreground">Daily Forecast</p>
                <p className="text-xs text-muted-foreground">Morning weather summary</p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input 
                  type="checkbox" 
                  className="sr-only peer" 
                  checked={formPreferences.dailyForecastNotification}
                  onChange={(e) => {
                    const updated = { ...formPreferences, dailyForecastNotification: e.target.checked };
                    setFormPreferences(updated);
                    saveChanges(formProfile, updated);
                  }}
                />
                <div className="w-11 h-6 bg-muted peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
              </label>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Save Changes Bottom Action */}
      <div className="flex items-center justify-between pt-2">
        {isAuthenticated ? (
          <button
            onClick={() => setIsLogoutModalOpen(true)}
            className="flex items-center gap-2 px-6 py-3 font-semibold rounded-xl transition-all shadow-md cursor-pointer border border-red-500/50 text-red-500 hover:bg-red-500/10"
          >
            <LogOut className="w-5 h-5" />
            <span>Logout</span>
          </button>
        ) : (
          <div></div> // Spacer
        )}

        <button 
          onClick={handleSaveAll}
          className={`flex items-center gap-2 px-6 py-3 font-semibold rounded-xl transition-all shadow-md cursor-pointer ${
            isSavedRecently 
              ? 'bg-emerald-600 hover:bg-emerald-700 text-white scale-105' 
              : 'bg-primary text-primary-foreground hover:bg-primary/90 hover:scale-[1.02]'
          }`}
        >
          {isSavedRecently ? (
            <>
              <Check className="w-5 h-5 animate-bounce" />
              <span>Saved!</span>
            </>
          ) : (
            <>
              <Save className="w-5 h-5" />
              <span>Save Changes</span>
            </>
          )}
        </button>
      </div>

      {/* Interactive Edit Profile Modal */}
      {isEditModalOpen && (
        <div className="fixed inset-0 z-50 bg-background/80 backdrop-blur-sm flex items-center justify-center p-4 animate-in fade-in duration-200">
          <div className="glass-panel text-white rounded-2xl shadow-2xl w-full max-w-md p-6 space-y-5 animate-in zoom-in-95 duration-200">
            {/* Modal Header */}
            <div className="flex items-center justify-between pb-3 border-b border-border">
              <div className="flex items-center gap-2">
                <Edit3 className="w-5 h-5 text-primary" />
                <h3 className="text-lg font-bold text-foreground">Edit Profile</h3>
              </div>
              <button 
                onClick={() => setIsEditModalOpen(false)}
                className="p-1 rounded-lg hover:bg-muted text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Edit Form */}
            <form onSubmit={handleSaveModalProfile} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-muted-foreground mb-1.5">
                  Full Name
                </label>
                <input 
                  type="text" 
                  required
                  value={formProfile.name}
                  onChange={(e) => setFormProfile(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full px-3.5 py-2.5 rounded-xl glass-input rounded-xl transition-all"
                  placeholder="e.g. John Doe"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-muted-foreground mb-1.5">
                  Email Address
                </label>
                <input 
                  type="email" 
                  required
                  value={formProfile.email}
                  onChange={(e) => setFormProfile(prev => ({ ...prev, email: e.target.value }))}
                  className="w-full px-3.5 py-2.5 rounded-xl glass-input rounded-xl transition-all"
                  placeholder="e.g. john.doe@example.com"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-muted-foreground mb-1.5">
                  City / Location
                </label>
                <input 
                  type="text" 
                  required
                  value={formProfile.location}
                  onChange={(e) => setFormProfile(prev => ({ ...prev, location: e.target.value }))}
                  className="w-full px-3.5 py-2.5 rounded-xl glass-input rounded-xl transition-all"
                  placeholder="e.g. Rajkot, Gujarat"
                />
              </div>

              {/* Action Buttons */}
              <div className="flex items-center justify-end gap-3 pt-3 border-t border-border">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-sm font-semibold border border-border hover:bg-muted text-foreground transition-colors cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex items-center gap-2 px-5 py-2 rounded-xl text-sm font-semibold bg-primary text-primary-foreground hover:bg-primary/90 transition-all shadow-xs cursor-pointer hover:scale-105"
                >
                  <Sparkles className="w-4 h-4" />
                  <span>Update Profile</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Logout Confirmation Modal */}
      {isLogoutModalOpen && (
        <div className="fixed inset-0 z-50 bg-background/80 backdrop-blur-sm flex items-center justify-center p-4 animate-in fade-in duration-200">
          <div className="glass-panel text-white rounded-2xl shadow-2xl w-full max-w-md p-6 space-y-5 animate-in zoom-in-95 duration-200 text-center">
            
            <div className="mx-auto w-16 h-16 bg-red-500/10 text-red-500 rounded-full flex items-center justify-center mb-4">
              <LogOut className="w-8 h-8" />
            </div>
            
            <h3 className="text-xl font-bold text-foreground">Sign Out</h3>
            <p className="text-muted-foreground text-sm">
              Are you sure you want to sign out of your WeatherGPT AI account?
            </p>

            <div className="flex items-center gap-3 pt-4 mt-2">
              <button
                onClick={() => setIsLogoutModalOpen(false)}
                className="flex-1 px-4 py-3 rounded-xl text-sm font-semibold border border-border hover:bg-muted text-foreground transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  setIsLogoutModalOpen(false);
                  logout();
                  window.location.href = '/';
                }}
                className="flex-1 px-4 py-3 rounded-xl text-sm font-semibold bg-red-600 text-white hover:bg-red-700 transition-all shadow-md cursor-pointer"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
