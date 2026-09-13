import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/location_model.dart';
import '../../providers/location_provider.dart';
import '../../services/location_service.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<LocationProvider>().searchLocations(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocationProvider>();
    final searchResults = locProvider.searchResults;
    final isSearching = locProvider.isSearching;
    final favorites = locProvider.favorites;
    final recents = locProvider.recentSearches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search City or Location'),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                onSubmitted: (text) {
                  _debounceTimer?.cancel();
                  context.read<LocationProvider>().searchLocations(text);
                },
                decoration: InputDecoration(
                  hintText: 'Search city, region, or country...',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            locProvider.clearSearchResults();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // "Use My Current Location" GPS Action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 0,
              color: const Color(0x1A0EA5E9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: locProvider.isLocating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0EA5E9)),
                      )
                    : const Icon(Icons.my_location_rounded, color: Color(0xFF0EA5E9)),
                title: const Text(
                  'Use My Current Location',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0EA5E9)),
                ),
                subtitle: const Text('Auto-detect weather via GPS', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF0EA5E9)),
                onTap: () async {
                  final ok = await locProvider.detectCurrentGPSLocation();
                  if (ok && context.mounted) {
                    Navigator.pop(context, locProvider.currentLocation);
                  }
                },
              ),
            ),
          ),

          // Search Results or Favorites & Recents
          Expanded(
            child: isSearching
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Searching global locations...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? _buildSearchResults(searchResults)
                    : _buildFavoritesAndRecents(locProvider, favorites, recents),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<WeatherLocation> results) {
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No locations found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Check spelling or search another city', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final loc = results[index];
        return ListTile(
          leading: const Icon(Icons.location_city_rounded, color: Color(0xFF0EA5E9)),
          title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(loc.state != null ? '${loc.state}, ${loc.country}' : loc.country, style: const TextStyle(fontSize: 12)),
          onTap: () => Navigator.pop(context, loc),
        );
      },
    );
  }

  Widget _buildFavoritesAndRecents(
    LocationProvider provider,
    List<WeatherLocation> favorites,
    List<WeatherLocation> recents,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Favorites Header
        if (favorites.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: Colors.amber),
              SizedBox(width: 6),
              Text('SAVED FAVORITES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          ...favorites.map((loc) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.star_rounded, color: Colors.amber),
                title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(loc.displayName, style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => provider.toggleFavorite(loc),
                ),
                onTap: () => Navigator.pop(context, loc),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Recent Searches
        if (recents.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('RECENT SEARCHES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
                ],
              ),
              GestureDetector(
                onTap: () => provider.clearRecentSearches(),
                child: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recents.map((loc) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              dense: true,
              leading: const Icon(Icons.schedule, size: 18, color: Colors.grey),
              title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(loc.displayName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              onTap: () => Navigator.pop(context, loc),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Popular & Trending Cities
        const Row(
          children: [
            Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFF59E0B)),
            SizedBox(width: 6),
            Text('POPULAR CITIES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LocationService.popularCities.map((loc) {
            return InkWell(
              onTap: () => Navigator.pop(context, loc),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_city_rounded, size: 14, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Text(
                      loc.name,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
