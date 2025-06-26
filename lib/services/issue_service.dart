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
        final downloadUrl = await snapshot.ref.getDownloadURL();

        urls.add(downloadUrl);
        print("✅ Image ${i + 1} uploaded: $downloadUrl");
      } catch (e) {
        print("❌ Error uploading image ${i + 1}: $e");
        throw 'Failed to upload image: $e';
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
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        print("✅ Image captured: ${image.path}");
      }

      return image;
    } catch (e) {
      print("❌ Error picking image from camera: $e");
      throw 'Failed to capture image: $e';
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      print("🖼️ Opening gallery...");

      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        print("✅ Image selected: ${image.path}");
      }

      return image;
    } catch (e) {
      print("❌ Error picking image from gallery: $e");
      throw 'Failed to select image: $e';
    }
  }

  // Pick multiple images
  Future<List<XFile>> pickMultipleImages() async {
    try {
      print("🖼️ Opening gallery for multiple selection...");

      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      print("✅ Selected ${images.length} images");
      return images;
    } catch (e) {
      print("❌ Error picking multiple images: $e");
      throw 'Failed to select images: $e';
    }
  }

  // Get user's issues
  Future<List<IssueModel>> getUserIssues() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      print("📋 Getting issues for user: ${user.email}");

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
      throw 'Failed to get issues: $e';
    }
  }

  // Get all issues (for map view)
  Future<List<IssueModel>> getAllIssues() async {
    try {
      print("🗺️ Getting all issues for map view");

      final querySnapshot =
          await _firestore
              .collection('issues')
              .orderBy('createdAt', descending: true)
              .limit(100) // Limit for performance
              .get();

      final issues =
          querySnapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();

      print("✅ Found ${issues.length} total issues");
      return issues;
    } catch (e) {
      print("❌ Error getting all issues: $e");
      throw 'Failed to get issues: $e';
    }
  }

  // Get issue by ID
  Future<IssueModel?> getIssueById(String issueId) async {
    try {
      final doc = await _firestore.collection('issues').doc(issueId).get();

      if (doc.exists) {
        return IssueModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print("❌ Error getting issue by ID: $e");
      return null;
    }
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String newStatus,
    String? adminNotes,
  }) async {
    try {
      // Update issue in Firestore
      await _firestore.collection('issues').doc(issueId).update({
        'status': newStatus,
        'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get issue details to find the user
      final issueDoc = await _firestore.collection('issues').doc(issueId).get();
      if (issueDoc.exists) {
        final issueData = issueDoc.data() as Map<String, dynamic>;
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
      return Stream.value([]);
    }

    return _firestore
        .collection('issues')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => IssueModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Add these methods to your existing issue_service.dart

  // Get issues by department (for officials)
  Future<List<IssueModel>> getIssuesByDepartment(String department) async {
    try {
      print("🏢 Getting issues for department: $department");

      final querySnapshot =
          await _firestore
              .collection('issues')
              .where('category', isEqualTo: department)
              .orderBy('createdAt', descending: true)
              .get();

      final issues =
          querySnapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();

      print("✅ Found ${issues.length} issues for $department department");
      return issues;
    } catch (e) {
      print("❌ Error getting department issues: $e");
      throw 'Failed to get department issues: $e';
    }
  }

  // Stream of department issues for real-time updates
  Stream<List<IssueModel>> getDepartmentIssuesStream(String department) {
    return _firestore
        .collection('issues')
        .where('category', isEqualTo: department)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => IssueModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get department statistics
  Future<Map<String, int>> getDepartmentStatistics(String department) async {
    try {
      final issues = await getIssuesByDepartment(department);
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      return {
        'total': issues.length,
        'pending':
            issues.where((i) => i.status.toLowerCase() == 'pending').length,
        'in_progress':
            issues.where((i) => i.status.toLowerCase() == 'in_progress').length,
        'resolved':
            issues.where((i) => i.status.toLowerCase() == 'resolved').length,
        'this_week': issues.where((i) => i.createdAt.isAfter(weekAgo)).length,
        'this_month': issues.where((i) => i.createdAt.isAfter(monthAgo)).length,
      };
    } catch (e) {
      print("❌ Error getting department statistics: $e");
      return {};
    }
  }

  // Assign issue to specific official (admin/department head function)
  Future<void> assignIssue({
    required String issueId,
    required String assignedToId,
    required String assignedToName,
    String? notes,
  }) async {
    try {
      await _firestore.collection('issues').doc(issueId).update({
        'assignedTo': assignedToId,
        'assignedToName': assignedToName,
        'assignedAt': FieldValue.serverTimestamp(),
        'assignmentNotes': notes,
        'status': 'in_progress', // Auto-set to in progress when assigned
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get issue details to send notification
      final issueDoc = await _firestore.collection('issues').doc(issueId).get();
      if (issueDoc.exists) {
        final issueData = issueDoc.data() as Map<String, dynamic>;

        // Notify the citizen about assignment
        await NotificationService().sendIssueUpdateNotification(
          userId: issueData['userId'],
          issueId: issueId,
          issueTitle: issueData['title'],
          newStatus: 'in_progress',
          adminNotes: 'Issue has been assigned to $assignedToName',
        );

        // Notify the assigned official
        await NotificationService().sendNotificationToUser(
          userId: assignedToId,
          title: '📋 New Assignment',
          body: 'You have been assigned issue: ${issueData['title']}',
          data: {
            'type': 'issue_assigned',
            'issueId': issueId,
            'priority': issueData['priority'] ?? 'medium',
          },
        );
      }

      print("✅ Issue assigned successfully");
    } catch (e) {
      print("❌ Error assigning issue: $e");
      throw 'Failed to assign issue: $e';
    }
  }

  // Get assigned issues for an official
  Future<List<IssueModel>> getAssignedIssues(String officialId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('issues')
              .where('assignedTo', isEqualTo: officialId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => IssueModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("❌ Error getting assigned issues: $e");
      throw 'Failed to get assigned issues: $e';
    }
  }

  // Bulk update issues (for department officials)
  Future<void> bulkUpdateIssues({
    required List<String> issueIds,
    String? newStatus,
    String? notes,
  }) async {
    try {
      final batch = _firestore.batch();

      for (String issueId in issueIds) {
        final issueRef = _firestore.collection('issues').doc(issueId);
        final updateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (newStatus != null) updateData['status'] = newStatus;
        if (notes != null) updateData['adminNotes'] = notes;

        batch.update(issueRef, updateData);
      }

      await batch.commit();

      // Send notifications for each updated issue
      for (String issueId in issueIds) {
        final issueDoc =
            await _firestore.collection('issues').doc(issueId).get();
        if (issueDoc.exists && newStatus != null) {
          final issueData = issueDoc.data() as Map<String, dynamic>;
          await NotificationService().sendIssueUpdateNotification(
            userId: issueData['userId'],
            issueId: issueId,
            issueTitle: issueData['title'],
            newStatus: newStatus,
            adminNotes: notes,
          );
        }
      }

      print("✅ Bulk update completed for ${issueIds.length} issues");
    } catch (e) {
      print("❌ Error in bulk update: $e");
      throw 'Failed to bulk update issues: $e';
    }
  }

  // Get issues requiring attention (high priority + pending)
  Future<List<IssueModel>> getUrgentIssues(String department) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('issues')
              .where('category', isEqualTo: department)
              .where('priority', whereIn: ['High', 'Critical'])
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => IssueModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("❌ Error getting urgent issues: $e");
      return [];
    }
  }
}
