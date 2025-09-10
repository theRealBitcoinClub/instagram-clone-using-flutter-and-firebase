class MemoRegExp {
  final String text;

  MemoRegExp(this.text);

  String extractValidImgurOrGiphyUrl() {
    final RegExp exp = RegExp(r'^(https?:\/\/)?(i\.imgur\.com\/)([a-zA-Z0-9]+)\.(jpe?g|png|gif|mp4|webp)$');
    final match = exp.firstMatch(text.trim());
    if (match?.group(0) != null) {
      return match!.group(0)!;
    }

    final RegExp expGiphy = RegExp(r'^(?:https?:\/\/)?(?:[^.]+\.)?giphy\.com(\/.*)?$');
    final matchGiphy = expGiphy.firstMatch(text.trim());

    return matchGiphy?.group(0) ?? "";
  }

  String extractIpfsCid() {
    final RegExp ipfsExp = RegExp(r'(Qm[1-9A-HJ-NP-Za-km-z]{44}|bafy[1-9A-HJ-NP-Za-km-z]{59})');
    final match = ipfsExp.firstMatch(text);
    return match?.group(0) ?? "";
  }

  String extractOdyseeUrl() {
    final RegExp odyseeExp = RegExp(r'https?:\/\/(?:www\.)?odysee\.com\/@[^:]+:[a-f0-9]+\/[^:\s]+:[a-f0-9]+');
    final match = odyseeExp.firstMatch(text);
    return match?.group(0) ?? "";
  }
}
