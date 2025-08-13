import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:dart_web_scraper/common/enums.dart';
import 'package:dart_web_scraper/common/models/parser_model.dart';
import 'package:dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:dart_web_scraper/dart_web_scraper/web_scraper.dart';
import 'package:instagram_clone1/memoscraper/memo_transformation.dart';
import '../memomodel/memo_model_creator.dart';
import '../memomodel/memo_model_post.dart';
import '../memomodel/memo_model_topic.dart';
import 'electrum_websocket_service.dart';
import 'memo_code.dart';
import 'memo_transaction_builder.dart';

const mainnetServers = [
  "cashnode.bch.ninja", // Kallisti / Selene Official
  "fulcrum.jettscythe.xyz", // Jett
  "bch.imaginary.cash", // im_uname
  "bitcoincash.network", // Dagur
  "electroncash.dk", // Georg
  "blackie.c3-soft.com", // Calin
  "bch.loping.net",
  "bch.soul-dev.com",
  "bitcoincash.stackwallet.com", // Rehrar / Stack Wallet official
  "node.minisatoshi.cash", // minisatoshi
];

void main() async {
  // testMemoScraper();
  testMemoSend();
}

void testMemoScraper() async {
  WebScraper webScraper = WebScraper();

  Map<String, Object> topics = await webScraper.scrape(
    url: Uri.parse("https://memo.cash/topics/all"),
    scraperConfig: createScraperConfigMemoModelTopic(),
  );

  List<MemoModelTopic> topicList = createMemoModelTopicList(topics);

  final config = createScraperConfigMemoModelPost();

  for (MemoModelTopic currentTopic in topicList) {
    printCurrentMemoModelTopic(currentTopic);

    Map<String, Object> posts = await webScraper.scrape(
      url: Uri.parse("https://memo.cash/${currentTopic.url!}"),
      scraperConfig: config,
    );

    List<MemoModelPost> postList = createMemoModelPostList(posts, currentTopic);

    printMemoModelPost(postList);
  }
}

ScraperConfig createScraperConfigMemoModelTopic() {
  return ScraperConfig(
    parsers: [
      Parser(
        id: "topics",
        parents: ["_root"],
        type: ParserType.element,
        selectors: [
          "td",
        ],
        multiple: true
      ),
      Parser(
          id: "topic",
          parents: ["topics"],
          type: ParserType.text,
          selectors: [
            "a",
          ]
      ),
      Parser(
          id: "topicURL",
          parents: ["topics"],
          type: ParserType.url,
          selectors: [
            "a",
          ]
      ),
      Parser(
          id: "tbody",
          parents: ["_root"],
          type: ParserType.text,
          selectors: [
            "tbody",
          ]
      )
    ],
  );
}

List<MemoModelTopic> createMemoModelTopicList(Map<String, Object> topics) {
  List<MemoModelTopic> topicList = [];
  
  var tbody = topics.values.elementAt(1).toString()
      .replaceAll(",", "")
      .split("\n");
  List<String> cleanBody = [];
  
  for (String line in tbody.clone()) {
    if (line.trim().isNotEmpty) {
      cleanBody.add(line.trim());
    }
  }
  
  int itemIndex = 0;
  for (Map<String, Object> value in topics.values.first as Iterable ) {
    topicList.add(MemoModelTopic(
        header: value["topic"].toString(),
        url: value["topicURL"].toString(),
        followerCount: int.parse(cleanBody[itemIndex+3]),
        lastPost: cleanBody[itemIndex+1],
        postCount: int.parse(cleanBody[itemIndex+2])));
    itemIndex += 4;
  }
  return topicList;
}

void printCurrentMemoModelTopic(MemoModelTopic currentTopic) {
  print(currentTopic.header);
  print(currentTopic.url);
  print(currentTopic.followerCount);
  print(currentTopic.postCount);
  print(currentTopic.lastPost);
}

ScraperConfig createScraperConfigMemoModelPost() {
  return ScraperConfig(
    parsers: [
      Parser(
          id: "posts",
          parents: ["_root"],
          type: ParserType.element,
          selectors: [
            ".topic-post",
          ],
          multiple: true
      ),
      Parser(
          id: "msg",
          parents: ["posts"],
          type: ParserType.text,
          selectors: [
            ".message",
          ]
      ),
      Parser(
          id: "profileUrl",
          parents: ["posts"],
          type: ParserType.url,
          selectors: [
            ".profile",
          ]

      ),
      Parser(
          id: "age",
          parents: ["posts"],
          type: ParserType.text,
          selectors: [
            ".time",
          ]
      ),
      Parser(
          id: "likeCount",
          parents: ["posts"],
          type: ParserType.text,
          selectors: [
            ".like-info",
          ]
      ),
      Parser(
          id: "replyCount",
          parents: ["posts"],
          type: ParserType.text,
          selectors: [
            ".reply-count",
          ]
      ),
      Parser(
          id: "tipsInSatoshi",
          parents: ["posts"],
          type: ParserType.text,
          selectors: [
            ".tip-button",
          ]
      ),
      Parser(
          id: "created",
          parents: ["posts"],
          type: ParserType.attribute,
          selectors: [
            ".time::title",
          ]
      ),
      Parser(
          id: "txhash",
          parents: ["posts"],
          type: ParserType.url,
          selectors: [
            ".time",
          ]
      ),
    Parser(
        id: "creatorName",
        parents: ["posts"],
        type: ParserType.text,
        selectors: [
          ".profile",
        ]
    ),
      Parser(
          id: "imgur",
          parents: ["posts"],
          type: ParserType.attribute,
          selectors: [
            ".imgur::href",
          ]
      )
    ],
  );
}

List<MemoModelPost> createMemoModelPostList(Map<String, Object> posts, MemoModelTopic currentTopic) {
  List<MemoModelPost> postList = [];

  for (Map<String, Object> value in posts.values.first as Iterable ) {
    var likeCount = 0;
    try {
      likeCount = int.parse(value["likeCount"].toString().split("\n")[0]);
    } catch (e) {}

        MemoModelPost memoModelPost = MemoModelPost(
            topic: currentTopic,
            text: value["msg"]?.toString(),
            age: value["age"].toString(),
            tipsInSatoshi: int.parse((value["tipsInSatoshi"] ?? "0").toString().replaceAll(",", "")),
            likeCounter: likeCount,
            replyCounter: int.parse((value["replyCount"] ?? "0").toString()),
            created: value["created"].toString(),
            txHash: value["txhash"].toString().substring("/post".length),
            imageUrl: value["imgur"]?.toString(),
            creator: MemoModelCreator(name: value["creatorName"].toString(),
            id: value["profileUrl"].toString().substring(8)));

    String text = memoModelPost.text ?? "";
    String trigger = "MemoApp.YouTube.AddPlayer('";
    if (text.contains(trigger)) {
      int i = text.indexOf(', ');
      memoModelPost.videoUrl="https://www.youtube.com/watch?v="
          + text.substring(i+"', '".length-1,text.indexOf("');", i-1));
    }

    if (memoModelPost.videoUrl == null && memoModelPost.imageUrl == null)
      continue;

    postList.add(memoModelPost);
  }

  currentTopic.posts = postList;
  return postList;
}

void printMemoModelPost(List<MemoModelPost> postList) {
  for (MemoModelPost p in postList) {
    print(p.text ?? "");
    print(p.imageUrl ?? "");
    print(p.videoUrl ?? "");
    print(p.creator!.name);
    print(p.creator!.id);
    print(p.txHash);
    print(p.age);
    print(p.created);
  }
}

void testMemoSend() async {
  // print("\n\n" + await doMemoAction("PostMessage", MemoCode.profileMessage,""));
  // print("\n${await doMemoAction("IMG1 https://imgur.com/eIEjcUe", MemoCode.ProfileMessage,"")}");
  // print("\n${await doMemoAction("IMG2 https://i.imgur.com/eIEjcUe.jpeg", MemoCode.ProfileMessage,"")}");
  // print("\n${await doMemoAction("YT1 https://youtu.be/dQw4w9WgXcQ", MemoCode.ProfileMessage,"")}");
  // print("\n${await doMemoAction("OD1 https://odysee.com/@BitcoinMap:9/HijackingBitcoin:73", MemoCode.ProfileMessage,"")}");
  // print("\n${await doMemoAction("OD2 https://odysee.com/%24/embed/%40BitcoinMap%3A9%2FHijackingBitcoin%3A73?r=9n3v5rTk1CsSYkoqD3gER4SHNML8SxwH", MemoCode.ProfileMessage,"")}");
  //
  // print("\n${await doMemoAction("YT2 https://www.youtube.com/watch?v=dQw4w9WgXcQ", MemoCode.ProfileMessage,"")}");
  // sleep(Duration(seconds: 1));
  // var other = await doMemoAction("reply", MemoCode.postReply,
  //     MemoTransformation.reOrderTxHash("ba832cad4e4f45b9158811e2914bc57b89fd100c4d3eb6f871a757d0b14db3f3"));
  //
  // print("\n" + other);
  var other = await doMemoAction(
    MemoTransformation.reOrderTxHash("bad2095d2f5e177ffd4da96fd0220ebcb8de7b9e1cffac9d0c7667b403204072"), MemoCode.postLike, "");

  print("\n" + other);
  // sleep(Duration(seconds: 1));
  // other = await doMemoAction("Keloke", MemoCode.ProfileName,"");
  // print("\n" + other);
  // sleep(Duration(seconds: 1));
  // other = await doMemoAction("Ke paso en Barrio Bitcoin", MemoCode.ProfileText,"");
  // print("\n" + other);
  // sleep(Duration(seconds: 1));
  // other = await doMemoAction("Bitcoin+Map", MemoCode.TopicFollow,"");
  // print("\n" + other);
  // sleep(Duration(seconds: 1));
  // other = await doMemoAction("Escuchame wow increible no me digas ke veina naguara vergacion", MemoCode.TopicMessage, "zxcvsadf");
  // print("\n" + other);
  // sleep(Duration(seconds: 1));
  // other = await doMemoAction("Bitcoin+Map", MemoCode.TopicFollowUndo,"");
  // print("\n" + other);
  // sleep(Duration(seconds: 1));
  // var other = await doMemoAction("17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ", MemoCode.MuteUser,"");
  // print("\n$other");
  // sleep(Duration(seconds: 1));
  // other = await doMemoAction("17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ", MemoCode.MuteUndo,"");
  // print("\n" + other);
}

Future<String> doMemoAction (String memoMessage, MemoCode memoAction, String memoTopic) async {
  print("\n${memoAction.opCode}\n${memoAction.name}");
  final service = await ElectrumWebSocketService.connect(
      "wss://${mainnetServers[2]}:50004");

  final provider = ElectrumProvider(service);

  const network = BitcoinCashNetwork.mainnet;

  final privateKey = ECPrivate.fromWif("5HtpWVLipP5iKskfrhZLcxveVV39JZpiMGQseYRepRDUPGp97sU", netVersion: network.wifNetVer);

  final publicKey = privateKey.getPublic();

  final BitcoinCashAddress p2pkhAddress =
      BitcoinCashAddress.fromBaseAddress(publicKey.toAddress());

  print("https://bchblockexplorer.com/address/${p2pkhAddress.address}");

  final List<ElectrumUtxo> elctrumUtxos = await requestElectrumUtxosFilterCashtokenUtxos(provider, p2pkhAddress);

  List<UtxoWithAddress> utxos = addUtxoAddressDetailsAsOwnerDetailsToCreateUtxoWithAddressModelList(elctrumUtxos, p2pkhAddress, publicKey);

  utxos = removeSlpUtxos(utxos);

  final BigInt walletBalance = getTotalWalletBalanceInSatoshis(utxos);

  final BigInt fee = BtcUtils.toSatoshi("0.000004");
  final BtcTransaction tx = createTransaction(p2pkhAddress, walletBalance, fee, network, utxos, memoMessage, memoAction, memoTopic, privateKey);
  
  print(tx.txId());
  print("http://memo.cash/explore/tx/${tx.txId()}");
  print("https://bchblockexplorer.com/tx/${tx.txId()}");

  await broadcastTransaction(provider, tx);
  return "Success";
}

Future<void> broadcastTransaction(ElectrumProvider provider, BtcTransaction tx) async {
  await provider.request(
      ElectrumRequestBroadCastTransaction(transactionRaw: tx.toHex()),timeout: const Duration(seconds: 30));
}

BtcTransaction createTransaction(BitcoinCashAddress p2pkhAddress, BigInt walletBalance, BigInt fee, BitcoinCashNetwork network, List<UtxoWithAddress> utxos, String memoMessage, MemoCode memoAction, String memoTopic, ECPrivate privateKey) {
  final MemoTransactionBuilder txBuilder = createTransactionBuilder(p2pkhAddress, walletBalance, fee, network, utxos, memoMessage, memoAction, memoTopic);
  final tx =
      txBuilder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return privateKey.signECDSA(trDigest, sighash: sighash);
  });
  return tx;
}

MemoTransactionBuilder createTransactionBuilder(BitcoinCashAddress p2pkhAddress, BigInt walletBalance, BigInt fee, BitcoinCashNetwork network, List<UtxoWithAddress> utxos, String memoMessage, MemoCode memoAction, String memoTopic) {
  final txBuilder = MemoTransactionBuilder(
    outPuts: [
      BitcoinOutput(
        address: p2pkhAddress.baseAddress,
        value: walletBalance -
            fee,
      )
    ],
    fee: fee,
    network: network,
    utxos: utxos,
    memo: memoMessage,
      memoCode: memoAction,
      memoTopic: memoTopic
  );
  return txBuilder;
}

BigInt getTotalWalletBalanceInSatoshis(List<UtxoWithAddress> utxos) {
   final sumOfUtxo = utxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    throw Exception("No UTXO funds found");
  }
  return sumOfUtxo;
}

Future<List<ElectrumUtxo>> requestElectrumUtxosFilterCashtokenUtxos(ElectrumProvider provider, BitcoinCashAddress p2pkhAddress) async {
  final elctrumUtxos =
      await provider.request(ElectrumRequestScriptHashListUnspent(
    scriptHash: p2pkhAddress.baseAddress.pubKeyHash(),
    includeTokens: false,
  ));
  return elctrumUtxos;
}

List<UtxoWithAddress> addUtxoAddressDetailsAsOwnerDetailsToCreateUtxoWithAddressModelList(List<ElectrumUtxo> elctrumUtxos, BitcoinCashAddress p2pkhAddress, ECPublic publicKey) {
  List<UtxoWithAddress> utxos = elctrumUtxos
      .map((e) => UtxoWithAddress(
          utxo: e.toUtxo(p2pkhAddress.type),
          ownerDetails: UtxoAddressDetails(
              publicKey: publicKey.toHex(), address: p2pkhAddress.baseAddress)))
      .toList();
  return utxos;
}

List<UtxoWithAddress> removeSlpUtxos(List<UtxoWithAddress> utxos) {
  for(UtxoWithAddress utxo in utxos.clone()) {
    if (utxo.utxo.value.toSignedInt32 == 546) {
      utxos.remove(utxo);
    }
  }
  return utxos;
}
