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
      print("🚀 IssueService: Starting issue submission");
      print("📁 DEBUG: Received category parameter: '$category'");

      final user = currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      // Validate category - make sure it's one of the expected values
      final validCategories = [
        'Road and Transportation',
        'Water and Sewage',
        'Electricity and Power',
        'Public Safety',
        'Environmental Issues',
      ];

      if (!validCategories.contains(category)) {
        print("❌ Invalid category received: '$category'");
        print("✅ Valid categories: $validCategories");
        throw 'Invalid category: $category';
      }

      print("✅ Category validation passed: '$category'");

      // Upload images first
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        print("📸 Uploading ${images.length} images...");
        imageUrls = await _uploadImages(images);
        print("✅ Images uploaded successfully");
      }

      // Create issue data directly as Map to avoid any IssueModel conversion issues
      final issueData = {
        'title': title,
        'description': description,
        'category': category, // Directly assign the category parameter
        'status': 'pending',
        'priority': priority,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userName': user.displayName ?? 'Anonymous',
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print("📋 Final issue data being submitted:");
      print("   Title: ${issueData['title']}");
      print("   Category: ${issueData['category']}");
      print("   Priority: ${issueData['priority']}");
      print("   Status: ${issueData['status']}");
      print("   User: ${issueData['userName']} (${issueData['userId']})");

      // Save directly to Firestore with explicit data
      DocumentReference docRef = await _firestore
          .collection('issues')
          .add(issueData);

      print("✅ Issue submitted successfully with ID: ${docRef.id}");

      // Verify the data was saved correctly
      DocumentSnapshot savedDoc = await docRef.get();
      if (savedDoc.exists) {
        final savedData = savedDoc.data() as Map<String, dynamic>;
        print("🔍 Verification - Saved category: '${savedData['category']}'");

        if (savedData['category'] != category) {
          print("❌ WARNING: Category mismatch!");
          print("   Expected: '$category'");
          print("   Saved: '${savedData['category']}'");
        } else {
          print("✅ Category saved correctly: '${savedData['category']}'");
        }
      }

      return docRef.id;
    } catch (e) {
      print("❌ Error submitting issue: $e");
      throw 'Failed to submit issue: $e';
    }
  }

  // Also add this method to check if there are any Firestore rules issues:
  Future<void> testCategorySubmission() async {
    try {
      print("🧪 Testing category submission...");

      final testCategories = [
        'Road and Transportation',
        'Water and Sewage',
        'Electricity and Power',
        'Public Safety',
        'Environmental Issues',
      ];

      for (String category in testCategories) {
        print("Testing category: '$category'");

        // Create a test document
        final testData = {
          'title': 'Test Issue',
          'category': category,
          'status': 'pending',
          'userId': currentUser?.uid ?? 'test-user',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Try to add it
        DocumentReference docRef = await _firestore
            .collection('test_issues')
            .add(testData);

        // Verify it was saved correctly
        DocumentSnapshot doc = await docRef.get();
        if (doc.exists) {
          final savedData = doc.data() as Map<String, dynamic>;
          print("✅ Category '$category' saved as: '${savedData['category']}'");

          // Clean up test document
          await docRef.delete();
        }
      }

      print("✅ Category test completed");
    } catch (e) {
      print("❌ Category test failed: $e");
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
        print("❌ No authenticated user found");
        throw 'User not authenticated';
      }

      print("📋 Getting issues for user: ${user.email} (${user.uid})");

      // Test Firestore connection first
      try {
        await FirebaseFirestore.instance.enableNetwork();
        print("✅ Firestore network enabled");
      } catch (e) {
        print("⚠️ Firestore network issue: $e");
      }

      // 🔁 Force fresh data from the server
      final querySnapshot = await FirebaseFirestore.instance
          .collection('issues')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server)) // <-- key change
          .timeout(const Duration(seconds: 30));

      print(
        "✅ Query executed successfully, found ${querySnapshot.docs.length} documents",
      );

      final issues =
          querySnapshot.docs.map((doc) {
            print("📄 Processing document: ${doc.id}");
            try {
              return IssueModel.fromFirestore(doc);
            } catch (e) {
              print("❌ Error parsing document ${doc.id}: $e");
              print("📄 Document data: ${doc.data()}");
              rethrow;
            }
          }).toList();

      print("✅ Found ${issues.length} issues for user");
      return issues;
    } on FirebaseException catch (e) {
      print("🔥 Firebase Exception: ${e.code} - ${e.message}");
      if (e.code == 'permission-denied') {
        throw 'Permission denied. Please check your account permissions.';
      } else if (e.code == 'unavailable') {
        throw 'Service unavailable. Please check your internet connection.';
      } else {
        throw 'Database error: ${e.message}';
      }
    } catch (e) {
      print("❌ General error getting user issues: $e");
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
  // Add these methods to your existing issue_service.dart

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
