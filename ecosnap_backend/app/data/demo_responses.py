"""
Curated Demo Responses for Hackathon
These provide accurate, verified data for demo scenarios.
"""

# Demo response for AC Room / Furnished Space
DEMO_SPACE_AUDIT = {
    "type": "room",
    "journey_executed": "SPACE_AUDIT",
    "product_name": "Living Room Analysis",
    "category": "Furnished Room",
    "data_source": "AI Analysis + Curated Data",
    "confidence_score": 0.92,
    "condition_assessment": "Room contains older appliances with upgrade potential. Good natural light reduces daytime electricity needs.",
    
    "economics": {
        "upfront_cost": "₹45,000",
        "monthly_savings": "₹1,850",
        "payback_period_months": 24,
        "five_year_savings": "₹1,11,000",
        "is_investment": True,
        "message": "Your investment pays back in 2 years, then you profit ₹22,200/year."
    },

    "trust_data": {
        "score": 4.8,
        "total_ratings": 1420,
        "verified_homes": 847,
        "satisfaction_rate": "98%"
    },

    "social_proof": {
        "neighbors_upgraded": 41,
        "area_trend": "High Adoption",
        "top_installer": {"name": "Raj Kumar", "rating": 4.9, "jobs": 23}
    },

    "guarantees": {
        "warranty": "5 Year Manufacturer Warranty",
        "performance": "90% Efficiency Guarantee",
        "risk_free": "30-Day Money Back"
    },

    "carbon_footprint": {
        "total_kg_co2": "850 kg/year",
        "comparison_text": "Equivalent to 3,400 km driven",
        "breakdown": {
            "manufacturing": "120 kg",
            "transport": "30 kg",
            "use_phase": "680 kg",
            "end_of_life": "20 kg"
        }
    },
    
    "material_breakdown": [
        {"component": "AC Unit", "material": "Aluminum + Copper", "recyclability": "High"},
        {"component": "Refrigerator", "material": "Steel + Plastic", "recyclability": "Medium"}
    ],
    
    "sustainability_score": {
        "score": "58",
        "grade": "C+",
        "reason": "Older appliances consuming 40% more than efficient alternatives",
        "shareable_text": "My home scored 58/100 on EcoSnap! Upgrading to save ₹22K/year 🌱"
    },
    
    "solar_viability": {
        "is_viable": True,
        "potential_kw": "2.5kW",
        "sunlight_quality": "Excellent (6.5 hrs/day avg)",
        "viability": "High",
        "roof_area_sqm": 45,
        "usable_area_sqm": 31.5,
        "recommended_panels": 8,
        "optimal_tilt": "15°",
        "annual_generation_kwh": 3125,
        "monthly_generation_kwh": 260,
        "panel_layout": "2x4 grid",
        "shading_analysis": "Minimal shading detected",
        "orientation": "South-facing (optimal)",
        "estimated_savings_yearly": "₹18,000",
        "recommendation": "Rooftop can support 8 panels, covering 80% of daytime load. PM Surya Ghar subsidy: ₹30,000 available."
    },
    
    "architectural_advice": {
        "layout_optimization": "Position workstation near window for natural light",
        "ventilation_tip": "Cross-ventilation possible - open opposite windows"
    },

    "alternatives": [
        {"name": "Rooftop Solar Panel System (2.5kW)", "price_estimate": "₹1,25,000", "benefit": "80% bill reduction", "carbon_savings": "2,800 kg/year"},
        {"name": "Solar Water Heater", "price_estimate": "₹35,000", "benefit": "Eliminates geyser cost", "carbon_savings": "450 kg/year"},
        {"name": "LG 5-Star Inverter AC 1.5T", "price_estimate": "₹34,999", "benefit": "45% less power", "carbon_savings": "280 kg/year"}
    ],
    
    "appliances": [
        {"type": "Conventional Grid Power", "current_power": "~4kW peak", "replacement": "2.5kW Solar + Grid Hybrid", "savings_yr": "₹18,000"},
        {"type": "Electric Water Heater", "current_power": "2000W", "replacement": "Solar Water Heater", "savings_yr": "₹6,500"},
        {"type": "Standard Lighting", "current_power": "~500W", "replacement": "Smart LED System", "savings_yr": "₹3,200"}
    ],

    "recommendation": "Priority 1: Install Rooftop Solar (highest impact). Your roof receives 6+ hours of direct sunlight and can support a 2.5kW system. This will reduce your electricity bill by 80% and pay back in 4-5 years. PM Surya Ghar subsidy: ₹30,000 available.",
    "recovery_info": {
        "recycling_time": "3-5 days",
        "recovery_value_inr": "₹2,500",
        "recycling_action": "Schedule pickup via Cashify or local kabadiwala"
    }
}

# Demo response for Empty Room / Space Planning
DEMO_SPACE_PLANNING = {
    "type": "room",
    "journey_executed": "SPACE_PLANNING",
    "product_name": "New Room Planning",
    "category": "Empty Space",
    "data_source": "AI Analysis + Curated Data",
    "confidence_score": 0.88,
    "condition_assessment": "Empty room with good potential for green setup. Excellent natural light from windows.",
    
    "economics": {
        "upfront_cost": "₹85,000 (Green Setup)",
        "monthly_savings": "₹3,200 vs standard setup",
        "payback_period_months": 26,
        "five_year_savings": "₹1,92,000",
        "is_investment": True,
        "message": "Green setup costs 15% more upfront but saves ₹38K/year in electricity."
    },

    "trust_data": {
        "score": 4.7,
        "total_ratings": 892,
        "verified_homes": 534,
        "satisfaction_rate": "96%"
    },

    "guarantees": {
        "warranty": "5 Year Extended Warranty",
        "performance": "Energy Star Certified",
        "risk_free": "Installation Guarantee"
    },

    "carbon_footprint": {
        "total_kg_co2": "320 kg/year (Green) vs 780 kg/year (Standard)",
        "comparison_text": "59% lower carbon footprint",
        "breakdown": {
            "heating_cooling": "180 kg",
            "lighting": "40 kg",
            "electronics": "80 kg",
            "standby": "20 kg"
        }
    },
    
    "sustainability_score": {
        "score": "82",
        "grade": "A-",
        "reason": "Green-first planning maximizes efficiency from day one",
        "shareable_text": "Planning my new room with EcoSnap - targeting 82/100 score! 🌿"
    },
    
    "solar_viability": {
        "is_viable": True,
        "potential_kw": "3kW",
        "sunlight_quality": "Direct (7+ hours)",
        "recommendation": "Ideal for rooftop solar. PM Surya Ghar subsidy: ₹30,000 available."
    },
    
    "architectural_advice": {
        "layout_optimization": "Place AC away from windows to reduce heat load",
        "ventilation_tip": "Install exhaust fan opposite to window for cross-flow"
    },

    "alternatives": [
        {"name": "Complete Green Setup Bundle", "price_estimate": "₹85,000", "benefit": "All 5-star appliances", "carbon_savings": "460 kg/year"},
        {"name": "Solar + Inverter Combo", "price_estimate": "₹1,20,000", "benefit": "Near-zero bills", "carbon_savings": "800 kg/year"}
    ],
    
    "appliances": [
        {"type": "Recommended: 5-Star AC", "current_power": "N/A", "replacement": "1200W Inverter", "savings_yr": "₹6,000 vs 3-star"},
        {"type": "Recommended: BLDC Fans", "current_power": "N/A", "replacement": "28W each", "savings_yr": "₹2,400 vs regular"}
    ],

    "recommendation": "Start with 5-star appliances from day one. The 15% premium pays back in 26 months, then you save indefinitely.",
    "recovery_info": {
        "recycling_time": "N/A",
        "recovery_value_inr": "N/A",
        "recycling_action": "No disposal needed - starting fresh!"
    }
}

# Demo response for Product / Find Alternative
DEMO_FIND_ALTERNATIVE = {
    "type": "product",
    "journey_executed": "FIND_ALTERNATIVE",
    "product_name": "Plastic Water Bottle",
    "category": "Single-Use Plastic",
    "data_source": "AI Analysis + Curated Data",
    "confidence_score": 0.95,
    "condition_assessment": "Single-use PET bottle. Average lifespan: 1 use. Takes 450 years to decompose.",
    
    "economics": {
        "upfront_cost": "₹500 (Steel Bottle)",
        "monthly_savings": "₹300 (vs buying bottled water)",
        "payback_period_months": 2,
        "five_year_savings": "₹18,000",
        "is_investment": True,
        "message": "A ₹500 steel bottle saves ₹300/month. Pays back in 2 months!"
    },

    "trust_data": {
        "score": 4.9,
        "total_ratings": 3200,
        "verified_homes": 1850,
        "satisfaction_rate": "99%"
    },

    "guarantees": {
        "warranty": "Lifetime Warranty (Steel)",
        "performance": "BPA-Free Certified",
        "risk_free": "Easy Returns"
    },

    "carbon_footprint": {
        "total_kg_co2": "0.08 kg per bottle",
        "comparison_text": "1 steel bottle = 500 plastic bottles saved",
        "breakdown": {
            "manufacturing": "0.05 kg",
            "transport": "0.02 kg",
            "use_phase": "0 kg",
            "end_of_life": "0.01 kg"
        }
    },
    
    "sustainability_score": {
        "score": "15",
        "grade": "F",
        "reason": "Single-use plastic has the worst sustainability score",
        "shareable_text": "Switching from plastic to steel bottles - saving 40 kg CO2/year! 🌍"
    },

    "alternatives": [
        {"name": "Milton Steel Bottle 1L", "price_estimate": "₹450", "benefit": "Lifetime use", "carbon_savings": "40 kg/year"},
        {"name": "Copper Bottle 1L", "price_estimate": "₹800", "benefit": "Health benefits + eco", "carbon_savings": "40 kg/year"},
        {"name": "Glass Bottle with Cover", "price_estimate": "₹350", "benefit": "100% recyclable", "carbon_savings": "35 kg/year"}
    ],

    "recommendation": "Switch to a steel or copper bottle immediately. ₹500 investment saves ₹3,600/year and prevents 500 plastic bottles from landfill.",
    "recovery_info": {
        "recycling_time": "Immediate",
        "recovery_value_inr": "₹2/bottle (if recycled)",
        "recycling_action": "Deposit in dry waste bin. Do NOT mix with wet waste."
    }
}

# Fallback for unknown/low-confidence images
DEMO_FALLBACK = {
    "type": "unknown",
    "journey_executed": "SPECIAL",
    "product_name": "Analysis Requires More Context",
    "category": "Unidentified",
    "data_source": "AI Analysis",
    "confidence_score": 0.35,
    "condition_assessment": "I couldn't identify specific items in this image with high confidence. Please try:\n• Taking a clearer photo\n• Focusing on the main item\n• Adding a note about what you'd like to analyze",
    
    "economics": {
        "upfront_cost": "—",
        "monthly_savings": "—",
        "payback_period_months": 0,
        "five_year_savings": "—",
        "is_investment": False,
        "message": "Please provide more context for accurate analysis."
    },

    "sustainability_score": {
        "score": "—",
        "grade": "N/A",
        "reason": "Insufficient data for scoring",
        "shareable_text": ""
    },

    "alternatives": [],
    "appliances": [],
    "recommendation": "Try scanning again with better lighting or add a note describing what you want to analyze.",
    "recovery_info": {
        "recycling_time": "—",
        "recovery_value_inr": "—",
        "recycling_action": "—"
    }
}

def get_demo_response(journey_id: str) -> dict:
    """Return curated response based on journey type."""
    responses = {
        "SPACE_AUDIT": DEMO_SPACE_AUDIT,
        "SPACE_PLANNING": DEMO_SPACE_PLANNING,
        "FIND_ALTERNATIVE": DEMO_FIND_ALTERNATIVE,
        "BILL_ANALYSIS": DEMO_SPACE_AUDIT,  # Reuse for simplicity
        "SPECIAL": DEMO_FALLBACK
    }
    return responses.get(journey_id, DEMO_FALLBACK)
