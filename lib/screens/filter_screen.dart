import 'package:flutter/material.dart';
import '../utils/user_details.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Basic filters
  String _selectedGender = 'Both';
  RangeValues _ageRange = const RangeValues(18, 75);
  double _distance = 35;
  bool _onlineOnly = false;

  // Looks filters
  List<String> _selectedBodyTypes = [];
  RangeValues _heightRange = const RangeValues(150, 200);

  // Background filters
  String _selectedLanguage = 'Any';
  String _selectedReligion = 'Any';
  List<String> _selectedEthnicities = [];

  // Lifestyle filters
  String _selectedRelationship = 'Any';
  String _smokingPreference = 'Any';
  String _drinkingPreference = 'Any';

  final List<String> _genderOptions = ['Male', 'Female', 'Both'];
  final List<String> _bodyTypes = ['Slim', 'Sporty', 'Curvy', 'Round', 'Supermodel', 'Average'];
  final List<String> _languages = ['Any', 'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese'];
  final List<String> _religions = ['Any', 'Christian', 'Muslim', 'Jewish', 'Hindu', 'Buddhist', 'Other'];
  final List<String> _ethnicities = ['Black', 'Brown', 'White', 'Asian', 'Mixed', 'Other'];
  final List<String> _relationships = ['Any', 'Single', 'Married', 'Divorced', 'Widowed'];
  final List<String> _smokingOptions = ['Any', 'Non-smoker', 'Smoker', 'Occasionally'];
  final List<String> _drinkingOptions = ['Any', 'Non-drinker', 'Social drinker', 'Regular drinker'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Don't load filters in initState, do it in didChangeDependencies instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load filters every time the screen is opened
    print('📱 Filter screen opened - loading saved filters...');
    _loadCurrentFilters();
    print('✅ Filter loading complete');
  }

  void _loadCurrentFilters() {
    // Load from UserDetails
    setState(() {
      // Basic filters
      _ageRange = RangeValues(
        UserDetails.filterOptionAgeMin.toDouble(),
        UserDetails.filterOptionAgeMax.toDouble(),
      );
      _distance = double.tryParse(UserDetails.filterOptionDistance) ?? 35;
      _onlineOnly = UserDetails.filterOptionIsOnline;

      // Load gender filter
      if (UserDetails.filterOptionGender == '4525') {
        _selectedGender = 'Male';
      } else if (UserDetails.filterOptionGender == '4526') {
        _selectedGender = 'Female';
      } else {
        _selectedGender = 'Both';
      }

      // Looks filters
      _selectedBodyTypes = List<String>.from(UserDetails.filterOptionBodyTypes);
      _heightRange = RangeValues(
        UserDetails.filterOptionHeightMin,
        UserDetails.filterOptionHeightMax,
      );

      // Background filters
      _selectedLanguage = UserDetails.filterOptionLanguage == 'english' ? 'English' : UserDetails.filterOptionLanguage;
      if (!_languages.contains(_selectedLanguage)) {
        _selectedLanguage = 'Any';
      }
      _selectedReligion = UserDetails.filterOptionReligion;
      _selectedEthnicities = List<String>.from(UserDetails.filterOptionEthnicities);

      // Lifestyle filters
      _selectedRelationship = UserDetails.filterOptionRelationship;
      _smokingPreference = UserDetails.filterOptionSmoking;
      _drinkingPreference = UserDetails.filterOptionDrinking;
    });

    print('🔄 Loaded current filters:');
    print('   • Gender: $_selectedGender (from ${UserDetails.filterOptionGender})');
    print('   • Age: ${_ageRange.start.round()}-${_ageRange.end.round()}');
    print('   • Distance: $_distance km');
    print('   • Online only: $_onlineOnly');
    print('   • Body types: $_selectedBodyTypes');
    print('   • Height: ${_heightRange.start.round()}-${_heightRange.end.round()} cm');
    print('   • Language: $_selectedLanguage');
    print('   • Religion: $_selectedReligion');
    print('   • Ethnicities: $_selectedEthnicities');
    print('   • Relationship: $_selectedRelationship');
    print('   • Smoking: $_smokingPreference');
    print('   • Drinking: $_drinkingPreference');
  }

  void _applyFilters() {
    // Save basic filters to UserDetails
    UserDetails.filterOptionAgeMin = _ageRange.start.round();
    UserDetails.filterOptionAgeMax = _ageRange.end.round();
    UserDetails.filterOptionDistance = _distance.round().toString();
    UserDetails.filterOptionIsOnline = _onlineOnly;

    // Convert gender selection to API format
    if (_selectedGender == 'Male') {
      UserDetails.filterOptionGender = '4525'; // Male gender code
    } else if (_selectedGender == 'Female') {
      UserDetails.filterOptionGender = '4526'; // Female gender code
    } else {
      UserDetails.filterOptionGender = '4525,4526'; // Both genders
    }

    // Save looks filters
    UserDetails.filterOptionBodyTypes = List<String>.from(_selectedBodyTypes);
    UserDetails.filterOptionHeightMin = _heightRange.start;
    UserDetails.filterOptionHeightMax = _heightRange.end;

    // Save background filters
    UserDetails.filterOptionLanguage = _selectedLanguage == 'English' ? 'english' : _selectedLanguage.toLowerCase();
    UserDetails.filterOptionReligion = _selectedReligion;
    UserDetails.filterOptionEthnicities = List<String>.from(_selectedEthnicities);

    // Save lifestyle filters
    UserDetails.filterOptionRelationship = _selectedRelationship;
    UserDetails.filterOptionSmoking = _smokingPreference;
    UserDetails.filterOptionDrinking = _drinkingPreference;

    print('🎯 Applied and saved filters:');
    print('   • Gender: $_selectedGender (API: ${UserDetails.filterOptionGender})');
    print('   • Age: ${_ageRange.start.round()}-${_ageRange.end.round()}');
    print('   • Distance: ${_distance.round()} km');
    print('   • Online only: $_onlineOnly');
    print('   • Body types: $_selectedBodyTypes');
    print('   • Height: ${_heightRange.start.round()}-${_heightRange.end.round()} cm');
    print('   • Language: $_selectedLanguage (saved as: ${UserDetails.filterOptionLanguage})');
    print('   • Religion: $_selectedReligion');
    print('   • Ethnicities: $_selectedEthnicities');
    print('   • Relationship: $_selectedRelationship');
    print('   • Smoking: $_smokingPreference');
    print('   • Drinking: $_drinkingPreference');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filters applied and saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true); // Return true to indicate filters were applied
  }

  void _resetFilters() {
    setState(() {
      // Reset UI state
      _selectedGender = 'Both';
      _ageRange = const RangeValues(18, 75);
      _distance = 35;
      _onlineOnly = false;
      _selectedBodyTypes.clear();
      _heightRange = const RangeValues(150, 200);
      _selectedLanguage = 'Any';
      _selectedReligion = 'Any';
      _selectedEthnicities.clear();
      _selectedRelationship = 'Any';
      _smokingPreference = 'Any';
      _drinkingPreference = 'Any';
    });

    // Reset UserDetails to default values
    UserDetails.filterOptionAgeMin = 18;
    UserDetails.filterOptionAgeMax = 75;
    UserDetails.filterOptionGender = "4525,4526"; // Both genders
    UserDetails.filterOptionIsOnline = false;
    UserDetails.filterOptionDistance = "35";
    UserDetails.filterOptionLanguage = "english";

    // Reset additional filter properties
    UserDetails.filterOptionBodyTypes = [];
    UserDetails.filterOptionHeightMin = 150;
    UserDetails.filterOptionHeightMax = 200;
    UserDetails.filterOptionReligion = "Any";
    UserDetails.filterOptionEthnicities = [];
    UserDetails.filterOptionRelationship = "Any";
    UserDetails.filterOptionSmoking = "Any";
    UserDetails.filterOptionDrinking = "Any";

    print('🔄 Reset all filters to default values');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All filters reset to defaults!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic'),
            Tab(text: 'Looks'),
            Tab(text: 'Background'),
            Tab(text: 'Lifestyle'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicTab(),
                _buildLooksTab(),
                _buildBackgroundTab(),
                _buildLifestyleTab(),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Gender'),
          _buildGenderSelector(),
          const SizedBox(height: 24),

          _buildSectionTitle('Age Range'),
          _buildAgeRangeSlider(),
          const SizedBox(height: 24),

          _buildSectionTitle('Distance'),
          _buildDistanceSlider(),
          const SizedBox(height: 24),

          _buildSectionTitle('Online Status'),
          _buildOnlineToggle(),
        ],
      ),
    );
  }

  Widget _buildLooksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Body Type'),
          _buildBodyTypeSelector(),
          const SizedBox(height: 24),

          _buildSectionTitle('Height Range (cm)'),
          _buildHeightRangeSlider(),
        ],
      ),
    );
  }

  Widget _buildBackgroundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Language'),
          _buildLanguageSelector(),
          const SizedBox(height: 24),

          _buildSectionTitle('Religion'),
          _buildReligionSelector(),
          const SizedBox(height: 24),

          _buildSectionTitle('Ethnicity'),
          _buildEthnicitySelector(),
        ],
      ),
    );
  }

  Widget _buildLifestyleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Relationship Status'),
          _buildRelationshipSelector(),
          const SizedBox(height: 24),

          _buildSectionTitle('Smoking'),
          _buildSmokingSelector(),
          const SizedBox(height: 24),

          _buildSectionTitle('Drinking'),
          _buildDrinkingSelector(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Wrap(
      spacing: 8,
      children: _genderOptions.map((gender) {
        return ChoiceChip(
          label: Text(gender),
          selected: _selectedGender == gender,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedGender = gender;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildAgeRangeSlider() {
    return Column(
      children: [
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 75,
          divisions: 57,
          labels: RangeLabels(
            _ageRange.start.round().toString(),
            _ageRange.end.round().toString(),
          ),
          onChanged: (values) {
            setState(() {
              _ageRange = values;
            });
          },
        ),
        Text('${_ageRange.start.round()} - ${_ageRange.end.round()} years'),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      children: [
        Slider(
          value: _distance,
          min: 1,
          max: 100,
          divisions: 99,
          label: '${_distance.round()} km',
          onChanged: (value) {
            setState(() {
              _distance = value;
            });
          },
        ),
        Text('${_distance.round()} km'),
      ],
    );
  }

  Widget _buildOnlineToggle() {
    return SwitchListTile(
      title: const Text('Show only online users'),
      value: _onlineOnly,
      onChanged: (value) {
        setState(() {
          _onlineOnly = value;
        });
      },
    );
  }

  Widget _buildBodyTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _bodyTypes.map((bodyType) {
        return FilterChip(
          label: Text(bodyType),
          selected: _selectedBodyTypes.contains(bodyType),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedBodyTypes.add(bodyType);
              } else {
                _selectedBodyTypes.remove(bodyType);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildHeightRangeSlider() {
    return Column(
      children: [
        RangeSlider(
          values: _heightRange,
          min: 140,
          max: 220,
          divisions: 80,
          labels: RangeLabels(
            '${_heightRange.start.round()} cm',
            '${_heightRange.end.round()} cm',
          ),
          onChanged: (values) {
            setState(() {
              _heightRange = values;
            });
          },
        ),
        Text('${_heightRange.start.round()} - ${_heightRange.end.round()} cm'),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage,
        isExpanded: true,
        underline: const SizedBox(),
        items: _languages.map((language) {
          return DropdownMenuItem(
            value: language,
            child: Text(language),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedLanguage = value!;
          });
        },
      ),
    );
  }

  Widget _buildReligionSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedReligion,
        isExpanded: true,
        underline: const SizedBox(),
        items: _religions.map((religion) {
          return DropdownMenuItem(
            value: religion,
            child: Text(religion),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedReligion = value!;
          });
        },
      ),
    );
  }

  Widget _buildEthnicitySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ethnicities.map((ethnicity) {
        return FilterChip(
          label: Text(ethnicity),
          selected: _selectedEthnicities.contains(ethnicity),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedEthnicities.add(ethnicity);
              } else {
                _selectedEthnicities.remove(ethnicity);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRelationshipSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedRelationship,
        isExpanded: true,
        underline: const SizedBox(),
        items: _relationships.map((relationship) {
          return DropdownMenuItem(
            value: relationship,
            child: Text(relationship),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRelationship = value!;
          });
        },
      ),
    );
  }

  Widget _buildSmokingSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _smokingPreference,
        isExpanded: true,
        underline: const SizedBox(),
        items: _smokingOptions.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _smokingPreference = value!;
          });
        },
      ),
    );
  }

  Widget _buildDrinkingSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _drinkingPreference,
        isExpanded: true,
        underline: const SizedBox(),
        items: _drinkingOptions.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _drinkingPreference = value!;
          });
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Reset Filters'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
