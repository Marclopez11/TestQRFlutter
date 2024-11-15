import 'package:latlong2/latlong.dart';
import 'accommodation.dart';
import 'interest.dart';
import 'route.dart';
import 'population.dart';
import '../services/taxonomy_service.dart';

class MapItem {
  final String id;
  final String title;
  final String description;
  final LatLng position;
  final String imageUrl;
  final String categoryName;
  final double averageRating;
  final int commentCount;
  final String type; // 'interest', 'route_walk', 'route_bike', 'hotel'
  final String markerIcon;
  final String filterName;

  // Enlaces sociales y contacto
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? websiteUrl;
  final String? whatsappNumber;
  final String? phoneNumber;
  final String? email;

  // Campos adicionales para rutas
  final double? distance;
  final int? hours;
  final int? minutes;
  final double? positiveElevation;
  final double? negativeElevation;
  final int? difficultyId;
  final int? circuitTypeId;
  final int? routeTypeId;
  final String? gpxFile;
  final String? kmlUrl;

  // Campos adicionales para hoteles
  final int? hotelType;
  final List<int>? hotelServices;
  final String? phoneNumber2;
  final String? stars;
  final String? address;

  // Campos adicionales para intereses
  final String? audioUrl;
  final String? videoUrl;
  final bool? featured;
  final List<String>? imageGallery;
  final String? langcode;
  final int? categoryId;

  // Campos adicionales para poblaciones
  final String? title1;
  final String? title2;
  final String? title3;
  final String? description2;
  final String? description3;

  MapItem({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.imageUrl,
    required this.categoryName,
    this.averageRating = 0.0,
    this.commentCount = 0,
    required this.type,
    required this.markerIcon,
    required this.filterName,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.websiteUrl,
    this.whatsappNumber,
    this.phoneNumber,
    this.email,
    this.distance,
    this.hours,
    this.minutes,
    this.positiveElevation,
    this.negativeElevation,
    this.difficultyId,
    this.circuitTypeId,
    this.routeTypeId,
    this.gpxFile,
    this.kmlUrl,
    this.hotelType,
    this.hotelServices,
    this.phoneNumber2,
    this.stars,
    this.address,
    this.audioUrl,
    this.videoUrl,
    this.featured,
    this.imageGallery,
    this.langcode,
    this.categoryId,
    this.title1,
    this.title2,
    this.title3,
    this.description2,
    this.description3,
  });

  // Factory constructor para puntos de interés
  factory MapItem.fromInterest(Interest interest) {
    return MapItem(
      id: interest.id,
      title: interest.title,
      description: interest.description,
      position: interest.location,
      imageUrl: interest.mainImage,
      categoryName: 'Punto de interés',
      type: 'interest',
      markerIcon: 'assets/images/marker-icon01.png',
      filterName: 'Puntos de interés',
      facebookUrl: interest.facebookUrl,
      instagramUrl: interest.instagramUrl,
      twitterUrl: interest.twitterUrl,
      websiteUrl: interest.websiteUrl,
      phoneNumber: interest.phoneNumber,
    );
  }

  // Factory constructor para rutas con taxonomía
  static Future<MapItem> fromRouteWithTaxonomy(
      RouteModel route, bool isBikeRoute) async {
    final taxonomyService = TaxonomyService();
    final routeTypes = await taxonomyService.getTaxonomyTerms('tipusruta');

    final routeTypeName = routeTypes[route.routeTypeId.toString()] ??
        (isBikeRoute ? 'Ruta en bici' : 'Ruta a pie');

    return MapItem(
      id: route.id.toString(),
      title: route.title,
      description: route.description,
      position: route.location,
      imageUrl: route.mainImage ?? '',
      categoryName: routeTypeName,
      type: isBikeRoute ? 'route_bike' : 'route_walk',
      markerIcon: isBikeRoute
          ? 'assets/images/marker-icon03.png'
          : 'assets/images/marker-icon02.png',
      filterName: routeTypeName,
      // Añadir todos los campos específicos de ruta
      distance: route.distance,
      hours: route.hours,
      minutes: route.minutes,
      positiveElevation: route.positiveElevation,
      negativeElevation: route.negativeElevation,
      difficultyId: route.difficultyId,
      circuitTypeId: route.circuitTypeId,
      routeTypeId: route.routeTypeId,
      gpxFile: route.gpxFile,
      kmlUrl: route.kmlUrl,
      // Campos opcionales que podrían ser null
      imageGallery: [], // Si la ruta tiene galería de imágenes
      langcode: '', // Si la ruta tiene código de idioma
      categoryId:
          route.routeTypeId, // Usar el ID del tipo de ruta como categoryId
    );
  }

  // Factory constructor para alojamientos
  factory MapItem.fromRoute(RouteModel route, bool isBikeRoute) {
    return MapItem(
      id: route.id.toString(),
      title: route.title,
      description: route.description,
      position: route.location,
      imageUrl: route.mainImage ?? '',
      categoryName: isBikeRoute ? 'Ruta en bici' : 'Ruta a pie',
      type: isBikeRoute ? 'route_bike' : 'route_walk',
      markerIcon: isBikeRoute
          ? 'assets/images/marker-icon03.png'
          : 'assets/images/marker-icon02.png',
      filterName: isBikeRoute ? 'Ruta en bici' : 'Ruta a pie',
      // Añadir todos los campos específicos de ruta
      distance: route.distance,
      hours: route.hours,
      minutes: route.minutes,
      positiveElevation: route.positiveElevation,
      negativeElevation: route.negativeElevation,
      difficultyId: route.difficultyId,
      circuitTypeId: route.circuitTypeId,
      routeTypeId: route.routeTypeId,
      gpxFile: route.gpxFile,
      kmlUrl: route.kmlUrl,
    );
  }

  // Factory constructor para alojamientos
  factory MapItem.fromAccommodation(Accommodation accommodation) {
    return MapItem(
      id: accommodation.id,
      title: accommodation.title,
      description: accommodation.description,
      position: accommodation.location,
      imageUrl: accommodation.mainImage,
      categoryName: 'Hotel',
      type: 'hotel',
      markerIcon: 'assets/images/marker-icon04.png',
      filterName: 'Hoteles',
      facebookUrl: accommodation.facebook,
      instagramUrl: accommodation.instagram,
      twitterUrl: accommodation.twitter,
      websiteUrl: accommodation.web,
      phoneNumber: accommodation.phoneNumber,
      phoneNumber2: accommodation.phoneNumber2,
      stars: accommodation.stars,
      address: accommodation.address,
      hotelServices: accommodation.hotelServices,
      email: accommodation.email,
    );
  }

  // Factory constructor para poblaciones
  factory MapItem.fromPopulation(Population population) {
    return MapItem(
      id: population.id,
      title: population.title,
      description: population.description1 ?? '',
      position: population.location,
      imageUrl: population.mainImage,
      categoryName: 'Población',
      type: 'population',
      markerIcon: 'assets/images/marker-icon05.png',
      filterName: 'Poblaciones',
      // Añadir todos los campos específicos de población
      imageGallery: population.imageGallery,
      title1: population.title1,
      title2: population.title2,
      title3: population.title3,
      description2: population.description2,
      description3: population.description3,
    );
  }

  String getIconForFilter() {
    switch (type) {
      case 'interest':
        return 'assets/images/icon01.png';
      case 'route_walk':
        return 'assets/images/icon02.png';
      case 'route_bike':
        return 'assets/images/icon03.png'; // Asegurar que este es el icono correcto para bici
      case 'hotel':
        return 'assets/images/icon04.png';
      case 'population':
        return 'assets/images/icon05.png';
      default:
        return 'assets/images/icon01.png';
    }
  }

  String getFilterName() {
    return filterName;
  }
}
