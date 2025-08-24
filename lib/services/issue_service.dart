// services/issue_service.dart
import 'dart:io';
import 'package:civic_link/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/issue_model.dart';

class IssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Submit a new issue
  Future<String> submitIssue({
    required String title,
    required String description,
    required String category,
    required String priority,
    required List<XFile> images,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      print("📝 IssueService: Starting issue submission");

      final user = currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      // Upload images first
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        print("📸 Uploading ${images.length} images...");
        imageUrls = await _uploadImages(images);
        print("✅ Images uploaded successfully");
      }

      // Create issue document
      final issueData = IssueModel(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        category: category,
        status: 'pending',
        priority: priority,
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: user.displayName ?? 'Anonymous',
        latitude: latitude,
        longitude: longitude,
        address: address,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('issues')
          .add(issueData.toFirestore());

      print("✅ Issue submitted successfully with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Error submitting issue: $e");
      throw 'Failed to submit issue: $e';
    }
  }

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages(List<XFile> images) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        print("📸 Uploading image ${i + 1}/${images.length}");

        final file = File(images[i].path);
        final fileName =
            'issues/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        final ref = _storage.ref().child(fileName);
        final uploadTask = ref.putFile(file);

        final snapshot = await uploadTask;

        // Check task state
        if (snapshot.state != TaskState.success) {
          throw Exception(
            'Image upload failed with state: ${snapshot.state}, bytesTransferred: ${snapshot.bytesTransferred}, totalBytes: ${snapshot.totalBytes}',
          );
        }

        // Retry getDownloadURL up to 3 times with 2-second delays
        String? downloadUrl;
        int retries = 3;
        while (retries > 0) {
          try {
            downloadUrl = await snapshot.ref.getDownloadURL();
            if (downloadUrl != null) {
              print("✅ getDownloadURL succeeded on attempt $i: $downloadUrl");
              break;
            } else {
              print("⚠️ getDownloadURL returned null, retrying...");
            }
          } catch (e, stackTrace) {
            print(
              "⚠️ getDownloadURL attempt failed: $e\nStack trace: $stackTrace",
            );
            if (retries == 1) {
              print("❌ All retries failed for image ${i + 1}");
              throw Exception('Failed to get download URL after retries: $e');
            }
            await Future.delayed(const Duration(seconds: 2));
            retries--;
          }
        }

        if (downloadUrl == null) {
          print(
            "❌ Download URL still null after retries for image ${i + 1}, skipping...",
          );
          continue; // Skip this image and proceed with others
        }

        urls.add(downloadUrl);
        print("✅ Image ${i + 1} uploaded: $downloadUrl");
      } catch (e, stackTrace) {
        print("❌ Error uploading image ${i + 1}: $e\nStack trace: $stackTrace");
        throw Exception('Failed to upload image: $e');
      }
    }

    return urls;
  }

  // Get current location
  Future<Position> getCurrentLocation() async {
    try {
      print("📍 Getting current location...");

      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("✅ Location obtained: ${position.latitude}, ${position.longitude}");
      return position;
    } catch (e) {
      print("❌ Error getting location: $e");
      throw 'Failed to get location: $e';
    }
  }

  // Get address from coordinates (simplified version)
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // For now, return a formatted coordinate string
      // In a real app, you'd use geocoding service
      return "Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}";
    } catch (e) {
      print("❌ Error getting address: $e");
      return "Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}";
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      print("📸 Opening camera...");

      // Check camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw 'Camera permission denied';
      }

      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxHeight: 1024,
        maxWidth: 1024,
      );

      if (image == null) {
        print("⚠️ Camera image selection cancelled");
        return null;
      }

      print("✅ Image picked from camera: ${image.path}");
      return image;
    } catch (e) {
      print("❌ Error picking from camera: $e");
      throw 'Failed to pick from camera: $e';
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      print("🖼️ Opening gallery...");

      // Check gallery permission
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        throw 'Gallery permission denied';
      }

      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxHeight: 1024,
        maxWidth: 1024,
      );

      if (image == null) {
        print("⚠️ Gallery image selection cancelled");
        return null;
      }

      print("✅ Image picked from gallery: ${image.path}");
      return image;
    } catch (e) {
      print("❌ Error picking from gallery: $e");
      throw 'Failed to pick from gallery: $e';
    }
  }

  // Get all issues
  Future<List<IssueModel>> getAllIssues() async {
    try {
      print("🔍 Getting all issues...");

      final querySnapshot =
          await _firestore
              .collection('issues')
              .orderBy('createdAt', descending: true)
              .get();

      final issues =
          querySnapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();

      print("✅ Found ${issues.length} issues");
      return issues;
    } catch (e) {
      print("❌ Error getting all issues: $e");
      throw 'Failed to get issues: $e';
    }
  }

  // Get user's issues
  Future<List<IssueModel>> getUserIssues() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      print("🔍 Getting issues for user: ${user.uid}");

      final querySnapshot =
          await _firestore
              .collection('issues')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();

      final issues =
          querySnapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();

      print("✅ Found ${issues.length} issues for user");
      return issues;
    } catch (e) {
      print("❌ Error getting user issues: $e");
      throw 'Failed to get user issues: $e';
    }
  }

  // Update issue status (for officials)
  Future<void> updateIssueStatus({
    required String issueId,
    required String newStatus,
    required String adminNotes,
  }) async {
    try {
      print("🔄 Updating issue $issueId status to $newStatus");

      await _firestore.collection('issues').doc(issueId).update({
        'status': newStatus,
        'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to user
      final issueDoc = await _firestore.collection('issues').doc(issueId).get();
      if (issueDoc.exists) {
        final issueData = issueDoc.data()!;
        final userId = issueData['userId'];
        final issueTitle = issueData['title'];

        // Send notification to user
        await NotificationService().sendIssueUpdateNotification(
          userId: userId,
          issueId: issueId,
          issueTitle: issueTitle,
          newStatus: newStatus,
          adminNotes: adminNotes,
        );
      }

      print("✅ Issue status updated and notification sent");
    } catch (e) {
      print("❌ Error updating issue status: $e");
      throw 'Failed to update issue status: $e';
    }
  }

  // Stream of user's issues for real-time updates
  Stream<List<IssueModel>> getUserIssuesStream() {
    final user = currentUser;
    if (user == null) {
      print("❌ No user for stream");
      return Stream.value([]);
    }

    print("🔄 Setting up issues stream for user: ${user.uid}");

    return FirebaseFirestore.instance
        .collection('issues')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          print("❌ Stream error: $error");
          if (error is FirebaseException) {
            print(
              "🔥 Firebase Exception in stream: ${error.code} - ${error.message}",
            );
          }
        })
        .map((snapshot) {
          print("📊 Stream update: ${snapshot.docs.length} documents");
          return snapshot.docs
              .map((doc) {
                try {
                  return IssueModel.fromFirestore(doc);
                } catch (e) {
                  print("❌ Error parsing document in stream ${doc.id}: $e");
                  // Return a placeholder or skip this document
                  return null;
                }
              })
              .where((issue) => issue != null)
              .cast<IssueModel>()
              .toList();
        });
  }

  // Get issues by department (for officials)
  Future<List<IssueModel>> getIssuesByDepartment(String department) async {
    try {
      print("🔍 IssueService: Getting issues for department: $department");

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('issues')
              .where('category', isEqualTo: department)
              .orderBy('createdAt', descending: true)
              .get();

      final issues =
          querySnapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();

      print(
        "✅ IssueService: Found ${issues.length} issues for department $department",
      );
      return issues;
    } catch (e) {
      print("❌ Error getting issues by department: $e");
      return [];
    }
  }

  Future<List<IssueModel>> getAssignedIssues(String userId) async {
    try {
      print("🔍 IssueService: Getting assigned issues for user: $userId");

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('issues')
              .where('assignedTo', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      final issues =
          querySnapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();

      print(
        "✅ IssueService: Found ${issues.length} assigned issues for user $userId",
      );
      return issues;
    } catch (e) {
      print("❌ Error getting assigned issues: $e");
      return [];
    }
  }

  Future<void> bulkUpdateIssues({
    required List<String> issueIds,
    required String newStatus,
    required String notes,
  }) async {
    try {
      print(
        "🔄 IssueService: Bulk updating ${issueIds.length} issues to status: $newStatus",
      );

      final batch = FirebaseFirestore.instance.batch();

      for (String issueId in issueIds) {
        final docRef = FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId);
        batch.update(docRef, {
          'status': newStatus,
          'adminNotes': notes,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': currentUser?.uid,
        });
      }

      await batch.commit();
      print(
        "✅ IssueService: Bulk update completed for ${issueIds.length} issues",
      );
    } catch (e) {
      print("❌ Error in bulk update: $e");
      throw 'Failed to update issues: $e';
    }
  }

  Future<void> assignIssue({
    required String issueId,
    required String assignedToId,
    required String assignedToName,
    required String notes,
  }) async {
    try {
      print("👥 IssueService: Assigning issue $issueId to $assignedToName");

      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
            'assignedTo': assignedToId,
            'assignedToName': assignedToName,
            'adminNotes': notes,
            'status': 'in_progress',
            'updatedAt': FieldValue.serverTimestamp(),
            'assignedAt': FieldValue.serverTimestamp(),
            'assignedBy': currentUser?.uid,
          });

      print("✅ IssueService: Issue assigned successfully");
    } catch (e) {
      print("❌ Error assigning issue: $e");
      throw 'Failed to assign issue: $e';
    }
  }
}
