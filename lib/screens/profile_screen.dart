// lib/screens/edit_profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  MyUserInfo? dataUser;
  final ImagePicker _picker = ImagePicker();
  List<MediaFile> mediaList = List.generate(6, (_) => MediaFile());
  int _numImage = 0;

  // Basic controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController hobbyController = TextEditingController();
  final TextEditingController musicController = TextEditingController();
  final TextEditingController movieController = TextEditingController();
  final TextEditingController dishController = TextEditingController();
  final TextEditingController songController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController snapchatController = TextEditingController();
  final TextEditingController tiktokController = TextEditingController();

  DateTime? selectedBirthday;

  // Dropdown selections (store the label/text)
  String? selectedGender;
  String? selectedRelationship;
  String? selectedWorkStatus;
  String? selectedEducation;
  String? selectedReligion;
  String? selectedSmoke;
  String? selectedDrink;
  String? selectedPets;
  String? selectedBody;
  String? selectedEthnicity;
  String? selectedChildren;
  String? selectedLookingFor;
  String? selectedTravel;

  // Hardcoded option lists
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> relationshipOptions = ['Single', 'In a relationship', 'Married'];
  final List<String> workStatusOptions = ['Student', 'Employed', 'Unemployed', 'Self-employed', 'Freelancer'];
  final List<String> educationOptions = ['High School', 'Bachelor', 'Master', 'PhD', 'Other'];
  final List<String> religionOptions = ['None', 'Christian', 'Muslim', 'Hindu', 'Buddhist', 'Other'];
  final List<String> smokeOptions = ['No', 'Occasionally', 'Yes'];
  final List<String> drinkOptions = ['No', 'Occasionally', 'Yes'];
  final List<String> petsOptions = ['None', 'Cat', 'Dog', 'Other'];
  final List<String> bodyOptions = ['Slim', 'Average', 'Athletic', 'Heavy'];
  final List<String> ethnicityOptions = ['Asian', 'Black', 'White', 'Hispanic', 'Other'];
  final List<String> childrenOptions = ['None', 'One', 'Two', 'More than Two'];
  final List<String> lookingForOptions = ['Friendship', 'Dating', 'Long-term', 'Marriage'];
  final List<String> travelOptions = ['No preference', 'Occasionally', 'Often'];

  // mapping label -> numeric id (safe to send both label and id)
  final Map<String, String> relationshipMap = {
    'Single': '1',
    'In a relationship': '2',
    'Married': '3',
  };

  final Map<String, String> workStatusMap = {
    'Student': '1',
    'Employed': '2',
    'Unemployed': '3',
    'Self-employed': '4',
    'Freelancer': '5',
  };

  final Map<String, String> educationMap = {
    'High School': '1',
    'Bachelor': '2',
    'Master': '3',
    'PhD': '4',
    'Other': '5',
  };

  final Map<String, String> religionMap = {
    'None': '0',
    'Christian': '1',
    'Muslim': '2',
    'Hindu': '3',
    'Buddhist': '4',
    'Other': '5',
  };

  final Map<String, String> smokeMap = {'No': '0', 'Occasionally': '1', 'Yes': '2'};
  final Map<String, String> drinkMap = {'No': '0', 'Occasionally': '1', 'Yes': '2'};
  final Map<String, String> petsMap = {'None': '0', 'Cat': '1', 'Dog': '2', 'Other': '3'};
  final Map<String, String> bodyMap = {'Slim': '1', 'Average': '2', 'Athletic': '3', 'Heavy': '4'};
  final Map<String, String> ethnicityMap = {'Asian': '1', 'Black': '2', 'White': '3', 'Hispanic': '4', 'Other': '5'};
  final Map<String, String> childrenMap = {'None': '0', 'One': '1', 'Two': '2', 'More than Two': '3'};
  final Map<String, String> lookingForMap = {'Friendship': '1', 'Dating': '2', 'Long-term': '3', 'Marriage': '4'};
  final Map<String, String> travelMap = {'No preference': '0', 'Occasionally': '1', 'Often': '2'};

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  String? _getLabelFromValue(String value, List<String> options, Map<String, String> labelToIdMap) {
    if (options.contains(value)) {
      return value;
    }
    final reverseMap = {for (var entry in labelToIdMap.entries) entry.value: entry.key};
    return reverseMap[value] ?? null;
  }

  // ------------------- LOAD USER INFO -------------------
  void _loadUserInfo() {
    // Fill MyUserInfo from UserDetails
    dataUser = MyUserInfo(
      firstName: UserDetails.firstName,
      lastName: UserDetails.lastName,
      hobby: UserDetails.hobby,
      music: UserDetails.music,
      movie: UserDetails.movie,
      city: UserDetails.city,
      country: UserDetails.country_txt,
      birthday: UserDetails.birthday,
      gender: UserDetails.genderTxt,
      relationship: UserDetails.relationship,
      workStatus: UserDetails.workStatus,
      education: UserDetails.education,
      mediaFiles: UserDetails.mediaFiles,
      about: UserDetails.fullName, // if you have a dedicated about, use it
    );

    // Prefill media
    mediaList = List.generate(
      6,
          (i) => i < dataUser!.mediaFiles.length ? dataUser!.mediaFiles[i] : MediaFile(),
    );

    // Text controllers
    firstNameController.text = UserDetails.firstName;
    lastNameController.text = UserDetails.lastName;
    aboutController.text = UserDetails.about;
    hobbyController.text = UserDetails.hobby;
    musicController.text = UserDetails.music;
    movieController.text = UserDetails.movie;
    dishController.text = UserDetails.dish;
    songController.text = UserDetails.song;
    cityController.text = UserDetails.city;
    countryController.text = UserDetails.country_txt;

    websiteController.text = UserDetails.website;
    facebookController.text = UserDetails.facebook;
    instagramController.text = UserDetails.instagram;
    twitterController.text = UserDetails.twitter;
    linkedinController.text = UserDetails.linkedin;
    snapchatController.text = UserDetails.okru;
    tiktokController.text = UserDetails.mailru;

    // Birthday
    selectedBirthday = (UserDetails.birthday.isNotEmpty)
        ? DateTime.tryParse(UserDetails.birthday)
        : null;

    // Dropdowns: try label first, fallback to mapping numeric id
    selectedGender = UserDetails.gender.isNotEmpty ? UserDetails.gender : null;
    selectedRelationship = _getLabelFromValue(UserDetails.relationship, relationshipOptions, relationshipMap);
    selectedWorkStatus = _getLabelFromValue(UserDetails.workStatus, workStatusOptions, workStatusMap);
    selectedEducation = _getLabelFromValue(UserDetails.education, educationOptions, educationMap);
    selectedReligion = _getLabelFromValue(UserDetails.religion, religionOptions, religionMap);
    selectedSmoke = _getLabelFromValue(UserDetails.smoke, smokeOptions, smokeMap);
    selectedDrink = _getLabelFromValue(UserDetails.drink, drinkOptions, drinkMap);
    selectedPets = _getLabelFromValue(UserDetails.pets, petsOptions, petsMap);
    selectedBody = _getLabelFromValue(UserDetails.body, bodyOptions, bodyMap);
    selectedEthnicity = _getLabelFromValue(UserDetails.ethnicity, ethnicityOptions, ethnicityMap);
    selectedChildren = _getLabelFromValue(UserDetails.children, childrenOptions, childrenMap);
    selectedLookingFor = _getLabelFromValue(UserDetails.lookingFor, lookingForOptions, lookingForMap);
    selectedTravel = _getLabelFromValue(UserDetails.travel, travelOptions, travelMap);

    setState(() {});
  }

// ------------------- UPDATE PROFILE -------------------
  Future<void> _updateProfile() async {
    final body = _buildPostBody();

    try {
      final response = await http.post(
        Uri.parse('https://backend.staralign.me/endpoint/v1/models/users/update_profile'),
        // ✅ Use form-urlencoded for compatibility with your backend's successful curl test
        body: body, // http.post automatically converts Map<String, String> to x-www-form-urlencoded
      );
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['code'] == 200) {
        Fluttertoast.showToast(msg: 'Profile updated successfully!');

        // Update UserDetails local model
        UserDetails.firstName = firstNameController.text.trim();
        UserDetails.lastName = lastNameController.text.trim();
        UserDetails.about = aboutController.text.trim();
        UserDetails.hobby = hobbyController.text.trim();
        UserDetails.music = musicController.text.trim();
        UserDetails.movie = movieController.text.trim();
        UserDetails.city = cityController.text.trim();
        UserDetails.country_txt = countryController.text.trim();
        UserDetails.birthday = selectedBirthday?.toIso8601String() ?? '';
        UserDetails.genderTxt = selectedGender ?? '';
        UserDetails.relationship = selectedRelationship ?? '';
        UserDetails.workStatus = selectedWorkStatus ?? '';
        UserDetails.education = selectedEducation ?? '';
        UserDetails.religion = selectedReligion ?? '';
        UserDetails.smoke = selectedSmoke ?? '';
        UserDetails.drink = selectedDrink ?? '';
        UserDetails.pets = selectedPets ?? '';
        UserDetails.body = selectedBody ?? '';
        UserDetails.ethnicity = selectedEthnicity ?? '';
        UserDetails.children = selectedChildren ?? '';
        UserDetails.travel = selectedTravel ?? '';
        UserDetails.lookingFor = selectedLookingFor ?? '';
        UserDetails.dish = dishController.text.trim();
        UserDetails.song = songController.text.trim();

        UserDetails.website = websiteController.text.trim();
        UserDetails.facebook = facebookController.text.trim();
        UserDetails.instagram = instagramController.text.trim();
        UserDetails.twitter = twitterController.text.trim();
        UserDetails.linkedin = linkedinController.text.trim();
        UserDetails.okru = snapchatController.text.trim();
        UserDetails.mailru = tiktokController.text.trim();

        setState(() {});
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? 'Profile update failed.');
      }
    } catch (e) {
      print('Update error: $e');
      Fluttertoast.showToast(msg: 'Error updating profile: $e');
    }
  }

  // Image pick dialog
  Future<void> _openDialog(int numImage) async {
    _numImage = numImage;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.choose_file_type),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(AppLocalizations.of(context)!.image_gallery), onTap: () => Navigator.pop(context, 'ImageGallery')),
            ListTile(title: Text(AppLocalizations.of(context)!.camera), onTap: () => Navigator.pop(context, 'Camera')),
            ListTile(title: Text(AppLocalizations.of(context)!.video_gallery), onTap: () => Navigator.pop(context, 'VideoGallery')),
            ListTile(title: Text(AppLocalizations.of(context)!.video_camera), onTap: () => Navigator.pop(context, 'VideoCamera')),
          ],
        ),
      ),
    );
    if (result != null) _onSelection(result);
  }

  void _onSelection(String type) async {
    XFile? file;
    switch (type) {
      case 'ImageGallery':
        file = await _picker.pickImage(source: ImageSource.gallery);
        break;
      case 'Camera':
        file = await _picker.pickImage(source: ImageSource.camera);
        break;
      case 'VideoGallery':
        file = await _picker.pickVideo(source: ImageSource.gallery);
        break;
      case 'VideoCamera':
        file = await _picker.pickVideo(source: ImageSource.camera);
        break;
    }
    if (file != null) await _sendFile(file.path, type.contains('Video'));
  }

  Future<void> _sendFile(String path, bool isVideo) async {
    setState(() {
      mediaList[_numImage - 1] = MediaFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        full: path,
        avater: path,
        isVideo: isVideo ? '1' : '0',
      );
    });

    Fluttertoast.showToast(msg: '${isVideo ? "Video" : "Image"} added successfully');

    await _uploadMedia(File(path), isVideo);
  }

  Future<void> _uploadMedia(File file, bool isVideo) async {
    final uri = Uri.parse('https://backend.staralign.me/endpoint/v1/models/media/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['access_token'] = UserDetails.accessToken;

    request.files.add(await http.MultipartFile.fromPath(
      isVideo ? 'video_file' : 'image_file',
      file.path,
    ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Media uploaded successfully!');
      } else {
        Fluttertoast.showToast(msg: 'Media upload failed.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Upload error: $e');
    }
  }

  // Build the POST body with all fields (both numeric id and *_txt where appropriate)
  // lib/screens/edit_profile_screen.dart

// ... (inside _EditProfileScreenState class)

// Build the POST body with all fields (only ID for categorized fields)
  Map<String, String> _buildPostBody() {
    final Map<String, String> body = {
      'access_token': UserDetails.accessToken,
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'about': aboutController.text.trim(),
      'hobby': hobbyController.text.trim(),
      'music': musicController.text.trim(),
      'movie': movieController.text.trim(),
      'dish': dishController.text.trim(),
      'song': songController.text.trim(),
      'city': cityController.text.trim(),
      'country': countryController.text.trim(), // Send country text, assuming backend handles
      'website': websiteController.text.trim(),
      'facebook': facebookController.text.trim(),
      'instagram': instagramController.text.trim(),
      'twitter': twitterController.text.trim(),
      'linkedin': linkedinController.text.trim(),
      'okru': snapchatController.text.trim(),
      'mailru': tiktokController.text.trim(),
    };

    // birthday
    body['birthday'] = selectedBirthday?.toIso8601String() ?? '';

    // gender (Gender may be sent as text 'Male/Female/Other' or numeric '1/2/3'.
    // Since the API responded with an error for 'relationship_txt', we'll only send 'gender'.)
    if (selectedGender != null && selectedGender!.isNotEmpty) {
      // Assuming the API expects the text for 'gender', based on your maps/logic
      body['gender'] = selectedGender!;
    }

    // relationship
    if (selectedRelationship != null) {
      body['relationship'] = relationshipMap[selectedRelationship!] ?? '';
      // ❌ Removed body['relationship_txt']
    }

    // work status
    if (selectedWorkStatus != null) {
      body['work_status'] = workStatusMap[selectedWorkStatus!] ?? '';
      // ❌ Removed body['work_status_txt']
    }

    // education
    if (selectedEducation != null) {
      body['education'] = educationMap[selectedEducation!] ?? '';
      // ❌ Removed body['education_txt']
    }

    // religion
    if (selectedReligion != null) {
      body['religion'] = religionMap[selectedReligion!] ?? '';
      // ❌ Removed body['religion_txt']
    }

    // smoke & drink
    if (selectedSmoke != null) {
      body['smoke'] = smokeMap[selectedSmoke!] ?? '';
      // ❌ Removed body['smoke_txt']
    }
    if (selectedDrink != null) {
      body['drink'] = drinkMap[selectedDrink!] ?? '';
      // ❌ Removed body['drink_txt']
    }

    // pets
    if (selectedPets != null) {
      body['pets'] = petsMap[selectedPets!] ?? '';
      // ❌ Removed body['pets_txt']
    }

    // body, ethnicity, children, travel, looking_for
    if (selectedBody != null) {
      body['body'] = bodyMap[selectedBody!] ?? '';
      // ❌ Removed body['body_txt']
    }
    if (selectedEthnicity != null) {
      body['ethnicity'] = ethnicityMap[selectedEthnicity!] ?? '';
      // ❌ Removed body['ethnicity_txt']
    }
    if (selectedChildren != null) {
      body['children'] = childrenMap[selectedChildren!] ?? '';
      // ❌ Removed body['children_txt']
    }
    if (selectedTravel != null) {
      body['travel'] = travelMap[selectedTravel!] ?? '';
      // ❌ Removed body['travel_txt']
    }
    if (selectedLookingFor != null) {
      // The key that caused the error: body['looking_for'] = ...
      body['show_me_to'] = lookingForMap[selectedLookingFor!] ?? '';
    }

    return body;
  }
  void _deletePhoto(int index) {
    setState(() {
      mediaList[index] = MediaFile();
    });
    Fluttertoast.showToast(msg: 'Deleted successfully');
  }

  Future<void> _pickBirthday() async {
    DateTime initialDate = selectedBirthday ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedBirthday = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dataUser == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.title_edit_profile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PERSONAL INFO
            const SectionTitle('Personal Info'),
            Row(
              children: [
                Expanded(child: _buildTextField('First Name', firstNameController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Last Name', lastNameController)),
              ],
            ),
            _buildTextField('About', aboutController, maxLines: 3),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.birthday),
                    subtitle: Text(selectedBirthday != null
                        ? "${selectedBirthday!.day}/${selectedBirthday!.month}/${selectedBirthday!.year}"
                        : 'Select birthday'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickBirthday,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('Gender', genderOptions, selectedGender, (val) => setState(() => selectedGender = val))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTextField('City', cityController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Country', countryController)),
              ],
            ),
            const SizedBox(height: 12),

            // LIFESTYLE & BELIEFS
            const SectionTitle('Lifestyle & Beliefs'),
            _buildDropdown('Religion', religionOptions, selectedReligion, (val) => setState(() => selectedReligion = val)),
            Row(
              children: [
                Expanded(child: _buildDropdown('Smoke', smokeOptions, selectedSmoke, (val) => setState(() => selectedSmoke = val))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('Drink', drinkOptions, selectedDrink, (val) => setState(() => selectedDrink = val))),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildDropdown('Pets', petsOptions, selectedPets, (val) => setState(() => selectedPets = val))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('Children', childrenOptions, selectedChildren, (val) => setState(() => selectedChildren = val))),
              ],
            ),
            _buildDropdown('Body Type', bodyOptions, selectedBody, (val) => setState(() => selectedBody = val)),
            _buildDropdown('Ethnicity', ethnicityOptions, selectedEthnicity, (val) => setState(() => selectedEthnicity = val)),
            const SizedBox(height: 12),

            // PREFERENCES
            const SectionTitle('Preferences'),
            _buildDropdown('Relationship Status', relationshipOptions, selectedRelationship, (val) => setState(() => selectedRelationship = val)),
            Row(
              children: [
                Expanded(child: _buildDropdown('Work Status', workStatusOptions, selectedWorkStatus, (val) => setState(() => selectedWorkStatus = val))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('Education', educationOptions, selectedEducation, (val) => setState(() => selectedEducation = val))),
              ],
            ),
            _buildDropdown('Looking For', lookingForOptions, selectedLookingFor, (val) => setState(() => selectedLookingFor = val)),
            _buildDropdown('Travel', travelOptions, selectedTravel, (val) => setState(() => selectedTravel = val)),
            const SizedBox(height: 12),

            // INTERESTS & FAVORITES
            const SectionTitle('Interests & Favorites'),
            _buildTextField('Hobby', hobbyController),
            Row(
              children: [
                Expanded(child: _buildTextField('Favorite Song', songController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Favorite Movie', movieController)),
              ],
            ),
            _buildTextField('Favorite Food / Dish', dishController),
            _buildTextField('Favorite Music (genre/artist)', musicController),
            const SizedBox(height: 12),

            // SOCIAL LINKS
            const SectionTitle('Social Links'),
            Row(
              children: [
                Expanded(child: _buildTextField('Website', websiteController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Facebook', facebookController)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField('Instagram', instagramController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Twitter', twitterController)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField('LinkedIn', linkedinController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Snapchat / Ok.ru', snapchatController)),
              ],
            ),
            _buildTextField('TikTok / Mail.ru', tiktokController),
            const SizedBox(height: 12),

            // MEDIA (existing grid)
            const SectionTitle('Media'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              children: List.generate(6, (i) {
                final media = mediaList[i];
                return GestureDetector(
                  onTap: () => media.id == null ? _openDialog(i + 1) : null,
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: media.id == null
                            ? const Center(child: Icon(Icons.add_a_photo, size: 40))
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: media.full ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      if (media.id != null)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _deletePhoto(i),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(AppLocalizations.of(context)!.save_profile, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // helpers
  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? selected, ValueChanged<String?> onChanged) {
    // If selected text doesn't match options, show null
    final value = (selected != null && options.contains(selected)) ? selected : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            hint: Text(AppLocalizations.of(context)!.select_label(label)),
          ),
        ),
      ),
    );
  }
}

// small section title widget
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}

