import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/attachment_model.dart';

class AttachmentService {
  final SupabaseClient _supabase;
  final String _storageBucket = 'chat-attachments';
  final Uuid _uuid = const Uuid();

  AttachmentService(this._supabase);

  String get storageBucket => _storageBucket;

  Future<List<AttachmentModel>> uploadFiles({
    required String chatId,
    required String messageId,
    required List<File> files,
  }) async {
    if (files.isEmpty) return [];
    final uploaded = <AttachmentModel>[];

    for (final file in files) {
      final fileName = p.basename(file.path);
      final storagePath = 'chat/$chatId/${_uuid.v4()}_$fileName';
      try {
        print('📤 Uploading: $fileName');
        print('📍 To path: $storagePath');
        final String uploadedPath = await _supabase.storage.from(_storageBucket).upload(
              storagePath,
              file,
              fileOptions: FileOptions(cacheControl: '3600', upsert: false),
            );
        if (uploadedPath.isEmpty) {
          throw Exception('Supabase returned an empty upload path for "$fileName".');
        }
        
        // Ensure we store only the relative path, without bucket prefix
        String cleanedPath = uploadedPath;
        if (cleanedPath.startsWith('$_storageBucket/')) {
          cleanedPath = cleanedPath.replaceFirst('$_storageBucket/', '');
          print('🧹 Cleaned stored path from: $uploadedPath to: $cleanedPath');
        } else {
          print('✅ Path is clean: $cleanedPath');
        }
        
        uploaded.add(AttachmentModel(
          id: _uuid.v4(),
          messageId: messageId,
          fileUrl: cleanedPath,
          fileName: fileName,
          extension: p.extension(fileName).toLowerCase(),
          downloadState: AttachmentDownloadState.notDownloaded.name,
          localPath: null,
          createdAt: DateTime.now(),
        ));
      } catch (error) {
        throw Exception('Failed to upload attachment "$fileName": $error');
      }
    }

    return uploaded;
  }

  Future<Uint8List> downloadAttachmentBytes(String storagePath) async {
    try {
      // Clean up the storage path - remove bucket name prefix if present
      String cleanPath = storagePath;
      if (cleanPath.startsWith('$_storageBucket/')) {
        cleanPath = cleanPath.replaceFirst('$_storageBucket/', '');
        print('🧹 Cleaned path from: $storagePath to: $cleanPath');
      }
      
      print('⬇️ Downloading bytes for: $cleanPath');
      print('📍 From bucket: $_storageBucket');
      
      // Try to list the file to verify it exists before downloading
      try {
        print('🔍 Checking if file exists in storage...');
        final fileList = await _supabase.storage.from(_storageBucket).list(path: '');
        final fileName = cleanPath.split('/').last;
        print('📦 Files in storage: ${fileList.map((f) => f.name).toList()}');
      } catch (e) {
        print('⚠️ Could not list storage (might be permission issue): $e');
      }
      
      final bytes = await _supabase.storage.from(_storageBucket).download(cleanPath);
      print('✅ Downloaded ${bytes.length} bytes successfully');
      return bytes;
    } catch (error) {
      print('❌ Download bytes failed: $error');
      throw Exception('Failed to download attachment "$storagePath": $error');
    }
  }

  Future<File> downloadAttachmentToLocal(String chatId, AttachmentModel attachment) async {
    try {
      print('📥 Starting download for: ${attachment.fileName}');
      final bytes = await downloadAttachmentBytes(attachment.fileUrl);
      
      if (bytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }
      
      final localFile = await _localFileForAttachment(chatId, attachment);
      print('💾 Creating directory: ${localFile.parent.path}');
      await localFile.parent.create(recursive: true);
      
      print('✍️ Writing ${bytes.length} bytes to: ${localFile.path}');
      await localFile.writeAsBytes(bytes, flush: true);
      
      final exists = await localFile.exists();
      final fileSize = await localFile.length();
      print('✅ File downloaded successfully: exists=$exists, size=$fileSize bytes');
      
      if (!exists || fileSize == 0) {
        throw Exception('File was not written properly');
      }
      
      return localFile;
    } catch (e) {
      print('❌ Download to local failed: $e');
      rethrow;
    }
  }

  Future<File> _localFileForAttachment(String chatId, AttachmentModel attachment) async {
    final dir = await getApplicationDocumentsDirectory();
    final chatDir = Directory(p.join(dir.path, 'chat_attachments', chatId));
    final sanitizedFileName = attachment.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return File(p.join(chatDir.path, '${attachment.id}_$sanitizedFileName'));
  }

  Future<bool> localAttachmentExists(String chatId, AttachmentModel attachment) async {
    final file = await _localFileForAttachment(chatId, attachment);
    return file.exists();
  }
}
