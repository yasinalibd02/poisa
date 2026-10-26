import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

/// Firestore stores an icon *key* (a stable string), never a code point, so the
/// icon set can change without a data migration and so Flutter's icon
/// tree-shaking keeps working. Everything the picker offers lives here.
///
/// iOS-style (SF Symbols) glyphs wherever Cupertino has a faithful match; the
/// rest — food, mosque, piggy bank and similar — stay Material because the
/// Cupertino set has nothing that reads as the same thing.
abstract final class AppIcons {
  /// Shown when a stored key is unknown (e.g. removed in a later release).
  static const IconData fallback = CupertinoIcons.square_grid_2x2_fill;

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
    'grocery': CupertinoIcons.cart_fill,

    // Transport
    'directions_bus': CupertinoIcons.bus,
    'local_taxi': CupertinoIcons.car_detailed,
    'train': CupertinoIcons.train_style_one,
    'motorcycle': Icons.two_wheeler_rounded,
    'bicycle': Icons.pedal_bike_rounded,
    'car': CupertinoIcons.car_fill,
    'fuel': Icons.local_gas_station_rounded,
    'flight': CupertinoIcons.airplane,
    'boat': Icons.directions_boat_rounded,
    'parking': Icons.local_parking_rounded,

    // Shopping
    'shopping_bag': CupertinoIcons.bag_fill,
    'shopping_cart': CupertinoIcons.cart_fill,
    'checkroom': Icons.checkroom_rounded,
    'shoe': Icons.ice_skating_rounded,
    'watch': Icons.watch_rounded,
    'diamond': CupertinoIcons.rhombus_fill,
    'store': Icons.storefront_rounded,

    // Home & bills
    'home': CupertinoIcons.house_fill,
    'apartment': CupertinoIcons.building_2_fill,
    'receipt': CupertinoIcons.doc_text_fill,
    'bolt': CupertinoIcons.bolt_fill,
    'water_drop': CupertinoIcons.drop_fill,
    'gas': CupertinoIcons.flame_fill,
    'wifi': CupertinoIcons.wifi,
    'phone': CupertinoIcons.phone_fill,
    'tv': CupertinoIcons.tv_fill,
    'cleaning': Icons.cleaning_services_rounded,
    'build': CupertinoIcons.wrench_fill,
    'chair': Icons.chair_rounded,

    // Health
    'health': CupertinoIcons.heart_fill,
    'medication': CupertinoIcons.capsule_fill,
    'hospital': CupertinoIcons.bandage_fill,
    'fitness': Icons.fitness_center_rounded,
    'spa': Icons.spa_rounded,
    'dentist': Icons.masks_rounded,

    // Education
    'school': Icons.school_rounded,
    'book': CupertinoIcons.book_fill,
    'science': CupertinoIcons.lab_flask_solid,
    'laptop': CupertinoIcons.device_laptop,
    'edit_note': CupertinoIcons.square_pencil_fill,

    // Entertainment
    'movie': CupertinoIcons.film_fill,
    'music': CupertinoIcons.music_note_2,
    'sports': CupertinoIcons.sportscourt_fill,
    'games': CupertinoIcons.gamecontroller_fill,
    'travel': CupertinoIcons.sun_max_fill,
    'park': CupertinoIcons.tree,
    'camera': CupertinoIcons.camera_fill,
    'celebration': CupertinoIcons.sparkles,

    // People
    'family': CupertinoIcons.person_3_fill,
    'child': Icons.child_care_rounded,
    'pets': CupertinoIcons.paw_solid,
    'gift': CupertinoIcons.gift_fill,
    'volunteer': CupertinoIcons.hand_raised_fill,
    'mosque': Icons.mosque_rounded,

    // Income & finance
    'salary': Icons.payments_rounded,
    'business': CupertinoIcons.briefcase_fill,
    'freelance': CupertinoIcons.hammer_fill,
    'bonus': CupertinoIcons.rosette,
    'investment': CupertinoIcons.graph_square_fill,
    'savings': Icons.savings_rounded,
    'interest': CupertinoIcons.percent,
    'refund': CupertinoIcons.arrow_counterclockwise,
    'sell': CupertinoIcons.tag_fill,

    // Lending
    'handshake': CupertinoIcons.arrow_right_arrow_left_circle_fill,
    'loan_given': CupertinoIcons.arrow_up_right,
    'loan_taken': CupertinoIcons.arrow_down_left,

    // Wallets & misc
    'cash': Icons.account_balance_wallet_rounded,
    'bank': Icons.account_balance_rounded,
    'card': CupertinoIcons.creditcard_fill,
    'mobile_wallet': CupertinoIcons.device_phone_portrait,
    'category': CupertinoIcons.square_grid_2x2_fill,
    'more': CupertinoIcons.ellipsis,
  };

  /// Ordered keys, for the picker grid.
  static List<String> get keys => catalogue.keys.toList(growable: false);

  /// Resolves a stored key to an [IconData], never throwing.
  static IconData resolve(String? key) => catalogue[key] ?? fallback;
}
