// import 'package:flutter/material.dart';
//
// class IntroOverlay extends StatefulWidget {
//   final VoidCallback onComplete;
//
//   const IntroOverlay({Key? key, required this.onComplete}) : super(key: key);
//
//   @override
//   _IntroOverlayState createState() => _IntroOverlayState();
// }
//
// class _IntroOverlayState extends State<IntroOverlay> with SingleTickerProviderStateMixin {
//   int _currentStep = 0;
//   late AnimationController _controller;
//   late Animation<double> _opacityAnimation;
//
//   final List<IntroStep> _steps = [
//     IntroStep(title: "Choose Your Theme", description: "Choose app appearance by selecting your theme", target: IntroTarget.topRight),
//     IntroStep(title: "Create New Content", description: "Tap the + button to publish new posts", target: IntroTarget.center),
//     IntroStep(title: "Your Profile", description: "Access your personal profile and settings", target: IntroTarget.bottomRight),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
//     _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//     _controller.forward();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _nextStep() {
//     if (_currentStep < _steps.length - 1) {
//       setState(() {
//         _currentStep++;
//         _controller.reset();
//         _controller.forward();
//       });
//     } else {
//       widget.onComplete();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _nextStep,
//       child: Scaffold(
//         backgroundColor: Colors.black.withOpacity(0.7),
//         body: SafeArea(
//           child: AnimatedBuilder(
//             animation: _opacityAnimation,
//             builder: (context, child) {
//               return Opacity(opacity: _opacityAnimation.value, child: child);
//             },
//             child: _buildStepContent(_steps[_currentStep]),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStepContent(IntroStep step) {
//     return Stack(
//       children: [
//         // Highlighted area with cutout
//         _buildHighlight(step.target),
//
//         // Text content
//         _buildTextContent(step),
//
//         // Finger pointer
//         _buildFingerPointer(step.target),
//       ],
//     );
//   }
//
//   Widget _buildHighlight(IntroTarget target) {
//     Offset position;
//     double width, height;
//
//     switch (target) {
//       case IntroTarget.topRight:
//         position = Offset(MediaQuery.of(context).size.width - 70, 70);
//         width = 50;
//         height = 50;
//         break;
//       case IntroTarget.center:
//         position = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 70);
//         width = 60;
//         height = 60;
//         break;
//       case IntroTarget.bottomRight:
//         position = Offset(MediaQuery.of(context).size.width - 70, MediaQuery.of(context).size.height - 70);
//         width = 50;
//         height = 50;
//         break;
//     }
//
//     return Stack(
//       children: [
//         // Dimmed background
//         Container(color: Colors.black.withOpacity(0.7)),
//
//         // Clear cutout for highlighted element
//         Positioned(
//           left: position.dx - width / 2,
//           top: position.dy - height / 2,
//           child: Container(
//             width: width,
//             height: height,
//             decoration: BoxDecoration(
//               color: Colors.transparent,
//               shape: BoxShape.circle,
//               boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), spreadRadius: 4, blurRadius: 10)],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextContent(IntroStep step) {
//     return Positioned(
//       left: 0,
//       right: 0,
//       bottom: 300,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0),
//         child: Column(
//           children: [
//             Text(
//               step.title,
//               style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 16),
//             Text(
//               step.description,
//               style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 24),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: _steps.asMap().entries.map((entry) {
//                 return Container(
//                   width: 8,
//                   height: 8,
//                   margin: EdgeInsets.symmetric(horizontal: 4),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: _currentStep == entry.key ? Colors.white : Colors.white.withOpacity(0.5),
//                   ),
//                 );
//               }).toList(),
//             ),
//             SizedBox(height: 16),
//             Text(
//               "Tap to continue",
//               style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontStyle: FontStyle.italic),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFingerPointer(IntroTarget target) {
//     Offset position;
//     double rotation;
//
//     switch (target) {
//       case IntroTarget.topRight:
//         position = Offset(MediaQuery.of(context).size.width - 60, 30);
//         rotation = 0.3;
//         break;
//       case IntroTarget.center:
//         position = Offset(MediaQuery.of(context).size.width / 2 - 20, MediaQuery.of(context).size.height - 230);
//         rotation = 3.10;
//         break;
//       case IntroTarget.bottomRight:
//         position = Offset(MediaQuery.of(context).size.width - 90, MediaQuery.of(context).size.height - 230);
//         rotation = 3;
//         break;
//     }
//
//     return Positioned(
//       left: position.dx - 30,
//       top: position.dy - 30,
//       child: Transform.rotate(
//         angle: rotation,
//         child: Icon(Icons.arrow_circle_up_sharp, size: 90, color: Colors.white),
//       ),
//     );
//   }
// }
//
// class IntroStep {
//   final String title;
//   final String description;
//   final IntroTarget target;
//
//   IntroStep({required this.title, required this.description, required this.target});
// }
//
// enum IntroTarget { topRight, center, bottomRight }
