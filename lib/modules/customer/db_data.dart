// // lib/data/db_data.dart

// import 'package:flutter/material.dart';
// import '../../model/service.dart'; // Make sure the path is correct

// // This list is the single source of truth for all services in the app.
// final List<Service> allAppServices = [
//   // Existing Services (now with full data)
//   Service(
//     title: 'Air Conditioning',
//     price: 'RM 20 / hour',
//     icon: Icons.air,
//     color: const Color(0xFFFFF9C4),
//     mainImagePaths: ['assets/images/electric.jpg', 'assets/images/electric2.jpg'], // Example for slider
//     rating: 4.5,
//     ordersCompleted: 88,
//     duration: '1 to 2 hours',
//     description: 'Expert AC repair, installation, and maintenance services to keep you cool and comfortable.',
//     servicesIncluded: ['Filter cleaning & replacement', 'Coolant level check & gas refill', 'Condenser coil cleaning', 'Thermostat repair'],
//     galleryImagePaths: ['assets/images/review1.jpg', 'assets/images/review2.png', 'assets/images/review3.jpg'],
//     reviews: [
//       Review(
//         authorName: 'Mei Ling',
//         date: '14/12/2024',
//         comment: 'Very fast and efficient AC service.',
//         rating: 5.0,
//         avatarPath: 'assets/avatars/avatar1.png', // Add avatar path
//       ),
//     ],
//   ),
//   Service(
//     title: 'Electric Service',
//     price: 'RM 15 / hour',
//     icon: Icons.electrical_services,
//     color: const Color(0xFFFFE0B2),
//     mainImagePaths: ['assets/images/electric.jpg', 'assets/images/electric2.jpg'], // Multiple images for slider
//     rating: 4.0,
//     ordersCompleted: 56,
//     duration: '30 minutes to 2 hours',
//     description: 'We provide fast, reliable, and professional electrical services for homes. From lighting and wiring to panel upgrades, our licensed electricians handle it all.',
//     servicesIncluded: ['Repairs & troubleshooting', 'Lighting & outlet installation', 'Panel upgrades & rewiring', 'Smart home & EV charger setup'],
//     galleryImagePaths: ['assets/images/review1.jpg', 'assets/images/review2.png', 'assets/images/review3.jpg'],
//     reviews: [
//       Review(
//         authorName: 'Josh Peter',
//         date: '12/12/2024',
//         comment: 'Fixed my flickering lights issue in under an hour. Very professional!',
//         rating: 4.0,
//         avatarPath: 'assets/avatars/josh.png', // Add avatar path
//       ),
//       Review(
//         authorName: 'Caleb',
//         date: '10/12/2024',
//         comment: 'Installed my new EV charger. Clean work and very knowledgeable.',
//         rating: 5.0,
//         avatarPath: 'assets/avatars/caleb.png', // Add avatar path
//       ),
//     ],
//   ),
//   Service(
//     title: 'Plumbing',
//     price: 'RM 20 / hour',
//     icon: Icons.plumbing,
//     color: const Color(0xFFB3E5FC),
//     mainImagePaths: ['assets/images/electric.jpg', 'assets/images/electric2.jpg'],
//     rating: 4.8,
//     ordersCompleted: 120,
//     duration: '1 to 3 hours',
//     description: 'From leaky faucets to major pipe repairs, our certified plumbers provide high-quality service to ensure your home\'s plumbing runs smoothly.',
//     servicesIncluded: ['Leak repairs (faucets, pipes)', 'Drain cleaning & unclogging', 'Water heater installation', 'Pipe replacement'],
//     galleryImagePaths: ['assets/images/review1.jpg', 'assets/images/review2.png', 'assets/images/review3.jpg'],
//     reviews: [
//       Review(
//         authorName: 'Ethan',
//         date: '11/12/2024',
//         comment: 'Exceeded my expectations! Quick, reliable, and fixed my plumbing issue with precision.',
//         rating: 5.0,
//         avatarPath: 'assets/avatars/ethan.png',
//       ),
//     ],
//   ),

//   // -- NEWLY ADDED SERVICES --

//   Service(
//     title: 'Toilet',
//     price: 'RM 20 / hour',
//     icon: Icons.wc,
//     color: const Color(0xFFC5CAE9),
//     mainImagePaths: ['assets/images/electric.jpg', 'assets/images/electric2.jpg'],
//     rating: 4.3,
//     ordersCompleted: 75,
//     duration: '1 to 2 hours',
//     description: 'Professional toilet repair and installation services, handling clogs, leaks, and flush mechanism replacements.',
//     servicesIncluded: ['Clog removal', 'Leak repair (base and tank)', 'Flush mechanism replacement', 'New toilet installation'],
//     galleryImagePaths: ['assets/images/review1.jpg', 'assets/images/review2.png', 'assets/images/review3.jpg'],
//     reviews: [], // Can be empty
//   ),
//   Service(
//     title: 'Painting',
//     price: 'RM 20 / hour',
//     icon: Icons.format_paint,
//     color: const Color(0xFFE1BEE7),
//     mainImagePaths: ['assets/images/electric.jpg', 'assets/images/electric2.jpg'],
//     rating: 4.7,
//     ordersCompleted: 112,
//     duration: 'Varies by project size',
//     description: 'High-quality interior and exterior painting services for homes and businesses. We use premium paints for a lasting, beautiful finish.',
//     servicesIncluded: ['Interior wall painting', 'Exterior painting', 'Ceiling painting', 'Trim and door painting'],
//     galleryImagePaths: ['assets/images/review1.jpg', 'assets/images/review2.png', 'assets/images/review3.jpg'],
//     reviews: [
//       Review(
//         authorName: 'David C.',
//         date: '28/10/2024',
//         comment: 'Built beautiful custom bookshelves for my study. Great craftsmanship.',
//         rating: 5.0,
//         avatarPath: 'assets/avatars/david.png',
//       ),
//     ],
//   ),
// ];