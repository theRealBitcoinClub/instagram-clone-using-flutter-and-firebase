// import 'package:flutter/material.dart';
//
// class MediaSelectorWidget extends StatelessWidget {
//   final String label;
//   final IconData iconData;
//   final VoidCallback onTap;
//   final double iconSize;
//   final double borderRadius;
//   final double borderWidth;
//
//   const MediaSelectorWidget({
//     Key? key,
//     required this.label,
//     required this.iconData,
//     required this.onTap,
//     this.iconSize = 40,
//     this.borderRadius = 8,
//     this.borderWidth = 2,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     final ColorScheme colorScheme = theme.colorScheme;
//     final TextTheme textTheme = theme.textTheme;
//
//     return Expanded(
//       child: Material(
//         color: Colors.transparent, // Move background color here
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(borderRadius),
//           side: BorderSide(color: colorScheme.primary, width: borderWidth),
//         ),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(borderRadius),
//           child: AspectRatio(
//             aspectRatio: 1,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(iconData, size: iconSize, color: colorScheme.primary),
//                 const SizedBox(height: 4),
//                 Text(
//                   label,
//                   style: textTheme.labelLarge?.copyWith(color: colorScheme.surface, fontWeight: FontWeight.w500),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
