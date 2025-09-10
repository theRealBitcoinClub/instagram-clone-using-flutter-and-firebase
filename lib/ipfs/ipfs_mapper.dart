class IPFSMappingEntry {
  final String ipfsCid;
  final String shortId;
  final int timestamp;
  final String createdAt;
  final String type;

  IPFSMappingEntry({required this.ipfsCid, required this.shortId, required this.timestamp, required this.createdAt, this.type = 'image'});

  factory IPFSMappingEntry.fromJson(Map<String, dynamic> json) {
    return IPFSMappingEntry(
      ipfsCid: json['ipfs_cid'],
      shortId: json['short_id'],
      timestamp: json['timestamp'],
      createdAt: json['created_at'],
      type: json['type'] ?? 'image',
    );
  }

  Map<String, dynamic> toJson() {
    return {'ipfs_cid': ipfsCid, 'short_id': shortId, 'timestamp': timestamp, 'created_at': createdAt, 'type': type};
  }
}

class Metadata {
  final int totalMappings;
  final String lastUpdated;
  final String? lastShortId;
  final String version;

  Metadata({required this.totalMappings, required this.lastUpdated, this.lastShortId, this.version = '1.0'});

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      totalMappings: json['total_mappings'],
      lastUpdated: json['last_updated'],
      lastShortId: json['last_short_id'],
      version: json['version'] ?? '1.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {'total_mappings': totalMappings, 'last_updated': lastUpdated, 'last_short_id': lastShortId, 'version': version};
  }
}

class IPFSShortIDMapper {
  final String githubRepoUrl;
  final String mappingFilename;
  final String metadataFilename;

  Map<String, IPFSMappingEntry> mapping = {};
  Metadata? metadata;

  IPFSShortIDMapper({required this.githubRepoUrl, this.mappingFilename = 'ipfs_mapping.json', this.metadataFilename = 'metadata.json'});

  /// Encode IPFS CID to a short hexadecimal timestamp ID
  /// Format: IPFS://4JD42PL9
  Map<String, dynamic> encodeIpfsToShortId(String ipfsCid) {
    // Get current timestamp in milliseconds
    final timestampMs = DateTime.now().millisecondsSinceEpoch;

    // Convert to hexadecimal and remove '0x' prefix
    final hexTimestamp = timestampMs.toRadixString(16).toUpperCase();

    // Ensure it's exactly 8 characters (pad with zeros if needed)
    final shortId = hexTimestamp.padLeft(8, '0').substring(hexTimestamp.length - 8);

    final shortUrl = 'IPFS://$shortId';

    return {'short_url': shortUrl, 'short_id': shortId, 'timestamp_ms': timestampMs};
  }

  /// Decode short ID back to IPFS CID using the mapping
  String decodeShortIdToIpfs(String shortId, {Map<String, IPFSMappingEntry>? customMapping}) {
    final mappingData = customMapping ?? mapping;

    // Remove IPFS:// prefix if present
    if (shortId.startsWith('IPFS://')) {
      shortId = shortId.substring(7);
    }

    if (mappingData.containsKey(shortId)) {
      return mappingData[shortId]!.ipfsCid;
    } else {
      throw Exception('Short ID $shortId not found in mapping');
    }
  }

  /// Generate a mapping entry with additional metadata
  IPFSMappingEntry generateMappingEntry(String ipfsCid, String shortId, int timestampMs) {
    return IPFSMappingEntry(
      ipfsCid: ipfsCid,
      shortId: shortId,
      timestamp: timestampMs,
      createdAt: DateTime.fromMillisecondsSinceEpoch(timestampMs).toIso8601String(),
      type: 'image',
    );
  }
}
