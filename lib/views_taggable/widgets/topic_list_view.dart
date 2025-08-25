import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:instagram_clone1/memomodel/memo_model_topic.dart';

import '../view_models/search_view_model.dart';
import 'loading_indicator.dart';

class TopicListView extends StatelessWidget {
  const TopicListView({Key? key, required this.tagController, required this.animation}) : super(key: key);

  final FlutterTaggerController tagController;
  final Animation<Offset> animation;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.2),
              offset: const Offset(0, -20),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: ValueListenableBuilder<bool>(
            valueListenable: searchViewModel.loading,
            builder: (_, loading, __) {
              return ValueListenableBuilder<List<MemoModelTopic>>(
                valueListenable: searchViewModel.topics,
                builder: (_, topics, __) {
                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(onPressed: tagController.dismissOverlay, icon: const Icon(Icons.close)),
                      ),
                      if (loading && topics.isEmpty) ...{Center(heightFactor: 8, child: LoadingWidget())},
                      if (!loading && topics.isEmpty) const Center(heightFactor: 8, child: Text("No topic found")),
                      if (topics.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: topics.length,
                            itemBuilder: (_, index) {
                              final topic = topics[index];
                              return ListTile(
                                // leading: Container(
                                //   height: 50,
                                //   width: 50,
                                //   decoration: BoxDecoration(
                                //     shape: BoxShape.circle,
                                //     image: DecorationImage(
                                // image: NetworkImage(topic.avatar),
                                // ),
                                // ),
                                // ),
                                title: Text(topic.header),
                                subtitle: Text("@${topic.header}"),
                                onTap: () {
                                  tagController.addTag(id: topic.header, name: topic.header);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
