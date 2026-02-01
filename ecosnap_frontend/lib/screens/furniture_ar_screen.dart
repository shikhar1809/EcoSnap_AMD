import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FurnitureARScreen extends StatefulWidget {
  const FurnitureARScreen({super.key});

  @override
  State<FurnitureARScreen> createState() => _FurnitureARScreenState();
}

class _FurnitureARScreenState extends State<FurnitureARScreen> {
  Offset _pos = Offset(150, 300);
  double _scale = 1.0;
  
  final List<Map<String, dynamic>> _items = [
    {"name": "Bamboo Armchair", "icon": Icons.chair, "save": "₹8,000"},
    {"name": "Recycled Wood Table", "icon": Icons.table_restaurant, "save": "₹5,500"},
    {"name": "Solar Floor Lamp", "icon": Icons.light, "save": "₹2,000"},
  ];
  
  int _selectedIdx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mock Room Backdrop
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Icon(Icons.home_work_outlined, size: 300, color: Colors.white10),
            ),
          ),
          
          Positioned(
            top: 50, left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    Text("AR PREVIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text("Saves ${_items[_selectedIdx]['save']} vs. plastic", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Draggable/Resizable Item
          Positioned(
            left: _pos.dx,
            top: _pos.dy,
            child: GestureDetector(
              onPanUpdate: (details) => setState(() => _pos += details.delta),
              onScaleUpdate: (details) => setState(() => _scale = details.scale.clamp(0.5, 3.0)),
              child: Transform.scale(
                scale: _scale,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent),
                        boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 20)]
                      ),
                      child: Icon(_items[_selectedIdx]['icon'], size: 80, color: Colors.greenAccent),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Text(_items[_selectedIdx]['name'], style: TextStyle(color: Colors.white, fontSize: 10)),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Column(
              children: [
                Text("Drag to position • Pinch to resize", style: TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIdx = index),
                        child: Container(
                          width: 80,
                          margin: EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: _selectedIdx == index ? Colors.greenAccent : Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(_items[index]['icon'], color: _selectedIdx == index ? Colors.black : Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
