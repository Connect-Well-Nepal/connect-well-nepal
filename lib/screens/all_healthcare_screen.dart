import 'package:flutter/material.dart';
import 'package:connect_well_nepal/models/place_model.dart';
import 'package:connect_well_nepal/services/osm_places_service.dart';
import 'package:connect_well_nepal/services/location_service.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// AllHealthcareScreen - Shows all nearby healthcare facilities
class AllHealthcareScreen extends StatefulWidget {
  final List<PlaceModel> initialPlaces;
  
  const AllHealthcareScreen({
    super.key,
    required this.initialPlaces,
  });

  @override
  State<AllHealthcareScreen> createState() => _AllHealthcareScreenState();
}

class _AllHealthcareScreenState extends State<AllHealthcareScreen> {
  final OSMPlacesService _placesService = OSMPlacesService();
  final LocationService _locationService = LocationService();
  
  List<PlaceModel> _places = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  int _radiusKm = 5;

  @override
  void initState() {
    super.initState();
    _places = widget.initialPlaces;
    _loadMorePlaces();
  }

  Future<void> _loadMorePlaces() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() => _isLoading = true);
    
    try {
      final places = await _placesService.getNearbyHealthcare(
        radiusMeters: _radiusKm * 1000,
        forceRefresh: true,
      );
      
      if (mounted) {
        setState(() {
          _places = places;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading healthcare places: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load healthcare facilities: ${e.toString()}'),
            backgroundColor: AppColors.secondaryCrimsonRed,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadMorePlaces,
            ),
          ),
        );
      }
    }
  }

  List<PlaceModel> get _filteredPlaces {
    return _places.where((place) {
      // Filter by type
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Hospitals' && place.isHospital) ||
          (_selectedFilter == 'Clinics' && !place.isHospital);
      
      // Filter by search
      final matchesSearch = _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          place.address.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Healthcare'),
        backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryNavyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMorePlaces,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[900] : AppColors.primaryNavyBlue,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search hospitals, clinics...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Filters row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Type filter chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Hospitals', 'Clinics'].map((filter) {
                        final isSelected = filter == _selectedFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedFilter = filter);
                            },
                            selectedColor: AppColors.primaryNavyBlue.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primaryNavyBlue,
                            labelStyle: TextStyle(
                              color: isSelected 
                                  ? AppColors.primaryNavyBlue 
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Radius selector
                PopupMenuButton<int>(
                  initialValue: _radiusKm,
                  onSelected: (value) {
                    setState(() => _radiusKm = value);
                    _loadMorePlaces();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 2, child: Text('2 km')),
                    const PopupMenuItem(value: 5, child: Text('5 km')),
                    const PopupMenuItem(value: 10, child: Text('10 km')),
                    const PopupMenuItem(value: 20, child: Text('20 km')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me, size: 16, color: isDark ? Colors.white70 : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$_radiusKm km',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 18, color: isDark ? Colors.white70 : AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location status
          if (_locationService.hasLocation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.successGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Showing ${_filteredPlaces.length} places within $_radiusKm km',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Places list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlaces.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: 64,
                              color: isDark ? Colors.white38 : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No healthcare facilities found',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white54 : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _radiusKm = 20;
                                });
                                _loadMorePlaces();
                              },
                              icon: const Icon(Icons.search),
                              label: const Text('Search wider area'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredPlaces.length,
                        itemBuilder: (context, index) {
                          return _buildPlaceCard(_filteredPlaces[index], isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(PlaceModel place, bool isDark) {
    final isHospital = place.isHospital;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPlaceDetails(place),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Place icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isHospital
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHospital ? Icons.local_hospital : Icons.medical_services,
                  color: isHospital ? Colors.red : AppColors.primaryNavyBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Place info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isHospital
                                ? Colors.red.withValues(alpha: 0.1)
                                : AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isHospital ? 'Hospital' : 'Clinic',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isHospital ? Colors.red : AppColors.primaryNavyBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating
                        if (place.rating != null) ...[
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                            ),
                          ),
                          if (place.totalRatings != null && place.totalRatings! > 0) ...[
                            Text(
                              ' (${place.totalRatings})',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(width: 16),
                        ],
                        
                        // Distance
                        Icon(
                          Icons.directions_walk,
                          size: 14,
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(place.distanceKm),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.successGreen,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Open status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: place.isOpen
                                ? AppColors.successGreen.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: place.isOpen ? AppColors.successGreen : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return 'N/A';
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  void _showPlaceDetails(PlaceModel place) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: place.isHospital
                              ? Colors.red.withValues(alpha: 0.1)
                              : AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          place.isHospital ? Icons.local_hospital : Icons.medical_services,
                          color: place.isHospital ? Colors.red : AppColors.primaryNavyBlue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: place.isHospital
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                place.typeDisplayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: place.isHospital ? Colors.red : AppColors.primaryNavyBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Distance',
                          _formatDistance(place.distanceKm),
                          Icons.directions_walk,
                          AppColors.successGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Rating',
                          place.rating != null ? '${place.rating!.toStringAsFixed(1)}★' : 'N/A',
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Status',
                          place.isOpen ? 'Open' : 'Closed',
                          Icons.access_time,
                          place.isOpen ? AppColors.successGreen : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Address
                  Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primaryNavyBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.address,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening directions to ${place.name}...')),
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${place.name}...')),
                            );
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavyBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
