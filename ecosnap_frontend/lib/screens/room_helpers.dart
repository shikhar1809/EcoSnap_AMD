
  Widget _buildRoomOverviewTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text("Room Audit", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                 Text("Efficiency Scan", style: TextStyle(color: Colors.grey, fontSize: 14)),
               ]),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                 child: Text("${data['efficiency_score'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
               )
            ],
          ),
          const SizedBox(height: 24),
          _infoCard(Icons.home, "Room Rating", "${data['efficiency_score']}/100", "Based on appliances & layout"),
          const SizedBox(height: 20),
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.orange.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.orange.withOpacity(0.3)),
             ),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.lightbulb, color: Colors.orange, size: 20), SizedBox(width: 8), Text('Recommendation:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
                  const SizedBox(height: 4),
                  Text(data['recommendation'] ?? '', style: const TextStyle(color: Colors.white70)),
                ]
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomAppliancesTab(Map<String, dynamic> data) {
    final appliances = data['appliances'] as List? ?? [];
    if (appliances.isEmpty) {
      return const Center(child: Text("No high-energy appliances detected.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appliances.length,
      itemBuilder: (ctx, i) {
        final a = appliances[i];
        return Card(
           margin: const EdgeInsets.only(bottom: 12),
           color: Colors.white10,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           child: Padding(
             padding: const EdgeInsets.all(12),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                   Text(a['type'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   Text(a['efficiency_rating'] ?? '', style: const TextStyle(color: Colors.greenAccent))
                 ]),
                 const Divider(color: Colors.white24),
                 Text("Power: ${a['current_power_consumption']}", style: const TextStyle(color: Colors.grey)),
                 const SizedBox(height: 8),
                 Text("Replace with: ${a['recommended_replacement']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                 Text("Est. Savings: ${a['financial_savings_year']}/yr", style: const TextStyle(color: Colors.green)),
               ],
             ),
           ),
        );
      },
    );
  }

  Widget _buildGreenArchitectureTab(Map<String, dynamic> data) {
    final arch = data['green_architecture'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const Text("Layout & Design", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
               child: Text(arch['layout_advice'] ?? 'No advice', style: const TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 24),
            const Text("Sustainable Additions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
               child: Text(arch['sustainable_additions'] ?? 'No additions', style: const TextStyle(color: Colors.white70)),
            ),
         ],
      ),
    );
  }
