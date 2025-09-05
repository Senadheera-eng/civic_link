// services/issue_service.dart (CORRECTED IMPORTS VERSION)
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/issue_model.dart';
import 'notification_service.dart';

class IssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  User? get currentUser => _auth.currentUser;

  // Get all issues (for map view) with improved error handling
  Future<List<IssueModel>> getAllIssues() async {
    try {
      print("🗺️ Getting all issues for map view");

      final querySnapshot = await _firestore
          .collection('issues')
          .orderBy('createdAt', descending: true)
          .limit(200) // Increased limit but still manageable
          .get(
            const GetOptions(source: Source.serverAndCache),
          ) // Use cache when possible
          .timeout(const Duration(seconds: 15)); // Add timeout

      final issues = <IssueModel>[];

      for (var doc in querySnapshot.docs) {
        try {
          final issue = IssueModel.fromFirestore(doc);

          // Validate coordinates before adding
          if (_isValidCoordinate(issue.latitude) &&
              _isValidCoordinate(issue.longitude)) {
            issues.add(issue);
          } else {
            print(
              "⚠️ Skipping issue ${doc.id} with invalid coordinates: lat=${issue.latitude}, lng=${issue.longitude}",
            );
          }
        } catch (e) {
          print("⚠️ Error parsing issue document ${doc.id}: $e");
          continue; // Skip invalid documents
        }
      }

      print("✅ Found ${issues.length} valid issues for map");
      return issues;
    } on FirebaseException catch (e) {
      print("❌ Firebase error getting all issues: ${e.code} - ${e.message}");
      if (e.code == 'permission-denied') {
        throw 'Access denied. Please check your account permissions.';
      } else if (e.code == 'unavailable') {
        throw 'Service unavailable. Please check your internet connection.';
      } else {
        throw 'Database error: ${e.message}';
      }
    } catch (e) {
      print("❌ General error getting all issues: $e");
      throw 'Failed to get issues: $e';
    }
  }

  // Helper method to validate coordinates
  bool _isValidCoordinate(double coordinate) {
    return coordinate.isFinite &&
        coordinate != 0.0 &&
        coordinate.abs() <= 180.0;
  }

  // Get user's issues with better error handling
  Future<List<IssueModel>> getUserIssues() async {
    final user = currentUser;
    if (user == null) {
      print("❌ No authenticated user");
      throw 'Please sign in to view your issues';
    }

    try {
      print("👤 Getting issues for user: ${user.uid}");

      final querySnapshot = await _firestore
          .collection('issues')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 10));

      final issues =
          querySnapshot.docs
              .map((doc) {
                try {
                  return IssueModel.fromFirestore(doc);
                } catch (e) {
                  print("⚠️ Error parsing user issue ${doc.id}: $e");
                  return null;
                }
              })
              .where((issue) => issue != null)
              .cast<IssueModel>()
              .toList();

      print("✅ Found ${issues.length} user issues");
      return issues;
    } on FirebaseException catch (e) {
      print("❌ Firebase error getting user issues: ${e.code} - ${e.message}");
      if (e.code == 'permission-denied') {
        throw 'Access denied. Please check your account permissions.';
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

  // Get issue by ID with error handling
  Future<IssueModel?> getIssueById(String issueId) async {
    try {
      final doc = await _firestore
          .collection('issues')
          .doc(issueId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists) {
        return IssueModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("❌ Error getting issue by ID: $e");
      return null;
    }
  }

  // Submit issue with better error handling
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
    final user = currentUser;
    if (user == null) {
      throw 'Please sign in to submit issues';
    }

    // Validate coordinates
    if (!_isValidCoordinate(latitude) || !_isValidCoordinate(longitude)) {
      throw 'Invalid location coordinates. Please try again.';
    }

    try {
      print("📝 Submitting issue for user: ${user.uid}");

      // Upload images with progress tracking
      final imageUrls = <String>[];
      for (int i = 0; i < images.length; i++) {
        try {
          final imageUrl = await _uploadImage(images[i], user.uid);
          imageUrls.add(imageUrl);
          print("📸 Uploaded image ${i + 1}/${images.length}");
        } catch (e) {
          print("⚠️ Failed to upload image ${i + 1}: $e");
          // Continue with other images instead of failing completely
        }
      }

      // Create issue document
      final issueData = {
        'userId': user.uid,
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'priority': priority,
        'status': 'pending',
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'adminNotes': null,
      };

      final docRef = await _firestore
          .collection('issues')
          .add(issueData)
          .timeout(const Duration(seconds: 15));

      print("✅ Issue submitted successfully: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Error submitting issue: $e");
      throw 'Failed to submit issue: $e';
    }
  }

  // Upload image with retry logic
  Future<String> _uploadImage(XFile image, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final ref = _storage.ref().child('issues/$userId/$fileName');

      final uploadTask = ref.putFile(File(image.path));

      // Wait for upload to complete with timeout
      final snapshot = await uploadTask.timeout(const Duration(minutes: 2));

      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw 'Upload failed with state: ${snapshot.state}';
      }
    } catch (e) {
      print("❌ Error uploading image: $e");
      rethrow;
    }
  }

  // Get current location with improved error handling
  Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable them in settings.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in app settings.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Add timeout
      );

      return position;
    } catch (e) {
      print("❌ Error getting current location: $e");
      rethrow;
    }
  }

  // Get address from coordinates with error handling
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      if (!_isValidCoordinate(latitude) || !_isValidCoordinate(longitude)) {
        return 'Unknown location';
      }

      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = <String>[];

        if (place.street?.isNotEmpty == true) addressParts.add(place.street!);
        if (place.locality?.isNotEmpty == true)
          addressParts.add(place.locality!);
        if (place.administrativeArea?.isNotEmpty == true)
          addressParts.add(place.administrativeArea!);

        return addressParts.isNotEmpty
            ? addressParts.join(', ')
            : 'Unknown location';
      }

      return 'Unknown location';
    } catch (e) {
      print("⚠️ Error getting address: $e");
      return 'Unknown location';
    }
  }

  // Pick image from camera with error handling
  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      print("❌ Error picking image from camera: $e");
      throw 'Camera error: $e';
    }
  }

  // Pick image from gallery with error handling
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      print("❌ Error picking image from gallery: $e");
      throw 'Gallery error: $e';
    }
  }

  // Update issue status with error handling
  Future<void> updateIssueStatus({
    required String issueId,
    required String newStatus,
    String? adminNotes,
  }) async {
    try {
      // Update issue in Firestore
      await _firestore
          .collection('issues')
          .doc(issueId)
          .update({
            'status': newStatus,
            'adminNotes': adminNotes,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));

      // Get issue details to find the user
      final issueDoc = await _firestore.collection('issues').doc(issueId).get();
      if (issueDoc.exists) {
        final issueData = issueDoc.data() as Map<String, dynamic>;
        final userId = issueData['userId'];
        final issueTitle = issueData['title'];

        // Send notification to user
        try {
          await NotificationService().sendIssueUpdateNotification(
            userId: userId,
            issueId: issueId,
            issueTitle: issueTitle,
            newStatus: newStatus,
            adminNotes: adminNotes,
          );
        } catch (e) {
          print("⚠️ Failed to send notification: $e");
          // Don't fail the whole operation if notification fails
        }
      }

      print("✅ Issue status updated successfully");
    } catch (e) {
      print("❌ Error updating issue status: $e");
      throw 'Failed to update issue status: $e';
    }
  }

  // Stream of user's issues for real-time updates with error handling
  Stream<List<IssueModel>> getUserIssuesStream() {
    final user = currentUser;
    if (user == null) {
      print("❌ No user for stream");
      return Stream.value([]);
    }

    print("🔄 Setting up issues stream for user: ${user.uid}");

    return _firestore
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
                  print("⚠️ Error parsing streamed issue ${doc.id}: $e");
                  return null;
                }
              })
              .where((issue) => issue != null)
              .cast<IssueModel>()
              .toList();
        });
  }

  // Delete issue with error handling
  Future<void> deleteIssue(String issueId) async {
    final user = currentUser;
    if (user == null) {
      throw 'Please sign in to delete issues';
    }

    try {
      // First, get the issue to check ownership and get image URLs
      final issueDoc = await _firestore.collection('issues').doc(issueId).get();
      if (!issueDoc.exists) {
        throw 'Issue not found';
      }

      final issueData = issueDoc.data() as Map<String, dynamic>;
      if (issueData['userId'] != user.uid) {
        throw 'You can only delete your own issues';
      }

      // Delete associated images
      final imageUrls = List<String>.from(issueData['imageUrls'] ?? []);
      for (String imageUrl in imageUrls) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print("⚠️ Failed to delete image: $e");
          // Continue with other images
        }
      }

      // Delete the issue document
      await _firestore.collection('issues').doc(issueId).delete();

      print("✅ Issue deleted successfully: $issueId");
    } catch (e) {
      print("❌ Error deleting issue: $e");
      throw 'Failed to delete issue: $e';
    }
  }
}
