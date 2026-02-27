"""
Demo Responses for Backup Mode
High-quality cached responses for live demos
"""

def get_demo_response(journey_id: str):
    """Get cached demo response for journey"""
    
    DEMO_RESPONSES = {
        "PRODUCT_SCAN": {
            "journey": "PRODUCT_SCAN",
            "type": "product",
            "product_name": "Bisleri 500ml Plastic Water Bottle",
            "brand": "Bisleri",
            "category": "Beverage Container",
            "sustainability_grade": "D",
            
            "carbon_lifecycle": {
                "total_grams_co2": 127,
                "breakdown": {
                    "raw_material_extraction": 45,
                    "manufacturing": 38,
                    "transportation": 22,
                    "packaging": 12,
                    "use_phase": 0,
                    "end_of_life": 10
                },
                "comparison": "= 0.5km car drive / 0.006 trees needed to offset",
                "if_recycled_co2_saved": 38,
                "if_landfilled_impact": "Takes 450 years to decompose"
            },
            
            "material_intelligence": {
                "primary_material": "PET Plastic",
                "material_code": "#1 PET",
                "recyclability_score": 85,
                "current_recycling_rate_india": "60%",
                "biodegradable": False,
                "decomposition_time_years": 450,
                "microplastic_risk": "High",
                "toxicity_level": "Safe"
            },
            
            "green_alternatives": [
                {
                    "product": "Milton Duo DLX 1000 Thermosteel Bottle",
                    "brand": "Milton",
                    "upfront_cost_inr": 450,
                    "co2_per_use_grams": 0.5,
                    "break_even_uses": 23,
                    "annual_savings_co2_kg": 4.6,
                    "annual_savings_money_inr": 1200,
                    "availability": "Amazon, Flipkart, Local stores",
                    "rating": 4.5
                }
            ],
            
            "behavioral_nudge": {
                "message": "Switching to reusable saves ₹1,200/year and 4.6kg CO₂",
                "social_proof": "2,847 EcoSnap users made this switch",
                "gamification": "Unlock 'Plastic Warrior' badge after 30 days",
                "urgency": "This bottle will take 450 years to decompose"
            },
            
            "recommendation": "Switch to Milton Thermosteel bottle. Break-even in just 23 uses (under 1 month). Annual savings: ₹1,200 + 4.6kg CO₂.",
            "confidence_score": 0.94,
            
            "edge_inference": {
                "processed_on_edge": True,
                "hardware": "AMD Ryzen™ AI NPU",
                "latency_ms": 42,
                "co2_saved_grams": 0.43 
            },
            
            "_data_sources": [
                "Open Food Facts (2.8M products)",
                "ADEME Carbon Database",
                "Material Recycling Database",
                "Green Alternatives Database"
            ]
        },
        
        "SOLAR_AUDIT": {
            "journey": "SOLAR_AUDIT",
            "type": "property_exterior",
            "product_name": "Advanced Solar Potential Analysis",
            
            "roof_3d_analysis": {
                "estimated_area_sqm": 45,
                "usable_area_sqm": 38,
                "tilt_angle_degrees": 15,
                "orientation": "South-West",
                "roof_material": "RCC",
                "structural_integrity": "Excellent",
                "load_capacity_assessment": "Can support 5kW system"
            },
            
            "solar_potential": {
                "viability_score": 92,
                "recommended_capacity_kw": 3.0,
                "estimated_annual_generation_kwh": 4560,
                "capacity_factor": 0.17
            },
            
            "financial_analysis": {
                "system_cost_inr": 150000,
                "central_subsidy_inr": 78000,
                "state_subsidy_inr": 21000,
                "net_cost_inr": 51000,
                "monthly_savings_inr": 5840,
                "payback_period_months": 8.7,
                "roi_25_years_inr": 1752000,
                "roi_percentage": 3435
            },
            
            "recommendation": "Excellent solar potential! 3kW system recommended. Total subsidy: ₹99,000. Payback in 8.7 months. 25-year savings: ₹17.5 lakhs.",
            "confidence_score": 0.91,
            
            "_data_sources": [
                "NASA POWER Satellite Data",
                "Google Solar API",
                "OpenStreetMap Buildings",
                "PM Surya Ghar Subsidy Database",
                "Maharashtra State Subsidy"
            ]
        },
        
        "ROOM_ENERGY": {
            "journey": "ROOM_ENERGY",
            "type": "room_interior",
            "product_name": "Room Energy Efficiency Analysis",
            
            "room_dimensions": {
                "estimated_area_sqm": 18,
                "estimated_volume_cubic_m": 54,
                "ceiling_height_m": 3.0
            },
            
            "appliances_detected": [
                {
                    "appliance": "Air Conditioner",
                    "quantity": 1,
                    "estimated_capacity_tons": 1.5,
                    "right_sized": False,
                    "recommended_capacity_tons": 1.0,
                    "oversizing_waste_annual_inr": 6800
                }
            ],
            
            "energy_efficiency": {
                "current_annual_consumption_kwh": 2400,
                "potential_savings_kwh": 960,
                "potential_savings_inr": 7680,
                "efficiency_grade": "C"
            },
            
            "recommendation": "AC is oversized by 50%. Right-sizing to 1.0 ton saves ₹6,800/year. Add insulation for additional ₹880/year savings.",
            "confidence_score": 0.88,
            
            "_data_sources": [
                "OpenWeatherMap Climate Data",
                "3D Room Estimation",
                "HVAC Sizing Calculator",
                "Energy Efficiency Database"
            ]
        }
    }
    
    return DEMO_RESPONSES.get(journey_id, DEMO_RESPONSES["PRODUCT_SCAN"])
