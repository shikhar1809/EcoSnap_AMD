import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InstallerMarketplaceScreen extends StatefulWidget {
  final double? systemKw;
  
  const InstallerMarketplaceScreen({super.key, this.systemKw});

  @override
  State<InstallerMarketplaceScreen> createState() => _InstallerMarketplaceScreenState();
}

class _InstallerMarketplaceScreenState extends State<InstallerMarketplaceScreen> {
  // Demo installer data
  final List<Map<String, dynamic>> _installers = [
    {
      'name': 'SunPower Solutions',
      'rating': 4.9,
      'reviews': 247,
      'projects': 156,
      'distance': '2.3 km',
      'response_time': '< 2 hours',
      'certifications': ['MNRE Approved', 'ISO 9001'],
      'quote': 95000,
      'warranty': '25 years',
      'installation_time': '3-5 days',
    },
    {
      'name': 'Green Energy India',
      'rating': 4.7,
      'reviews': 189,
      'projects': 203,
      'distance': '4.1 km',
      'response_time': '< 4 hours',
      'certifications': ['MNRE Approved'],
      'quote': 105000,
      'warranty': '20 years',
      'installation_time': '5-7 days',
    },
    {
      'name': 'EcoWatt Systems',
      'rating': 4.8,
      'reviews': 312,
      'projects': 278,
      'distance': '5.8 km',
      'response_time': '< 3 hours',
      'certifications': ['MNRE Approved', 'ISO 9001', 'BIS Certified'],
      'quote': 92000,
      'warranty': '25 years',
      'installation_time': '2-4 days',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Verified Installers', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.greenAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Installers near you',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'For ${widget.systemKw ?? 2.5}kW solar system',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_installers.length} Found',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          
          // Installer list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _installers.length,
              itemBuilder: (context, index) {
                final installer = _installers[index];
                return _buildInstallerCard(installer, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallerCard(Map<String, dynamic> installer, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: index == 0 ? Colors.greenAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: index == 0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.greenAccent, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.solar_power, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            installer['name'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        if (index == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'BEST MATCH',
                              style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${installer['rating']} (${installer['reviews']} reviews)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          installer['distance'],
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats
          Row(
            children: [
              _statBadge(Icons.check_circle, '${installer['projects']} projects'),
              const SizedBox(width: 12),
              _statBadge(Icons.schedule, installer['response_time']),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Certifications
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (installer['certifications'] as List<String>).map((cert) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Text(
                  cert,
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                ),
              );
            }).toList(),
          ),
          
          const Divider(color: Colors.white10, height: 24),
          
          // Quote details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quote', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(
                    '₹${installer['quote']}',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${installer['warranty']} warranty',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Install: ${installer['installation_time']}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${installer['name']}...')),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showBookingDialog(installer);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Book Site Visit', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _statBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.greenAccent, size: 12),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  void _showBookingDialog(Map<String, dynamic> installer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f3a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Book Site Visit',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule a free site visit with ${installer['name']}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _bookingField('Name', 'Enter your name'),
            const SizedBox(height: 12),
            _bookingField('Phone', 'Enter your phone number'),
            const SizedBox(height: 12),
            _bookingField('Preferred Date', 'Select date'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Site visit booked with ${installer['name']}!'),
                  backgroundColor: Colors.greenAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  Widget _bookingField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
