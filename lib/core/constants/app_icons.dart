import 'package:flutter/material.dart';

/// Firestore stores an icon *key* (a stable string), never a code point, so the
/// icon set can change without a data migration and so Flutter's icon
/// tree-shaking keeps working. Everything the picker offers lives here.
abstract final class AppIcons {
  /// Shown when a stored key is unknown (e.g. removed in a later release).
  static const IconData fallback = Icons.category_rounded;

  /// The full catalogue offered by the icon picker — 75 icons.
  static const Map<String, IconData> catalogue = <String, IconData>{
    // Food & drink
    'restaurant': Icons.restaurant_rounded,
    'fastfood': Icons.fastfood_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'local_bar': Icons.local_bar_rounded,
    'bakery': Icons.bakery_dining_rounded,
    'icecream': Icons.icecream_rounded,
    'egg': Icons.egg_alt_rounded,
    'grocery': Icons.local_grocery_store_rounded,

    // Transport
    'directions_bus': Icons.directions_bus_rounded,
    'local_taxi': Icons.local_taxi_rounded,
    'train': Icons.train_rounded,
    'motorcycle': Icons.two_wheeler_rounded,
    'bicycle': Icons.pedal_bike_rounded,
    'car': Icons.directions_car_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'flight': Icons.flight_rounded,
    'boat': Icons.directions_boat_rounded,
    'parking': Icons.local_parking_rounded,

    // Shopping
    'shopping_bag': Icons.shopping_bag_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'checkroom': Icons.checkroom_rounded,
    'shoe': Icons.ice_skating_rounded,
    'watch': Icons.watch_rounded,
    'diamond': Icons.diamond_rounded,
    'store': Icons.storefront_rounded,

    // Home & bills
    'home': Icons.home_rounded,
    'apartment': Icons.apartment_rounded,
    'receipt': Icons.receipt_long_rounded,
    'bolt': Icons.bolt_rounded,
    'water_drop': Icons.water_drop_rounded,
    'gas': Icons.local_fire_department_rounded,
    'wifi': Icons.wifi_rounded,
    'phone': Icons.smartphone_rounded,
    'tv': Icons.tv_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'build': Icons.build_rounded,
    'chair': Icons.chair_rounded,

    // Health
    'health': Icons.favorite_rounded,
    'medication': Icons.medication_rounded,
    'hospital': Icons.local_hospital_rounded,
    'fitness': Icons.fitness_center_rounded,
    'spa': Icons.spa_rounded,
    'dentist': Icons.masks_rounded,

    // Education
    'school': Icons.school_rounded,
    'book': Icons.menu_book_rounded,
    'science': Icons.science_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'edit_note': Icons.edit_note_rounded,

    // Entertainment
    'movie': Icons.movie_rounded,
    'music': Icons.music_note_rounded,
    'sports': Icons.sports_soccer_rounded,
    'games': Icons.sports_esports_rounded,
    'travel': Icons.beach_access_rounded,
    'park': Icons.park_rounded,
    'camera': Icons.photo_camera_rounded,
    'celebration': Icons.celebration_rounded,

    // People
    'family': Icons.family_restroom_rounded,
    'child': Icons.child_care_rounded,
    'pets': Icons.pets_rounded,
    'gift': Icons.card_giftcard_rounded,
    'volunteer': Icons.volunteer_activism_rounded,
    'mosque': Icons.mosque_rounded,

    // Income & finance
    'salary': Icons.payments_rounded,
    'business': Icons.business_center_rounded,
    'freelance': Icons.handyman_rounded,
    'bonus': Icons.emoji_events_rounded,
    'investment': Icons.trending_up_rounded,
    'savings': Icons.savings_rounded,
    'interest': Icons.percent_rounded,
    'refund': Icons.replay_rounded,
    'sell': Icons.sell_rounded,

    // Lending
    'handshake': Icons.handshake_rounded,
    'loan_given': Icons.call_made_rounded,
    'loan_taken': Icons.call_received_rounded,

    // Wallets & misc
    'cash': Icons.account_balance_wallet_rounded,
    'bank': Icons.account_balance_rounded,
    'card': Icons.credit_card_rounded,
    'mobile_wallet': Icons.phone_android_rounded,
    'category': Icons.category_rounded,
    'more': Icons.more_horiz_rounded,
  };

  /// Ordered keys, for the picker grid.
  static List<String> get keys => catalogue.keys.toList(growable: false);

  /// Resolves a stored key to an [IconData], never throwing.
  static IconData resolve(String? key) => catalogue[key] ?? fallback;
}
