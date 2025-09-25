import 'graph_models.dart';

class GraphQLQueryBuilder {
  static String getTx(String hash) {
    return '''
      query {
        tx(hash: "$hash") {
          ${Tx.queryFields}
        }
      }
    ''';
  }

  static String getTxs(List<String> hashes) {
    final hashesString = hashes.map((h) => '"$h"').join(',');
    return '''
      query {
        txs(hashes: [$hashesString]) {
          ${Tx.queryFields}
        }
      }
    ''';
  }

  static String getAddress(String address) {
    return '''
      query {
        address(address: "$address") {
          ${Lock.queryFields}
        }
      }
    ''';
  }

  static String getAddresses(List<String> addresses) {
    final addressesString = addresses.map((a) => '"$a"').join(',');
    return '''
      query {
        addresses(addresses: [$addressesString]) {
          ${Lock.queryFields}
        }
      }
    ''';
  }

  static String getBlock(String hash) {
    return '''
      query {
        block(hash: "$hash") {
          ${Block.queryFields}
        }
      }
    ''';
  }

  static String getNewestBlock() {
    return '''
      query {
        block_newest {
          ${Block.queryFields}
        }
      }
    ''';
  }

  static String getBlocks({bool? newest, int? start}) {
    final newestStr = newest != null ? 'newest: $newest' : '';
    final startStr = start != null ? 'start: $start' : '';
    final args = [newestStr, startStr].where((s) => s.isNotEmpty).join(', ');

    return '''
      query {
        blocks($args) {
          ${Block.queryFields}
        }
      }
    ''';
  }

  static String getProfiles(List<String> addresses) {
    final addressesString = addresses.map((a) => '"$a"').join(',');
    return '''
      query {
        profiles(addresses: [$addressesString]) {
          ${Profile.queryFields}
        }
      }
    ''';
  }

  static String getPosts(List<String> txHashes) {
    final txHashesString = txHashes.map((h) => '"$h"').join(',');
    return '''
      query {
        posts(txHashes: [$txHashesString]) {
          ${Post.queryFields}
        }
      }
    ''';
  }

  static String getNewestPosts({DateTime? start, String? tx, int? limit}) {
    final args = <String>[];
    if (start != null) args.add('start: "${start.toIso8601String()}"');
    if (tx != null) args.add('tx: "$tx"');
    if (limit != null) args.add('limit: $limit');

    return '''
      query {
        posts_newest(${args.join(', ')}) {
          ${Post.queryFields}
        }
      }
    ''';
  }

  static String getRoom(String name) {
    return '''
      query {
        room(name: "$name") {
          ${Room.queryFields}
        }
      }
    ''';
  }
}
