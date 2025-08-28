// import 'package:flutter/material.dart';
// import 'package:mahakka/memo/model/memo_model_creator.dart'; // YOUR ACTUAL PATH
//
// import 'creator_service.dart';
//
// class CreatorDisplayPage extends StatefulWidget {
//   final String creatorId;
//   final CreatorService creatorService; // Pass your actual service instance
//
//   const CreatorDisplayPage({super.key, required this.creatorId, required this.creatorService});
//
//   @override
//   State<CreatorDisplayPage> createState() => _CreatorDisplayPageState();
// }
//
// class _CreatorDisplayPageState extends State<CreatorDisplayPage> {
//   late Stream<MemoModelCreator?> _creatorStream;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize the stream from the service passed via the widget
//     _creatorStream = widget.creatorService.getCreatorStream(widget.creatorId);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Creator: ${widget.creatorId} (Simple Model)')),
//       body: StreamBuilder<MemoModelCreator?>(
//         stream: _creatorStream,
//         builder: (context, snapshot) {
//           // Handle loading state
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           // Handle error state
//           if (snapshot.hasError) {
//             print("StreamBuilder error in CreatorDisplayPage: ${snapshot.error}");
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           // Handle no data (document doesn't exist or stream returned null for other reasons)
//           if (!snapshot.hasData || snapshot.data == null) {
//             return Center(child: Text('Creator with ID "${widget.creatorId}" not found.'));
//           }
//
//           // Data is available, build the UI
//           final MemoModelCreator creator = snapshot.data!;
//
//           // Example of calling a method on your creator model if needed for display
//           // This assumes your MemoModelCreator has such methods.
//           // String avatarUrl = creator.profileImageAvatar(); // Call after potential _checkProfileImageAvatar if it's async
//           // String detailUrl = creator.profileImageDetail();
//
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ListView(
//               // Use ListView for potentially long content
//               children: <Widget>[
//                 // if (avatarUrl.isNotEmpty)
//                 //   Center(
//                 //     child: CircleAvatar(
//                 //       radius: 50,
//                 //       backgroundImage: NetworkImage(avatarUrl),
//                 //       onBackgroundImageError: (exception, stackTrace) {
//                 //         print("Error loading avatar image: $exception");
//                 //       },
//                 //     ),
//                 //   ),
//                 // if (avatarUrl.isEmpty)
//                 //   const Center(child: CircleAvatar(radius: 50, child: Icon(Icons.person))),
//                 // const SizedBox(height: 16),
//                 _buildInfoCard(context, "ID", creator.id),
//                 _buildInfoCard(context, "Name", creator.name, isTitle: true),
//                 if (creator.profileText.isNotEmpty) _buildInfoCard(context, "Profile Text", creator.profileText, maxLines: 5),
//                 _buildInfoCard(context, "Follower Count", creator.followerCount.toString()),
//                 _buildInfoCard(context, "Actions", creator.actions.toString()),
//                 _buildInfoCard(context, "Created", _formatDate(creator.created)),
//                 _buildInfoCard(context, "Last Action", _formatDate(creator.lastActionDate)),
//
//                 const SizedBox(height: 20),
//                 Text("Posts", style: Theme.of(context).textTheme.titleMedium),
//                 const SizedBox(height: 8),
//                 // Section for posts would now require a separate StreamBuilder
//                 // or FutureBuilder to fetch posts associated with this creator.id
//                 // from a different collection or based on a relation.
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Text(
//                     "Posts for this creator would be loaded separately here using creator.id to query another collection (e.g., 'posts' where 'creatorId' == creator.id).",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontStyle: FontStyle.italic),
//                   ),
//                 ),
//
//                 // Example placeholder for where posts would go:
//                 // FutureBuilder<List<MemoModelPost>>( // Assuming MemoModelPost exists
//                 //   future: somePostService.fetchPostsForCreator(creator.id), // You'd need this function/service
//                 //   builder: (context, postSnapshot) {
//                 //     if (postSnapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
//                 //     if (postSnapshot.hasError) return Text('Error loading posts: ${postSnapshot.error}');
//                 //     if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) return Text("No posts found for this creator.");
//                 //     return Column(
//                 //        children: postSnapshot.data!.map((post) => ListTile(title: Text(post.text ?? ""))).toList()
//                 //     );
//                 //   },
//                 // ),
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
//                   onPressed: () {
//                     // Example of updating the creator
//                     // Create a new instance or modify a copy
//                     final updatedCreator = MemoModelCreator(); // Assuming default constructor
//                     updatedCreator.id = creator.id; // ID must remain the same for update
//                     updatedCreator.name = "${creator.name} (Updated via UI!)";
//                     updatedCreator.profileText = creator.profileText;
//                     updatedCreator.followerCount = creator.followerCount + 1;
//                     updatedCreator.actions = creator.actions + 1;
//                     updatedCreator.created = creator.created; // Usually created date doesn't change
//                     updatedCreator.lastActionDate = DateTime.now().toIso8601String();
//                     // No posts to manage here
//
//                     widget.creatorService
//                         .saveCreator(updatedCreator)
//                         .then((_) {
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update requested for ${creator.id}")));
//                           print("Update requested for ${creator.id} (simpler model)");
//                         })
//                         .catchError((e) {
//                           ScaffoldMessenger.of(
//                             context,
//                           ).showSnackBar(SnackBar(content: Text("Failed to request update: $e"), backgroundColor: Colors.red));
//                           print("Failed to request update: $e");
//                         });
//                   },
//                   child: const Text("Simulate Update & Save to Firestore"),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(BuildContext context, String label, String value, {bool isTitle = false, int? maxLines}) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 6.0),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: Theme.of(
//                 context,
//               ).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value.isEmpty ? "N/A" : value,
//               style: isTitle
//                   ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
//                   : Theme.of(context).textTheme.bodyLarge,
//               maxLines: maxLines,
//               overflow: maxLines != null ? TextOverflow.ellipsis : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatDate(String dateString) {
//     if (dateString.isEmpty) return "N/A";
//     try {
//       final dateTime = DateTime.parse(dateString);
//       // For more robust formatting, consider the 'intl' package
//       // Example: return intl.DateFormat.yMMMd().add_jm().format(dateTime);
//       return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
//     } catch (e) {
//       print("Error formatting date string '$dateString': $e");
//       return dateString; // Return original if parsing fails
//     }
//   }
// }
