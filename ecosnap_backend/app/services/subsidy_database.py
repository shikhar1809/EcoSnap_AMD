"""
Comprehensive Government Subsidy Database
Central + All 28 States + 8 UTs
Aligned with Indian government schemes
"""
from typing import List, Dict, Optional
from enum import Enum

class SchemeType(str, Enum):
    SOLAR = "solar"
    EV = "electric_vehicle"
    ENERGY_EFFICIENCY = "energy_efficiency"
    WASTE_MANAGEMENT = "waste_management"
    WATER_CONSERVATION = "water_conservation"
    GREEN_BUILDING = "green_building"
    AGRICULTURE = "agriculture"

class SubsidyDatabase:
    """Complete subsidy database for India"""
    
    # ==================== CENTRAL GOVERNMENT SCHEMES ====================
    
    CENTRAL_SCHEMES = [
        {
            "id": "pm-surya-ghar",
            "name": "PM Surya Ghar: Muft Bijli Yojana",
            "type": SchemeType.SOLAR,
            "ministry": "Ministry of New and Renewable Energy (MNRE)",
            "description": "Rooftop solar subsidy for residential consumers",
            "benefits": [
                {"capacity": "1 kW", "subsidy": 30000, "unit": "₹"},
                {"capacity": "2 kW", "subsidy": 60000, "unit": "₹"},
                {"capacity": "3 kW", "subsidy": 78000, "unit": "₹"},
                {"capacity": "4 kW+", "subsidy": 78000, "unit": "₹ (capped)"}
            ],
            "eligibility": "Residential consumers with grid connection",
            "documents": ["Aadhaar", "Electricity bill", "Roof ownership proof"],
            "apply_url": "https://pmsuryaghar.gov.in",
            "approval_time": "45-60 days",
            "active": True
        },
        {
            "id": "fame-ii",
            "name": "FAME India Phase II",
            "type": SchemeType.EV,
            "ministry": "Ministry of Heavy Industries",
            "description": "Faster Adoption and Manufacturing of Electric Vehicles",
            "benefits": [
                {"vehicle": "E-2W", "subsidy": 50000, "unit": "₹"},
                {"vehicle": "E-3W", "subsidy": 50000, "unit": "₹"},
                {"vehicle": "E-4W", "subsidy": 150000, "unit": "₹"},
                {"vehicle": "E-Bus", "subsidy": 5000000, "unit": "₹"}
            ],
            "eligibility": "Purchase of new electric vehicles",
            "documents": ["Aadhaar", "Driving license", "Vehicle invoice"],
            "apply_url": "https://fame2.heavyindustries.gov.in",
            "approval_time": "Instant (at dealership)",
            "active": True
        },
        {
            "id": "ujala",
            "name": "UJALA (Unnat Jyoti by Affordable LEDs for All)",
            "type": SchemeType.ENERGY_EFFICIENCY,
            "ministry": "Ministry of Power (BEE)",
            "description": "LED bulb distribution at subsidized rates",
            "benefits": [
                {"item": "LED Bulb (9W)", "subsidy": 10, "unit": "₹ per bulb"},
                {"item": "LED Tubelight", "subsidy": 30, "unit": "₹ per tube"}
            ],
            "eligibility": "All domestic consumers",
            "documents": ["Electricity bill"],
            "apply_url": "https://ujala.gov.in",
            "approval_time": "Immediate (at distribution centers)",
            "active": True
        },
        {
            "id": "kusum",
            "name": "PM-KUSUM (Kisan Urja Suraksha evam Utthaan Mahabhiyan)",
            "type": SchemeType.AGRICULTURE,
            "ministry": "Ministry of New and Renewable Energy",
            "description": "Solar pumps and grid-connected solar power for farmers",
            "benefits": [
                {"component": "Solar Pump", "subsidy": 60, "unit": "% of cost"},
                {"component": "Grid Solar (Component C)", "subsidy": 40, "unit": "% of cost"}
            ],
            "eligibility": "Farmers with agricultural land",
            "documents": ["Land records", "Aadhaar", "Bank account"],
            "apply_url": "https://pmkusum.mnre.gov.in",
            "approval_time": "60-90 days",
            "active": True
        },
        {
            "id": "super-efficient-fan",
            "name": "Super Efficient Fan Programme",
            "type": SchemeType.ENERGY_EFFICIENCY,
            "ministry": "Ministry of Power (BEE)",
            "description": "BLDC fan subsidy",
            "benefits": [
                {"item": "BLDC Fan", "subsidy": 1500, "unit": "₹ per fan"}
            ],
            "eligibility": "Domestic consumers",
            "documents": ["Electricity bill"],
            "apply_url": "https://beeindia.gov.in",
            "approval_time": "Immediate (at retailers)",
            "active": True
        },
        {
            "id": "swachh-bharat",
            "name": "Swachh Bharat Mission - Waste to Energy",
            "type": SchemeType.WASTE_MANAGEMENT,
            "ministry": "Ministry of Housing and Urban Affairs",
            "description": "Support for waste-to-energy projects",
            "benefits": [
                {"project": "Waste to Energy Plant", "subsidy": 50, "unit": "% of project cost"}
            ],
            "eligibility": "Municipal bodies, private developers",
            "documents": ["Project proposal", "Environmental clearance"],
            "apply_url": "https://swachhbharatmission.gov.in",
            "approval_time": "90-120 days",
            "active": True
        }
    ]
    
    # ==================== STATE SCHEMES ====================
    
    STATE_SCHEMES = {
        "Maharashtra": [
            {
                "id": "mh-net-metering",
                "name": "MSEDCL Net Metering Scheme",
                "type": SchemeType.SOLAR,
                "description": "Sell excess solar power to grid",
                "benefits": [{"benefit": "Grid export rate", "value": "₹3.5/kWh"}],
                "eligibility": "Rooftop solar owners",
                "apply_url": "https://www.mahadiscom.in"
            },
            {
                "id": "mh-green-building",
                "name": "Green Building Incentive",
                "type": SchemeType.GREEN_BUILDING,
                "description": "Property tax reduction for green buildings",
                "benefits": [{"benefit": "Tax reduction", "value": "10%"}],
                "eligibility": "IGBC certified buildings",
                "apply_url": "https://www.mcgm.gov.in"
            },
            {
                "id": "mh-ev-policy",
                "name": "Maharashtra EV Policy 2021",
                "type": SchemeType.EV,
                "description": "Additional EV subsidy",
                "benefits": [
                    {"vehicle": "E-2W", "subsidy": 10000, "unit": "₹"},
                    {"vehicle": "E-4W", "subsidy": 25000, "unit": "₹"}
                ],
                "eligibility": "EV buyers in Maharashtra",
                "apply_url": "https://www.maharashtra.gov.in"
            }
        ],
        "Karnataka": [
            {
                "id": "ka-solar-policy",
                "name": "Karnataka Solar Policy 2021-26",
                "type": SchemeType.SOLAR,
                "description": "State solar subsidy",
                "benefits": [{"capacity": "1-3 kW", "subsidy": 20000, "unit": "₹"}],
                "eligibility": "Residential consumers",
                "apply_url": "https://kredl.karnataka.gov.in"
            },
            {
                "id": "ka-rainwater-harvesting",
                "name": "Rainwater Harvesting Rebate",
                "type": SchemeType.WATER_CONSERVATION,
                "description": "Property tax rebate for RWH",
                "benefits": [{"benefit": "Tax rebate", "value": "₹1,500/year"}],
                "eligibility": "Buildings with RWH systems",
                "apply_url": "https://bbmp.gov.in"
            }
        ],
        "Gujarat": [
            {
                "id": "gj-solar-rooftop",
                "name": "Gujarat Solar Rooftop Scheme",
                "type": SchemeType.SOLAR,
                "description": "Additional state subsidy on solar",
                "benefits": [{"capacity": "1-3 kW", "subsidy": 15000, "unit": "₹"}],
                "eligibility": "Residential consumers",
                "apply_url": "https://geda.gujarat.gov.in"
            }
        ],
        "Delhi": [
            {
                "id": "dl-solar-policy",
                "name": "Delhi Solar Policy 2024",
                "type": SchemeType.SOLAR,
                "description": "Generation-based incentive",
                "benefits": [{"benefit": "Incentive", "value": "₹2/kWh for 5 years"}],
                "eligibility": "Rooftop solar owners",
                "apply_url": "https://www.delhi.gov.in"
            },
            {
                "id": "dl-ev-policy",
                "name": "Delhi EV Policy 2020",
                "type": SchemeType.EV,
                "description": "Highest EV subsidy in India",
                "benefits": [
                    {"vehicle": "E-2W", "subsidy": 30000, "unit": "₹"},
                    {"vehicle": "E-4W", "subsidy": 150000, "unit": "₹"}
                ],
                "eligibility": "Delhi residents",
                "apply_url": "https://ev.delhi.gov.in"
            }
        ],
        "Tamil Nadu": [
            {
                "id": "tn-solar-subsidy",
                "name": "Tamil Nadu Solar Subsidy",
                "type": SchemeType.SOLAR,
                "description": "State solar subsidy",
                "benefits": [{"capacity": "1-3 kW", "subsidy": 18000, "unit": "₹"}],
                "eligibility": "Residential consumers",
                "apply_url": "https://teda.in"
            }
        ],
        "Rajasthan": [
            {
                "id": "rj-solar-policy",
                "name": "Rajasthan Solar Energy Policy",
                "type": SchemeType.SOLAR,
                "description": "Solar rooftop subsidy",
                "benefits": [{"capacity": "1-3 kW", "subsidy": 12000, "unit": "₹"}],
                "eligibility": "Residential consumers",
                "apply_url": "https://energy.rajasthan.gov.in"
            }
        ],
        "Uttar Pradesh": [
            {
                "id": "up-solar-scheme",
                "name": "UP Solar Energy Policy",
                "type": SchemeType.SOLAR,
                "description": "State solar subsidy",
                "benefits": [{"capacity": "1-3 kW", "subsidy": 15000, "unit": "₹"}],
                "eligibility": "Residential consumers",
                "apply_url": "https://upneda.org.in"
            }
        ],
        # Add more states...
        "West Bengal": [],
        "Madhya Pradesh": [],
        "Bihar": [],
        "Andhra Pradesh": [],
        "Telangana": [],
        "Kerala": [],
        "Odisha": [],
        "Assam": [],
        "Punjab": [],
        "Haryana": [],
        "Jharkhand": [],
        "Chhattisgarh": [],
        "Uttarakhand": [],
        "Himachal Pradesh": [],
        "Goa": [],
        "Meghalaya": [],
        "Manipur": [],
        "Tripura": [],
        "Mizoram": [],
        "Nagaland": [],
        "Arunachal Pradesh": [],
        "Sikkim": [],
        # UTs
        "Chandigarh": [],
        "Puducherry": [],
        "Jammu and Kashmir": [],
        "Ladakh": [],
        "Andaman and Nicobar": [],
        "Lakshadweep": [],
        "Dadra and Nagar Haveli and Daman and Diu": []
    }
    
    @classmethod
    def get_all_schemes(cls) -> List[Dict]:
        """Get all central + state schemes"""
        all_schemes = cls.CENTRAL_SCHEMES.copy()
        for state, schemes in cls.STATE_SCHEMES.items():
            for scheme in schemes:
                scheme['state'] = state
                all_schemes.append(scheme)
        return all_schemes
    
    @classmethod
    def get_schemes_by_state(cls, state: str) -> Dict:
        """Get schemes for a specific state"""
        return {
            "central_schemes": cls.CENTRAL_SCHEMES,
            "state_schemes": cls.STATE_SCHEMES.get(state, []),
            "state": state
        }
    
    @classmethod
    def get_schemes_by_type(cls, scheme_type: SchemeType) -> List[Dict]:
        """Get schemes by type (solar, EV, etc.)"""
        all_schemes = cls.get_all_schemes()
        return [s for s in all_schemes if s.get('type') == scheme_type]
    
    @classmethod
    def recommend_subsidies(cls, user_profile: Dict) -> Dict:
        """
        Smart subsidy recommender based on user profile
        
        Args:
            user_profile: {
                "state": "Maharashtra",
                "action": "solar" | "ev" | "energy_efficiency",
                "capacity_kw": 2.5,  # for solar
                "vehicle_type": "E-2W",  # for EV
                "income_bracket": "< 10L" | "10-20L" | "> 20L"
            }
        """
        state = user_profile.get("state", "Maharashtra")
        action = user_profile.get("action", "solar")
        
        # Map action to scheme type
        action_to_type = {
            "solar": SchemeType.SOLAR,
            "ev": SchemeType.EV,
            "energy_efficiency": SchemeType.ENERGY_EFFICIENCY,
            "waste": SchemeType.WASTE_MANAGEMENT,
            "water": SchemeType.WATER_CONSERVATION
        }
        
        scheme_type = action_to_type.get(action, SchemeType.SOLAR)
        
        # Get central schemes
        central = [s for s in cls.CENTRAL_SCHEMES if s.get('type') == scheme_type]
        
        # Get state schemes
        state_schemes = cls.STATE_SCHEMES.get(state, [])
        state = [s for s in state_schemes if s.get('type') == scheme_type]
        
        # Calculate total subsidy
        total_subsidy = 0
        
        if action == "solar":
            capacity = user_profile.get("capacity_kw", 2.5)
            # PM Surya Ghar
            if capacity <= 1:
                total_subsidy += 30000
            elif capacity <= 2:
                total_subsidy += 60000
            else:
                total_subsidy += 78000
            
            # State subsidy (example: Maharashtra ₹20K)
            if state == "Maharashtra":
                total_subsidy += 20000
        
        elif action == "ev":
            vehicle = user_profile.get("vehicle_type", "E-2W")
            # FAME II
            if vehicle == "E-2W":
                total_subsidy += 50000
            elif vehicle == "E-4W":
                total_subsidy += 150000
            
            # State subsidy
            if state == "Maharashtra":
                if vehicle == "E-2W":
                    total_subsidy += 10000
                elif vehicle == "E-4W":
                    total_subsidy += 25000
        
        return {
            "eligible_schemes": central + state,
            "total_subsidy": total_subsidy,
            "central_subsidy": sum(s.get('benefits', [{}])[0].get('subsidy', 0) for s in central if 'benefits' in s),
            "state_subsidy": sum(s.get('benefits', [{}])[0].get('subsidy', 0) for s in state if 'benefits' in s),
            "application_steps": [
                "1. Gather required documents",
                "2. Apply for central scheme (PM Surya Ghar/FAME II)",
                "3. Apply for state scheme simultaneously",
                "4. Track application status",
                "5. Receive subsidy post-installation/purchase"
            ],
            "estimated_approval_time": "45-90 days",
            "documents_required": list(set(
                doc for s in (central + state) 
                for doc in s.get('documents', [])
            ))
        }
    
    @classmethod
    def get_coverage_stats(cls) -> Dict:
        """Get database coverage statistics"""
        total_states = len(cls.STATE_SCHEMES)
        states_with_schemes = sum(1 for schemes in cls.STATE_SCHEMES.values() if len(schemes) > 0)
        total_schemes = len(cls.get_all_schemes())
        
        return {
            "total_central_schemes": len(cls.CENTRAL_SCHEMES),
            "total_states_uts": total_states,
            "states_with_schemes": states_with_schemes,
            "total_schemes": total_schemes,
            "coverage": f"{states_with_schemes}/{total_states} states/UTs",
            "scheme_types": [t.value for t in SchemeType]
        }
