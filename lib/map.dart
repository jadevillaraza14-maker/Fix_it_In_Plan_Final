import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng philippinesCenter = LatLng(
    12.8797,
    121.7740,
  );

  LatLng? selectedLocation;

  String selectedAddress = '';

  bool isLoadingAddress = false;

  final MapController mapController = MapController();

  LatLng? currentLocation;

  bool isLocating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      useMyLocation();
    });
  }

   // ============================================================
  // CURRENT LOCATION
  // ============================================================

  void _mapMsg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> useMyLocation() async {
    if (isLocating) {
      return;
    }

    setState(() {
      isLocating = true;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _mapMsg('Turn on GPS (location) first.');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _mapMsg('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _mapMsg('Location is blocked. Allow it in app settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        ),
      );

      final point = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        currentLocation = point;
      });

      mapController.move(point, 16);

      await selectLocation(point);
    } catch (e) {
      _mapMsg('Could not read your location. Tap the map instead.');
    } finally {
      if (mounted) {
        setState(() {
          isLocating = false;
        });
      }
    }
  }

  // ============================================================
  // SELECT LOCATION
  // ============================================================

  Future<void> selectLocation(LatLng location) async {
    setState(() {
      selectedLocation = location;
      selectedAddress = '';
      isLoadingAddress = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?format=jsonv2'
            '&lat=${location.latitude}'
            '&lon=${location.longitude}'
            '&addressdetails=1'
            '&zoom=18'
            '&accept-language=en',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FixItInPlan/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final address = data['address'];

        if (address != null) {
          final road = address['road']?.toString();
          final houseNumber =
          address['house_number']?.toString();

          final barangay =
              address['village']?.toString() ??
                  address['suburb']?.toString() ??
                  address['neighbourhood']?.toString();

          final city =
              address['city']?.toString() ??
                  address['town']?.toString() ??
                  address['municipality']?.toString();

          final province =
              address['state']?.toString() ??
                  address['state_district']?.toString();

          final postcode =
          address['postcode']?.toString();

          final parts = <String>[];

          if (houseNumber != null &&
              houseNumber.isNotEmpty) {
            parts.add(houseNumber);
          }

          if (road != null && road.isNotEmpty) {
            parts.add(road);
          }

          if (barangay != null &&
              barangay.isNotEmpty) {
            parts.add(
              barangay.startsWith('Barangay')
                  ? barangay
                  : 'Brgy. $barangay',
            );
          }

          if (city != null && city.isNotEmpty) {
            parts.add(city);
          }

          if (province != null &&
              province.isNotEmpty) {
            parts.add(province);
          }

          if (postcode != null &&
              postcode.isNotEmpty) {
            parts.add(postcode);
          }

          if (parts.isNotEmpty) {
            setState(() {
              selectedAddress = parts.join(', ');
            });
          } else {
            setState(() {
              selectedAddress =
              'Address not available for this location.';
            });
          }
        } else {
          setState(() {
            selectedAddress =
            'Address not available for this location.';
          });
        }
      } else {
        setState(() {
          selectedAddress =
          'Unable to get address. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress =
        'Unable to get address. Please check your internet connection.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAddress = false;
        });
      }
    }
  }
  // ============================================================
  // CONFIRM LOCATION
  // ============================================================

  void confirmLocation() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please tap the map to select a project location.',
          ),
        ),
      );
      return;
    }

    if (selectedAddress.isEmpty ||
        selectedAddress.startsWith('Unable')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait for the address to load.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      selectedAddress,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),

      appBar: AppBar(
        backgroundColor: const Color(0xFF004437),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Select Project Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          // ========================================================
          // MAP
          // ========================================================

          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: philippinesCenter,
              initialZoom: 5.5,
              minZoom: 5,
              maxZoom: 18,

              onTap: (tapPosition, point) {
                selectLocation(point);
              },
            ),

            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                'com.fixitinplan.app',
              ),

              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFF006B50),
                        size: 50,
                      ),
                    ),
                  ],
                ),
              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),

          // ========================================================
          // INSTRUCTION CARD
          // ========================================================

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF006B50),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap the map to select your project location.',
                      style: TextStyle(
                        color: Color(0xFF173B33),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ========================================================
          // CURRENT LOCATION BUTTON
          // ========================================================

          Positioned(
            right: 16,
            top: 86,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: isLocating ? null : useMyLocation,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: isLocating
                      ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF006B50),
                    ),
                  )
                      : const Icon(
                    Icons.my_location,
                    color: Color(0xFF006B50),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // ========================================================
          // ADDRESS CARD
          // ========================================================

          if (selectedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: Container(
                padding:
                const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset:
                      const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                  const Text(
                  'Selected Location',
                  style: TextStyle(
                    color:
                    Color(0xFF004437),
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                    if (isLoadingAddress)
                const Row(
              children: [
              SizedBox(
              width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Color(0xFF006B50),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Getting address...',
                  style: TextStyle(
                    color:
                    Color(0xFF526B64),
                    fontSize: 13,
                  ),
                ),
              ),
              ],
            )
          else
            Text(
              selectedAddress.isEmpty
                  ? 'Address not available.'
                  : selectedAddress,
              style: const TextStyle(
                color:
                Color(0xFF526B64),
                fontSize: 13,
                fontWeight:
                FontWeight.w500,
              ),
            ),
        ],
      ),
    ),
    ),

    // ========================================================
    // CONFIRM BUTTON
    // ========================================================

    Positioned(
    left: 16,
    right: 16,
    bottom: 20,
    child: SizedBox(
    height: 54,
    child: ElevatedButton(
    onPressed:
    isLoadingAddress
    ? null
        : confirmLocation,
    style:
    ElevatedButton.styleFrom(
    backgroundColor:
    const Color(0xFF006B50),
    foregroundColor:
    Colors.white,
    elevation: 3,
    shape:
    RoundedRectangleBorder(
    borderRadius:
    BorderRadius.circular(16),
    ),
    ),
    child: isLoadingAddress
    ? const SizedBox(
    width: 22,
    height: 22,
    child:
    CircularProgressIndicator(
    strokeWidth: 2,
    color: Colors.white,
    ),
    )
        : const Text(
    'Confirm Location',
    style: TextStyle(
    fontSize: 17,
    fontWeight:
    FontWeight.bold,
    ),
    ),
    ),
    ),
    ),
    ],
    ),
    );
  }
}