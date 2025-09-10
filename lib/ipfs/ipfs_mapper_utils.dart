import 'github_ipfs_mapper.dart';
import 'ipfs_mapper.dart';

extension IPFSMapperUtils on GitHubIPFSMapper {
  /// Retrieve a specific mapping entry by short ID
  Future<IPFSMappingEntry?> getMappingEntry(String shortId) async {
    if (mapping.isEmpty) {
      await downloadMappingFile();
    }

    final shortIdClean = shortId.replaceAll('IPFS://', '');
    return mapping[shortIdClean];
  }

  /// Get the total number of mappings from metadata
  Future<int> getTotalMappingsCount() async {
    if (metadata == null) {
      await downloadMetadataFile();
    }

    return metadata?.totalMappings ?? 0;
  }

  /// Get all mappings
  Future<Map<String, IPFSMappingEntry>> getAllMappings() async {
    if (mapping.isEmpty) {
      await downloadMappingFile();
    }

    return mapping;
  }

  /// Check if there are updates by comparing metadata
  Future<Map<String, dynamic>> checkForUpdates() async {
    final oldCount = metadata?.totalMappings ?? 0;
    final currentMetadata = await downloadMetadataFile();
    final newCount = currentMetadata?.totalMappings ?? 0;

    return {'has_updates': newCount > oldCount, 'update_count': newCount - oldCount};
  }

  /// Resolve short ID to full IPFS URL
  Future<String> resolveIpfsUrl(String shortId) async {
    final ipfsCid = decodeShortIdToIpfs(shortId);
    return 'https://ipfs.io/ipfs/$ipfsCid';
  }

  /// Search mappings by IPFS CID
  Future<IPFSMappingEntry?> findMappingByCid(String ipfsCid) async {
    if (mapping.isEmpty) {
      await downloadMappingFile();
    }

    return mapping.values.firstWhere((entry) => entry.ipfsCid == ipfsCid, orElse: () => throw Exception('CID $ipfsCid not found in mapping'));
  }
}
