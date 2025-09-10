import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config_ipfs.dart';
import 'ipfs_mapper.dart';

class GitHubIPFSMapper extends IPFSShortIDMapper {
  final String? githubToken;
  final Map<String, String> headers;

  GitHubIPFSMapper({
    required String githubRepoUrl,
    String mappingFilename = IpfsConfig.mappingFile,
    String metadataFilename = IpfsConfig.metadataFile,
    this.githubToken,
  }) : headers = {if (githubToken != null) 'Authorization': 'token $githubToken', 'Accept': 'application/vnd.github.v3+json'},
       super(githubRepoUrl: githubRepoUrl, mappingFilename: mappingFilename, metadataFilename: metadataFilename);

  /// Convert GitHub repo URL to raw content URL
  String getRawGithubUrl(String filename) {
    final cleanUrl = githubRepoUrl.replaceAll(RegExp(r'/$'), '');
    if (cleanUrl.contains('github.com')) {
      return cleanUrl.replaceFirst('github.com', 'raw.githubusercontent.com') + '/main/$filename';
    }
    return '$cleanUrl/$filename';
  }

  /// Download the complete mapping file from GitHub
  Future<Map<String, IPFSMappingEntry>> downloadMappingFile() async {
    try {
      final url = getRawGithubUrl(mappingFilename);
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        mapping = jsonData.map((key, value) => MapEntry(key, IPFSMappingEntry.fromJson(value)));
        return mapping;
      } else {
        print('Failed to download mapping file: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Error downloading mapping file: $e');
      return {};
    }
  }

  /// Download the metadata file from GitHub
  Future<Metadata?> downloadMetadataFile() async {
    try {
      final url = getRawGithubUrl(metadataFilename);
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        metadata = Metadata.fromJson(jsonData);
        return metadata;
      } else {
        print('Failed to download metadata file: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading metadata file: $e');
      return null;
    }
  }

  /// Get the SHA hash of a file in the repository
  Future<String?> getFileSha(String filename) async {
    try {
      final repoPath = githubRepoUrl.split('github.com/').last;
      final apiUrl = 'https://api.github.com/repos/$repoPath/contents/$filename';

      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['sha'];
      }
      return null;
    } catch (e) {
      print('Error getting file SHA: $e');
      return null;
    }
  }

  /// Complete workflow: download, update, and upload mapping
  Future<Map<String, String>?> uploadNewMapping(String newIpfsCid) async {
    try {
      // Download current mapping and metadata
      final currentMapping = await downloadMappingFile();
      var currentMetadata = await downloadMetadataFile() ?? Metadata(totalMappings: 0, lastUpdated: DateTime.now().toIso8601String());

      // Generate new short ID
      final encodingResult = encodeIpfsToShortId(newIpfsCid);
      final shortUrl = encodingResult['short_url']!;
      final shortId = encodingResult['short_id']!;
      final timestampMs = encodingResult['timestamp_ms'] as int;

      // Create new mapping entry
      final newEntry = generateMappingEntry(newIpfsCid, shortId, timestampMs);

      // Update mapping
      final updatedMapping = Map<String, IPFSMappingEntry>.from(currentMapping);
      updatedMapping[shortId] = newEntry;

      // Update metadata
      final updatedMetadata = Metadata(
        totalMappings: updatedMapping.length,
        lastUpdated: DateTime.now().toIso8601String(),
        lastShortId: shortId,
        version: currentMetadata.version,
      );

      // Get SHA of existing files for update
      final mappingSha = await getFileSha(mappingFilename);
      final metadataSha = await getFileSha(metadataFilename);

      // Prepare API URLs
      final repoPath = githubRepoUrl.split('github.com/').last;
      final apiBase = 'https://api.github.com/repos/$repoPath/contents';

      // Update mapping file
      final mappingResponse = await http.put(
        Uri.parse('$apiBase/$mappingFilename'),
        headers: headers,
        body: json.encode({
          "message": "Add IPFS mapping: $shortId -> $newIpfsCid",
          "content": base64.encode(utf8.encode(json.encode(updatedMapping))),
          "sha": mappingSha,
        }),
      );

      if (mappingResponse.statusCode != 200 && mappingResponse.statusCode != 201) {
        throw Exception('Failed to update mapping file: ${mappingResponse.body}');
      }

      // Update metadata file
      final metadataResponse = await http.put(
        Uri.parse('$apiBase/$metadataFilename'),
        headers: headers,
        body: json.encode({
          "message": "Update metadata with new mapping count",
          "content": base64.encode(utf8.encode(json.encode(updatedMetadata.toJson()))),
          "sha": metadataSha,
        }),
      );

      if (metadataResponse.statusCode != 200 && metadataResponse.statusCode != 201) {
        throw Exception('Failed to update metadata file: ${metadataResponse.body}');
      }

      return {'short_url': shortUrl, 'short_id': shortId};
    } catch (e) {
      print('Error uploading new mapping: $e');
      return null;
    }
  }
}
