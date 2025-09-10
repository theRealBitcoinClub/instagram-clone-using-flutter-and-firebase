import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/ipfs/ipfs_mapper_utils.dart';

import 'github_ipfs_mapper.dart';

void main() async {
  // Initialize the mapper
  const githubRepoUrl = "https://github.com/${IpfsConfig.ghRepo}";
  const githubToken = IpfsConfig.ghToken; // Optional but recommended

  final mapper = GitHubIPFSMapper(githubRepoUrl: githubRepoUrl, githubToken: githubToken);

  // Example: Add a new IPFS file to mapping
  const newIpfsCid = "QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco";
  final result = await mapper.uploadNewMapping(newIpfsCid);

  if (result != null) {
    print("Created mapping: ${result['short_url']}");
    print("Short ID: ${result['short_id']}");
  }

  // Example: Retrieve a mapping
  final entry = await mapper.getMappingEntry(result!['short_id']!);
  print("IPFS CID: ${entry?.ipfsCid}");

  // Example: Decode a short URL
  try {
    final decodedCid = mapper.decodeShortIdToIpfs(result['short_url']!);
    print("Decoded CID: $decodedCid");
  } catch (e) {
    print("Error decoding: $e");
  }

  // Example: Get IPFS URL for display
  final ipfsUrl = await mapper.resolveIpfsUrl(result['short_url']!);
  print("IPFS URL: $ipfsUrl");

  // Example: Check for updates
  final updateInfo = await mapper.checkForUpdates();
  print("Updates available: ${updateInfo['has_updates']}, Count: ${updateInfo['update_count']}");

  // Example: Get total mappings count
  final totalCount = await mapper.getTotalMappingsCount();
  print("Total mappings: $totalCount");
}
