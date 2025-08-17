import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

class ImgurUtils {
  static Widget loadingImage(BuildContext context, Widget? child, ImageChunkEvent? loadingProgress) {
    // if (child == null)
    //   print("NULLLL");
    // print("object");
    var x = ((child as Semantics).child as RawImage).image;
    if (x != null) {
      // print("img null");
    // else {
      ui.Image img = x as ui.Image;
      // if (loadingProgress != null) {
      //   print("notnull" + img.width.toString());
      // } else {
      //   print("null" + img.width.toString());
      // }
      if (img.width == 161 && img.height == 81)
        return Text("This image was removed from Imgur"); //TODO these are the images not available anymore on imgur, return asset image
    }
    //   return SizedBox();
    return child;
  }

  static Widget errorLoadImage(BuildContext context, Object error, StackTrace? stackTrace) {
    // if ((error as SocketException).message == "Network is unreachable")
    //   TODO SHOW TOAST
    if (error.toString() == "Exception: Invalid image data") {
      // return Image(image: AssetImage(assetName),)
      // TODO RETURN ASSET IMAGE
      return Image(image: NetworkImage("https://i.imgur.com/yhN4cfs.png"));
    }
    print("object");
    //TODO I THINK ANY ERROR THAT HAPPENS THERE WILL BE RETURNED THE WIDGET
    return Image(image: NetworkImage("https://i.imgur.com/yhN4cfs.png"));
  }
}