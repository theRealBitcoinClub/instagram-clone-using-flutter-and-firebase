import 'graph_client.dart';
import 'graph_models.dart';
import 'graph_query_builder.dart';

class GraphCashService {
  final GraphQLClient _client;

  GraphCashService() : _client = GraphQLClient();

  // Transaction operations
  Future<Tx?> getTransaction(String hash) async {
    final query = GraphQLQueryBuilder.getTx(hash);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final txData = response.data?['tx'];
    return txData != null ? Tx.fromJson(txData) : null;
  }

  Future<List<Tx>> getTransactions(List<String> hashes) async {
    final query = GraphQLQueryBuilder.getTxs(hashes);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final txsData = response.data?['txs'] as List?;
    return txsData?.map((x) => Tx.fromJson(x)).toList() ?? [];
  }

  // Address operations
  Future<Lock?> getAddress(String address) async {
    final query = GraphQLQueryBuilder.getAddress(address);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final addressData = response.data?['address'];
    return addressData != null ? Lock.fromJson(addressData) : null;
  }

  Future<List<Lock>> getAddresses(List<String> addresses) async {
    final query = GraphQLQueryBuilder.getAddresses(addresses);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final addressesData = response.data?['addresses'] as List?;
    return addressesData?.map((x) => Lock.fromJson(x)).toList() ?? [];
  }

  // Block operations
  Future<Block?> getBlock(String hash) async {
    final query = GraphQLQueryBuilder.getBlock(hash);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final blockData = response.data?['block'];
    return blockData != null ? Block.fromJson(blockData) : null;
  }

  Future<Block?> getNewestBlock() async {
    final query = GraphQLQueryBuilder.getNewestBlock();
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final blockData = response.data?['block_newest'];
    return blockData != null ? Block.fromJson(blockData) : null;
  }

  Future<List<Block>> getBlocks({bool? newest, int? start}) async {
    final query = GraphQLQueryBuilder.getBlocks(newest: newest, start: start);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final blocksData = response.data?['blocks'] as List?;
    return blocksData?.map((x) => Block.fromJson(x)).toList() ?? [];
  }

  // Profile operations
  Future<List<Profile>> getProfiles(List<String> addresses) async {
    final query = GraphQLQueryBuilder.getProfiles(addresses);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final profilesData = response.data?['profiles'] as List?;
    return profilesData?.map((x) => Profile.fromJson(x)).toList() ?? [];
  }

  // Post operations
  Future<List<Post>> getPosts(List<String> txHashes) async {
    final query = GraphQLQueryBuilder.getPosts(txHashes);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final postsData = response.data?['posts'] as List?;
    return postsData?.map((x) => Post.fromJson(x)).toList() ?? [];
  }

  Future<List<Post>> getNewestPosts({DateTime? start, String? tx, int? limit}) async {
    final query = GraphQLQueryBuilder.getNewestPosts(start: start, tx: tx, limit: limit);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final postsData = response.data?['posts_newest'] as List?;
    return postsData?.map((x) => Post.fromJson(x)).toList() ?? [];
  }

  // Room operations
  Future<Room?> getRoom(String name) async {
    final query = GraphQLQueryBuilder.getRoom(name);
    final response = await _client.query(query);

    if (response.hasErrors) {
      throw GraphQLException(response.errors!.first.toString());
    }

    final roomData = response.data?['room'];
    return roomData != null ? Room.fromJson(roomData) : null;
  }

  void dispose() {
    _client.close();
  }
}
