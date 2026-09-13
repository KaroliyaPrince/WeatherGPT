class ApiConstants {
  static const String baseUrl = 'https://weathergpt-back-end.onrender.com';
  static const String weatherEndpoint = '$baseUrl/api/weather';
  static const String weatherCurrentEndpoint = '$baseUrl/api/weather/current';
  static const String weatherHourlyEndpoint = '$baseUrl/api/weather/hourly';
  static const String weatherDailyEndpoint = '$baseUrl/api/weather/daily';
  static const String weatherAlertsEndpoint = '$baseUrl/api/weather/alerts';
  static const String healthEndpoint = '$baseUrl/api/health';
  static const String askEndpoint = '$baseUrl/api/ask';
  static const String weatherLensEndpoint = 'https://weathergpt-backend-46or.onrender.com/api/weather/lens';
  static const String reverseGeocodeEndpoint = '$baseUrl/api/location/reverse-geocode';
  static const String disasterAlertsEndpoint = '$baseUrl/api/disaster/alerts';
  static const String compareEndpoint = '$baseUrl/api/weather/compare';
  static const String routeWeatherEndpoint = '$baseUrl/api/route-weather';

  // WeatherGPT Dedicated AI Backend
  static const String aiBaseUrl = 'https://weathergpt-backend-46or.onrender.com';
  static const String aiWeatherAskEndpoint = '$aiBaseUrl/api/ask';
  static const String aiAskEndpoint = '$aiBaseUrl/api/ask';
  static const String voiceTranscribeEndpoint = '$aiBaseUrl/api/voice/transcribe';
  static const String voiceSpeakEndpoint = '$aiBaseUrl/api/voice/speak';

  // Nominatim OpenStreetMap Search & Reverse Geocode
  static const String nominatimSearchUrl = 'https://nominatim.openstreetmap.org/search';
  static const String nominatimReverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  // OpenStreetMap & Basemap Tile Servers
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String darkMapTileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
  static const String darkMapReferenceTileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}';
  static const String satelliteTileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String voyagerTileUrl = 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  static const String terrainTileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
  static const String starlightNightTileUrl = 'https://gitc.earthdata.nasa.gov/wmts/epsg3857/best/VIIRS_CityLights_2012/default/GoogleMapsCompatible_Level8/{z}/{y}/{x}.jpg';
  static const String mapLabelsOverlayUrl = 'https://a.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}.png';
  static const String rainRadarTileUrl = 'https://tilecache.rainviewer.com/v2/radar/f118ced3165c/256/{z}/{x}/{y}/2/1_1.png';

  // Timeouts (50-second timeout handling Render cold starts and AI vision analysis)
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 50);
}
