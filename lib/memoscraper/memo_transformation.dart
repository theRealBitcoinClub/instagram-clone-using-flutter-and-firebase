class MemoTransformation {
  static String reOrderTxHash(String hexString) {
    // Step 1: Split the string into pairs
    List<String> pairs = [];
    for (int i = 0; i < hexString.length; i += 2) {
      pairs.add(hexString.substring(i, i + 2));
    }

    // Step 2: Reverse the order of the pairs
    pairs = pairs.reversed.toList();

    // Step 3: Combine them back into a single string
    String reversedHexString = pairs.join('');

    return reversedHexString;
  }
}