import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker;
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:universal_html/html.dart' as html;

import '../utils/user_details.dart';
import 'social_login_service.dart';

// ---------------- Sticker Model ----------------
class Sticker {
  final String id;
  final String url;
  Sticker({required this.id, required this.url});
}

// ---------------- Sticker BottomSheet ----------------
class StickersBottomSheet extends StatelessWidget {
  final List<Sticker> stickers;
  final Function(Sticker) onStickerSelected;

  const StickersBottomSheet({
    Key? key,
    required this.stickers,
    required this.onStickerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select a Sticker',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: stickers.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
              itemCount: stickers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final sticker = stickers[index];
                return GestureDetector(
                  onTap: () {
                    onStickerSelected(sticker);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        sticker.url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Failed to load sticker: ${sticker.url}');
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_neutral, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No stickers right now',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Stickers will appear here when they become available',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ---------------- Media Selection BottomSheet ----------------

class MediaSelectionBottomSheet extends StatelessWidget {
  final Function(ImageSource source) onImageSourceSelected;

  const MediaSelectionBottomSheet({
    Key? key,
    required this.onImageSourceSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CloseButton(),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Gallery Option
            _buildMediaOption(
              icon: Icons.photo_library,
              title: 'Gallery',
              subtitle: 'Choose from your photos',
              onTap: () {
                Navigator.pop(context);
                onImageSourceSelected(ImageSource.gallery);
              },
            ),

            const Divider(height: 1),

            // Camera Option
            if (!kIsWeb)
              _buildMediaOption(
                icon: Icons.camera_alt,
                title: 'Camera',
                subtitle: 'Take a new photo',
                onTap: () {
                  Navigator.pop(context);
                  onImageSourceSelected(ImageSource.camera);
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(icon, color: Colors.blue, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}


// ---------------- Chat Screen ----------------
class ChatConversationScreen extends StatefulWidget {
  final dynamic conversation;
  final VoidCallback? onMessageSent;

  const ChatConversationScreen({
    super.key,
    required this.conversation,
    this.onMessageSent,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  List<dynamic> _messages = [];
  List<Sticker> _stickers = [];
  bool _loading = true;
  bool _sending = false;
  bool _showEmojiPicker = false;
  bool _loadingStickers = true;
  FocusNode _focusNode = FocusNode();

  // Camera variables
  CameraController? _cameraController;
  bool _isCameraActive = false;
  bool _isRearCameraSelected = true;

  @override
  void initState() {
    super.initState();
    _loadStickers();
    _fetchMessages();
    _markMessagesAsRead();
    _initializeCamera();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });
  }

  // Load stickers and store in state
  Future<void> _loadStickers() async {
    setState(() {
      _loadingStickers = true;
    });

    try {
      final stickers = await _fetchStickers();
      setState(() {
        _stickers = stickers;
        _loadingStickers = false;
      });
      print('✅ Loaded ${stickers.length} stickers into state');
    } catch (e) {
      print('❌ Error loading stickers: $e');
      setState(() {
        _stickers = [];
        _loadingStickers = false;
      });
    }
  }

  // ---------------- Camera Implementation ----------------
  Future<void> _initializeCamera() async {
    if (kIsWeb) return; // Camera not supported on web

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No cameras found on device');
        return;
      }

      _cameraController = CameraController(
        cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );

      // Initialize camera
      await _cameraController!.initialize();

      // If mounted, update the UI
      if (mounted) {
        setState(() {});
      }

    } catch (e) {
      _showError('Failed to initialize camera: ${e.toString()}');
      print('Error initializing camera: $e');
    }
  }

  Future<bool> _checkPermissions() async {
    if (kIsWeb) return true; // Web handles permissions differently

    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;

    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }

    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ---------------- Fetch Messages ----------------
  Future<void> _fetchMessages() async {
    setState(() => _loading = true);

    try {
      final url =
      Uri.parse('${SocialLoginService.baseUrl}/messages/get_chat_conversations');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'to_userid': widget.conversation['user_id'].toString(),
          'limit': '50',
          'offset': '0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> messagesList = List<dynamic>.from(data['data']);
          setState(() {
            _messages = messagesList;
            _loading = false;
          });
          _scrollToBottom();
        } else {
          setState(() {
            _messages = [];
            _loading = false;
          });
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ---------------- Fetch Stickers ----------------
  Future<List<Sticker>> _fetchStickers() async {
    // Use the working endpoint from PowerShell command
    const String endpoint = 'https://backend.staralign.me/endpoint/v1/models/options/get_stickers';

    try {
      print('🎯 Fetching stickers from: $endpoint');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {'access_token': UserDetails.accessToken},
      );

      print('🎯 Response Status: ${response.statusCode}');
      print('🎯 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('🎯 Decoded Data: $data');

          if (data['code'] == 200 && data['data'] != null) {
            final List<dynamic> stickersData = List<dynamic>.from(data['data']);
            print('🎯 Found ${stickersData.length} stickers from backend');

            if (stickersData.isNotEmpty) {
              final stickers = stickersData
                  .where((stickerData) => stickerData != null &&
                  stickerData['id'] != null &&
                  stickerData['file'] != null)
                  .map((stickerData) {
                String id = stickerData['id'].toString();
                String fileUrl = stickerData['file'].toString();

                // Ensure the file URL is properly formatted
                if (fileUrl.isNotEmpty && !fileUrl.startsWith('http')) {
                  if (fileUrl.startsWith('/')) {
                    fileUrl = 'https://backend.staralign.me$fileUrl';
                  } else {
                    fileUrl = 'https://backend.staralign.me/$fileUrl';
                  }
                }

                print('🎯 Sticker ID: $id, URL: $fileUrl');

                return Sticker(
                  id: id,
                  url: fileUrl,
                );
              })
                  .toList();

              if (stickers.isNotEmpty) {
                print('✅ Successfully loaded ${stickers.length} stickers from backend');
                return stickers;
              }
            } else {
              print('🎯 Backend returned empty stickers array');
              print('🎯 No stickers available - returning empty list');
              return [];
            }
          } else {
            print('❌ Invalid response - Code: ${data['code']}, Message: ${data['message']}');
            if (data['errors'] != null) {
              print('❌ Errors: ${data['errors']}');
            }
          }
        } catch (jsonError) {
          print('❌ JSON decode error: $jsonError');
          print('❌ Response body: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized access - check access token');
        print('❌ Access token: ${UserDetails.accessToken.isNotEmpty ? "Present" : "Missing"}');
      } else {
        print('❌ HTTP ${response.statusCode} from endpoint');
        print('❌ Response: ${response.body}');
      }
    } catch (networkError) {
      print('❌ Network error: $networkError');
    }

    print('❌ Sticker endpoint failed - no stickers available');
    return [];
  }


  // ---------------- Send Text Message ----------------
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/send_text_message');
      final requestBody = {
        'access_token': UserDetails.accessToken,
        'to_userid': widget.conversation['user_id'].toString(),
        'message': message,
        'hash_id': UserDetails.accessToken,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          _messageController.clear();
          setState(() {
            _messages.add({
              'from': int.parse(UserDetails.userId.toString()),
              'to': widget.conversation['user_id'],
              'text': message,
              'media': '',
              'sticker': '',
              'seen': 0,
              'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              'message_type': 'text',
              'type': 'sent',
            });
          });
          _scrollToBottom();
          if (widget.onMessageSent != null) widget.onMessageSent!();
        } else {
          _showError(data['message']?.toString() ?? 'Failed to send message');
        }
      } else {
        _showError('Server error ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: Check your connection');
    } finally {
      setState(() => _sending = false);
    }
  }

  // ---------------- Premium Check Methods ----------------
  // Check if user has premium access
  bool _isPremiumUser() {
    print('isPro value: ${UserDetails.isPro}');
    print('isPro type: ${UserDetails.isPro.runtimeType}');
    return UserDetails.isPro == "1";
  }



  // Show dialog when premium is required
  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text('Premium Feature'),
            ],
          ),
          content: const Text(
            'Sending photos, videos and files is a premium feature. Upgrade to premium to unlock media sharing and many more features!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToUpgrade();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }

  // Navigate to upgrade screen
  void _navigateToUpgrade() {
    // You can implement navigation to your premium upgrade screen here
    Navigator.pushNamed(context, '/upgrade-premium');
  }

  // ---------------- Media Selection ----------------
  void _showMediaSelectionSheet() {
    if (!_isPremiumUser()) {
      _showPremiumRequiredDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MediaSelectionBottomSheet(
        onImageSourceSelected: (source) {
          if (source == ImageSource.camera) {
            _openCamera();
          } else {
            _pickImageFromGallery();
          }
        },
      ),
    );
  }


  // ---------------- Gallery Implementation ----------------
  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _sending = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await _sendImageMessageWeb(bytes, image.name);
        } else {
          await _sendImageMessage(File(image.path));
        }
      } else {
        setState(() => _sending = false);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showError('Failed to pick image. Please try again.');
      setState(() => _sending = false);
    }
  }

  // ---------------- Camera Implementation ----------------
  Future<void> _openCamera() async {
    if (kIsWeb) {
      _openWebCamera();
      return;
    }

    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      _showError('Camera permission denied');
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initializeCamera();
    }

    setState(() {
      _isCameraActive = true;
    });

    // Show camera preview
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCameraDialog(),
    );
  }

  Widget _buildCameraDialog() {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Camera Preview
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: _cameraController != null && _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

          // Top Controls
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isCameraActive = false;
                    });
                  },
                ),

                // Flash Toggle
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white, size: 30),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Capture Button
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Camera Switch Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    try {
      if (_cameraController!.value.flashMode == FlashMode.off) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      } else {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
      setState(() {});
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameraController == null) return;

    try {
      setState(() {
        _isRearCameraSelected = !_isRearCameraSelected;
      });

      final cameras = await availableCameras();
      final newCamera = cameras.firstWhere(
            (camera) => camera.lensDirection ==
            (_isRearCameraSelected ? CameraLensDirection.back : CameraLensDirection.front),
      );

      await _cameraController!.dispose();
      _cameraController = CameraController(newCamera, ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();

      Navigator.pop(context);
      setState(() {
        _isCameraActive = false;
      });

      // Show preview before sending
      await _showImagePreview(File(image.path));
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  // ---------------- Web Camera Implementation ----------------
  Future<void> _openWebCamera() async {
    try {
      print('📷 [_openWebCamera] Starting web camera access...');

      final html.InputElement input = html.InputElement(type: 'file');
      input.accept = 'image/*';
      input.setAttribute('capture', 'camera');

      input.click();

      input.onChange.listen((e) {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();

          reader.onLoadEnd.listen((e) {
            if (reader.result != null) {
              final List<int> bytes = List<int>.from(reader.result as List<int>);
              _sendImageMessageWeb(bytes, file.name);
            }
          });

          reader.readAsArrayBuffer(file);
        }
      });
    } catch (e) {
      print('Error opening web camera: $e');
      _showError('Failed to access camera. Please check browser permissions.');
    }
  }

  // ---------------- Image Preview ----------------
  Future<void> _showImagePreview(File imageFile) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Image Preview
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.7,
              child: PhotoView(
                imageProvider: FileImage(imageFile),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
            ),

            // Top Controls
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.pop(context);
                      _sendImageMessage(imageFile);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Video Implementation ----------------
  Future<void> _pickVideo() async {
    try {
      setState(() => _sending = true);

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        if (kIsWeb) {
          final bytes = await video.readAsBytes();
          await _sendVideoMessageWeb(bytes, video.name);
        } else {
          await _sendVideoMessage(File(video.path));
        }
      } else {
        setState(() => _sending = false);
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
      setState(() => _sending = false);
    }
  }

  // ---------------- Send Sticker Message ----------------
  Future<void> _sendStickerMessage(Sticker sticker) async {
    if (_sending) return;

    setState(() => _sending = true);

    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/send_sticker_message');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'to_userid': widget.conversation['user_id'].toString(),
          'sticker_id': sticker.id,
          'hash_id': UserDetails.accessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          setState(() {
            _messages.add({
              'from': int.parse(UserDetails.userId.toString()),
              'to': widget.conversation['user_id'],
              'text': '',
              'media': '',
              'sticker': sticker.url,
              'seen': 0,
              'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              'message_type': 'sticker',
              'type': 'sent',
            });
          });
          _scrollToBottom();
          if (widget.onMessageSent != null) widget.onMessageSent!();
        } else {
          _showError(data['message']?.toString() ?? 'Failed to send sticker');
        }
      } else {
        _showError('Server error ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to send sticker: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  // ---------------- Send Image Message (Mobile) ----------------
  Future<void> _sendImageMessage(File imageFile) async {
    try {
      // First add a temporary message with loading state
      final tempMessage = {
        'from': int.parse(UserDetails.userId.toString()),
        'to': widget.conversation['user_id'],
        'text': '',
        'media': '',
        'sticker': '',
        'seen': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'message_type': 'media',
        'type': 'sent',
        'isLoading': true,  // Add loading state
        'localPath': imageFile.path  // Store local path for preview
      };

      setState(() {
        _messages.add(tempMessage);
      });
      _scrollToBottom();

      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/send_media_message');

      var request = http.MultipartRequest('POST', url);
      request.fields['access_token'] = UserDetails.accessToken;
      request.fields['to_userid'] = widget.conversation['user_id'].toString();
      request.fields['hash_id'] = UserDetails.accessToken;

      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          // Find and update the temporary message
          setState(() {
            final index = _messages.lastIndexWhere((m) =>
            m['isLoading'] == true &&
                m['localPath'] == imageFile.path
            );
            if (index != -1) {
              _messages[index] = {
                'from': int.parse(UserDetails.userId.toString()),
                'to': widget.conversation['user_id'],
                'text': '',
                'media': data['data']?['media'] ?? '',
                'sticker': '',
                'seen': 0,
                'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                'message_type': 'media',
                'type': 'sent',
                'isLoading': false
              };
            }
          });
          if (widget.onMessageSent != null) widget.onMessageSent!();
        } else {
          _showError(data['message']?.toString() ?? 'Failed to send image');
        }
      } else {
        _showError('Server error ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to send image: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  // ---------------- Send Image Message (Web) ----------------
  Future<void> _sendImageMessageWeb(List<int> bytes, String filename) async {
    try {
      print('🔹 Starting _sendImageMessageWeb...');
      print('➡️ API URL: ${SocialLoginService.baseUrl}/messages/send_media_message');
      print('📸 Filename: $filename | Bytes length: ${bytes.length}');
      print('👤 Sending to user ID: ${widget.conversation['user_id']}');
      print('🔑 Access token: ${UserDetails.accessToken}');

      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/send_media_message');
      var request = http.MultipartRequest('POST', url);

      // Add form fields
      request.fields['access_token'] = UserDetails.accessToken;
      request.fields['to_userid'] = widget.conversation['user_id'].toString();
      request.fields['hash_id'] = UserDetails.accessToken;

      // Attach the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'media_file',
          bytes,
          filename: filename,
        ),
      );

      print('🧾 Request prepared with fields: ${request.fields}');
      print('🖼️ Files count: ${request.files.length}');

      // Send request
      final streamedResponse = await request.send();
      print('📡 Request sent. Waiting for response...');

      final response = await http.Response.fromStream(streamedResponse);
      print('✅ Response received. Status: ${response.statusCode}');
      print('🧠 Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Decoded JSON: $data');

        // ⚡ Some APIs return "code" instead of "status" — handle both
        final status = data['status'] ?? data['code'];

        if (status == 200) {
          print('✅ Image message sent successfully.');

          // 🧩 Wrap list update and scroll in one build cycle
          setState(() {
            _messages.add({
              'from': int.parse(UserDetails.userId.toString()),
              'to': widget.conversation['user_id'],
              'text': '',
              'media': data['data']?['media'] ?? '',
              'sticker': '',
              'seen': 0,
              'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              'message_type': 'media',
              'type': 'sent',
            });
          });

          // 🧭 Scroll to bottom *after* frame is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          // Notify parent if needed
          if (widget.onMessageSent != null) widget.onMessageSent!();
        } else {
          print('⚠️ Server returned non-200 status: ${data['message']}');
          _showError(data['message']?.toString() ?? 'Failed to send image');
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        _showError('Server error ${response.statusCode}');
      }
    } catch (e, stack) {
      print('💥 Exception in _sendImageMessageWeb: $e');
      print('🧩 Stack trace: $stack');
      _showError('Failed to send image: $e');
    } finally {
      print('🏁 _sendImageMessageWeb completed.');
      setState(() => _sending = false);
    }
  }


  // ---------------- Send Video Message (Mobile) ----------------
  Future<void> _sendVideoMessage(File videoFile) async {
    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/send_media_message');

      var request = http.MultipartRequest('POST', url);
      request.fields['access_token'] = UserDetails.accessToken;
      request.fields['to_userid'] = widget.conversation['user_id'].toString();
      request.fields['hash_id'] = UserDetails.accessToken;

      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          videoFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          setState(() {
            _messages.add({
              'from': int.parse(UserDetails.userId.toString()),
              'to': widget.conversation['user_id'],
              'text': '',
              'media': data['data']?['media'] ?? '',
              'sticker': '',
              'seen': 0,
              'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              'message_type': 'video',
              'type': 'sent',
            });
          });
          _scrollToBottom();
          if (widget.onMessageSent != null) widget.onMessageSent!();
        } else {
          _showError(data['message']?.toString() ?? 'Failed to send video');
        }
      } else {
        _showError('Server error ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to send video: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  // ---------------- Send Video Message (Web) ----------------
  Future<void> _sendVideoMessageWeb(List<int> bytes, String filename) async {
    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/send_media_message');

      var request = http.MultipartRequest('POST', url);
      request.fields['access_token'] = UserDetails.accessToken;
      request.fields['to_userid'] = widget.conversation['user_id'].toString();
      request.fields['hash_id'] = UserDetails.accessToken;

      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          setState(() {
            _messages.add({
              'from': int.parse(UserDetails.userId.toString()),
              'to': widget.conversation['user_id'],
              'text': '',
              'media': data['data']?['media'] ?? '',
              'sticker': '',
              'seen': 0,
              'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              'message_type': 'video',
              'type': 'sent',
            });
          });
          _scrollToBottom();
          if (widget.onMessageSent != null) widget.onMessageSent!();
        } else {
          _showError(data['message']?.toString() ?? 'Failed to send video');
        }
      } else {
        _showError('Server error ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to send video: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  // ---------------- Mark Messages Read ----------------
  Future<void> _markMessagesAsRead() async {
    try {
      final url =
      Uri.parse('${SocialLoginService.baseUrl}/messages/mark_all_messages_as_read');
      await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'access_token': UserDetails.accessToken},
      );
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------- Build UI ----------------
  @override
  Widget build(BuildContext context) {
    final username = widget.conversation['username'] ?? 'Unknown User';
    final avatar = widget.conversation['avatar'] ?? '';
    final lastSeenSeconds = widget.conversation['last_seen'] is int
        ? widget.conversation['last_seen']
        : int.tryParse(widget.conversation['last_seen']?.toString() ?? '0');
    final lastSeenText = lastSeenSeconds != null && lastSeenSeconds > 0
        ? _formatLastSeen(lastSeenSeconds)
        : 'Offline';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    lastSeenText,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ---------------- Last Seen ----------------
  String _formatLastSeen(int timestamp) {
    final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = DateTime.now().difference(lastSeenTime);

    if (diff.inDays >= 365) return 'Last seen ${diff.inDays ~/ 365} year(s) ago';
    if (diff.inDays >= 30) return 'Last seen ${diff.inDays ~/ 30} month(s) ago';
    if (diff.inDays >= 7) return 'Last seen ${diff.inDays ~/ 7} week(s) ago';
    if (diff.inDays > 0) return 'Last seen ${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return 'Last seen ${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return 'Last seen ${diff.inMinutes} minute(s) ago';
    return 'Online';
  }

  // ---------------- Empty State ----------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message) {
    final currentUserId = int.parse(UserDetails.userId.toString());
    final messageFromId = message['from'] is int
        ? message['from']
        : int.parse(message['from']?.toString() ?? '0');
    final isMe = messageFromId == currentUserId;

    final text = message['text']?.toString() ?? '';
    final media = message['media']?.toString() ?? '';
    final sticker = message['sticker']?.toString() ?? '';
    final messageType = message['message_type']?.toString() ?? 'text';
    final timestamp = _formatTimestamp(message['created_at']);
    final isLoading = message['isLoading'] == true;
    final localPath = message['localPath']?.toString();

    // 🧠 Fix: Ensure correct absolute URLs for media & stickers
    final baseUrl = SocialLoginService.baseUrl;
    final mediaUrl = media.isNotEmpty
        ? (media.startsWith('http') ? media : '$baseUrl/$media')
        : '';
    final stickerUrl = sticker.isNotEmpty
        ? (sticker.startsWith('http') ? sticker : '$baseUrl/$sticker')
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (messageType == 'text' && text.isNotEmpty)
                    Text(
                      text.replaceAll('<br>', '\n'),
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),

                  if (messageType == 'media')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isLoading && localPath != null
                          ? Stack(
                        children: [
                          // Show local image while uploading
                          Image.file(
                            File(localPath),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            width: 200,
                            height: 200,
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ],
                      )
                          : mediaUrl.isNotEmpty
                          ? Image.network(
                        mediaUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                          : Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
                    ),

                  if (messageType == 'video' && mediaUrl.isNotEmpty)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                mediaUrl,
                                width: 200,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 200,
                                      height: 150,
                                      color: Colors.grey,
                                      child: const Icon(Icons.videocam, size: 50),
                                    ),
                              ),
                              const Positioned.fill(
                                child: Center(
                                  child: Icon(Icons.play_circle_fill,
                                      color: Colors.white, size: 40),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Video',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),

                  if (messageType == 'sticker' && stickerUrl.isNotEmpty)
                    Image.network(
                      stickerUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                    ),

                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timestamp,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['seen'] != null && message['seen'] != 0
                              ? Icons.done_all
                              : Icons.done,
                          size: 16,
                          color: message['seen'] != null && message['seen'] != 0
                              ? Colors.blue
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: UserDetails.avatar.isNotEmpty
                  ? NetworkImage(UserDetails.avatar)
                  : null,
              child: UserDetails.avatar.isEmpty
                  ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- Message Input with Emoji & Sticker ----------------
  Widget _buildMessageInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Media Attachment Button
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _showMediaSelectionSheet,
                    ),
                    if (!_isPremiumUser())
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Write your message',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined,
                            color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                            if (_showEmojiPicker) {
                              _focusNode.unfocus();
                            } else {
                              FocusScope.of(context).requestFocus(_focusNode);
                            }
                          });
                        },
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.card_giftcard,
                                color: Colors.grey),
                            onPressed: () async {
                              // Show loading indicator if stickers are still loading
                              if (_loadingStickers) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                                // Wait for stickers to load
                                while (_loadingStickers) {
                                  await Future.delayed(const Duration(milliseconds: 100));
                                }
                                Navigator.pop(context); // Hide loading indicator
                              }

                              // Show stickers bottom sheet
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => StickersBottomSheet(
                                  stickers: _stickers,
                                  onStickerSelected: (sticker) {
                                    _sendStickerMessage(sticker);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (text) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _sending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _sending ? null : () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: emoji_picker.EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _messageController.text += emoji.emoji;
                _messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _messageController.text.length),
                );
              },
              config: emoji_picker.Config(
                columns: 8,
                emojiSizeMax: 32 *
                    (defaultTargetPlatform == TargetPlatform.iOS ? 1.3 : 1.0),
                verticalSpacing: 0,
                horizontalSpacing: 0,
                initCategory: emoji_picker.Category.RECENT,
                bgColor: Colors.white,
                indicatorColor: Theme.of(context).primaryColor,
                iconColor: Colors.grey,
                iconColorSelected: Theme.of(context).primaryColor,
                backspaceColor: Colors.red,
              ),
            ),
          ),
      ],
    );
  }


  // ---------------- Format Timestamp ----------------
  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown';
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.tryParse(timestamp) ??
            (timestamp.length <= 10
                ? DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000)
                : DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
      } else if (timestamp is int) {
        dateTime = timestamp.toString().length <= 10
            ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
            : DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return 'Unknown';
      }
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }
}
