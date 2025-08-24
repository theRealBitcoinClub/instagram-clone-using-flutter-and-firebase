import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

class ImgurUtils {
  static Widget loadingImage(BuildContext context, Widget? child, ImageChunkEvent? loadingProgress) {
    ui.Image? img = ((child as Semantics).child as RawImage).image;
    if (img != null) {
      if (img.width == 161 && img.height == 81)
        return Text(
          "This image was removed from Imgur",
        ); //TODO these are the images not available anymore on imgur, return asset image
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
      // TODO TRY TO USE THE PATH OF THAT URL TO LAUNCH A NEW REQUEST
      //  URL MIGHT BE https://imgur.com/GLXwHJU but must be https://i.imgur.com/GLXwHJU.jpeg
      return Image(image: AssetImage("assets/images/memo-128x128.png"));
    }
    // print("object");
    //TODO I THINK ANY ERROR THAT HAPPENS THERE WILL BE RETURNED THE WIDGET
    return Image(image: AssetImage("assets/images/cashtoken.png"));
  }
}
