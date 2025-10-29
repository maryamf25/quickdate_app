import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const gradientColors = [
      Color(0xFFE40997),
      Color(0xFFF20489),
      Color(0xFFDC0C9F),
      Color(0xFFCA12AF),
      Color(0xFFBA16C1),
      Color(0xFFAA1BCD),
      Color(0xFF9921E0),
      Color(0xFF8926F0),
    ];

    const shockingPink = Color(0xFFFF41BD);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Increase Popularity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🌈 Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Popularity",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Your current reach is very low",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Right Speedometer Icon (multicolor style)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.cyan,
                          Colors.blue,
                          Colors.purple,
                          Colors.red,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.speed,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🌸 Offer Cards Section
            _buildOfferCard(
              context,
              title: "Promote your profile",
              subtitle: "Get more visits for 5 minutes",
              credits: "254 Credits",
              icon: Icons.trending_up,
              buttonLabel: "Get x10 Visits",
            ),
            _buildOfferCard(
              context,
              title: "Instant Boost",
              subtitle: "Show your profile to top users",
              credits: "499 Credits",
              icon: Icons.flash_on,
              buttonLabel: "Boost Now",
            ),
            _buildOfferCard(
              context,
              title: "Super Visibility",
              subtitle: "Stay highlighted for 15 minutes",
              credits: "999 Credits",
              icon: Icons.visibility,
              buttonLabel: "Get x20 Visits",
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 💎 Reusable Offer Card
  Widget _buildOfferCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String credits,
        required IconData icon,
        required String buttonLabel,
      }) {
    const shockingPink = Color(0xFFFF41BD);
    const lightPink = Color(0xFFFFE6F3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: shockingPink, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: lightPink,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: shockingPink, size: 26),
              ),
              const SizedBox(width: 16),

              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Credits Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: shockingPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  credits,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: shockingPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // TODO: Handle purchase / boost
              },
              child: Text(
                buttonLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
