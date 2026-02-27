from typing import List, Dict, Optional
from enum import Enum
from app.database import supabase
import json

class SchemeType(str, Enum):
    SOLAR = "solar"
    EV = "electric_vehicle"
    ENERGY_EFFICIENCY = "energy_efficiency"
    WASTE_MANAGEMENT = "waste_management"
    WATER_CONSERVATION = "water_conservation"
    GREEN_BUILDING = "green_building"
    AGRICULTURE = "agriculture"

class SubsidyDatabase:
    """Complete subsidy database for India, backed by Supabase"""
    
    # SEED DATA (Only used if DB is empty)
    _SEED_CENTRAL = [
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
            "active": True,
            "scope": "central"
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
            "apply_url": "https://fame2.heavyindustries.gov.in",
            "active": True,
            "scope": "central"
        }
    ]

    _SEED_STATE = {
         "Maharashtra": [
            {
                "id": "mh-net-metering",
                "name": "MSEDCL Net Metering Scheme",
                "type": SchemeType.SOLAR,
                "description": "Sell excess solar power to grid",
                "benefits": [{"benefit": "Grid export rate", "value": "₹3.5/kWh"}],
                "scope": "state",
                "state": "Maharashtra"
            }
        ],
        "Delhi": [
            {
                "id": "dl-ev-policy",
                "name": "Delhi EV Policy 2020",
                "type": SchemeType.EV,
                "description": "Highest EV subsidy in India",
                "benefits": [{"vehicle": "E-2W", "subsidy": 30000}],
                "scope": "state",
                "state": "Delhi"
            }
        ]
    }

    @classmethod
    def _ensure_initialized(cls):
        """Seed schemes if table is empty"""
        try:
            res = supabase.table("schemes").select("count", count="exact").execute()
            if res.count == 0:
                print("Seeding Subsidy DB...")
                cls._seed_db()
        except Exception as e:
            print(f"Subsidy Init Error: {e}")

    @classmethod
    def _seed_db(cls):
        all_schemes = cls._SEED_CENTRAL.copy()
        for state, schemes in cls._SEED_STATE.items():
            for s in schemes:
                s['state'] = state
                all_schemes.append(s)
        
        try:
            supabase.table("schemes").upsert(all_schemes).execute()
        except Exception as e:
            print(f"Seeding Schemes Error: {e}")

    @classmethod
    def get_all_schemes(cls) -> List[Dict]:
        """Get all schemes from DB"""
        cls._ensure_initialized()
        try:
            return supabase.table("schemes").select("*").execute().data
        except: return cls._SEED_CENTRAL # Fallback

    @classmethod
    def get_schemes_by_state(cls, state: str) -> Dict:
        """Get schemes for a specific state"""
        cls._ensure_initialized()
        try:
            central = supabase.table("schemes").select("*").eq("scope", "central").execute().data
            state_schemes = supabase.table("schemes").select("*").eq("state", state).execute().data
            return {
                "central_schemes": central,
                "state_schemes": state_schemes,
                "state": state
            }
        except: return {"central_schemes": [], "state_schemes": [], "state": state}

    @classmethod
    def recommend_subsidies(cls, user_profile: Dict) -> Dict:
        """Smart subsidy recommender based on user profile"""
        cls._ensure_initialized()
        
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
        
        try:
             all_schemes = supabase.table("schemes").select("*").eq("type", scheme_type).execute().data
             central = [s for s in all_schemes if s.get('scope') == 'central']
             state_schemes = [s for s in all_schemes if s.get('state') == state]
             
             # Calculate total subsidy logic (simplified for DB)
             total_subsidy = 0
             # Note: Complex logic for calculating subsidy amount remains, but data source is DB now.
             # Preserving the specific calculation logic for PM Surya/FAME would require parsing 'benefits' JSON column.
             
             # Re-implementing basic logic assuming standard structure
             if action == "solar":
                 cap = user_profile.get("capacity_kw", 2.5)
                 if cap <= 1: total_subsidy += 30000
                 elif cap <= 2: total_subsidy += 60000
                 else: total_subsidy += 78000
                 if state == "Maharashtra": total_subsidy += 20000

             elif action == "ev":
                 veh = user_profile.get("vehicle_type", "E-2W")
                 if veh == "E-2W": total_subsidy += 50000
                 elif veh == "E-4W": total_subsidy += 150000
                 
             return {
                "eligible_schemes": central + state_schemes,
                "total_subsidy": total_subsidy,
                "application_steps": ["1. Apply online", "2. Verify docs"],
                "estimated_approval_time": "45-90 days"
             }

        except Exception as e:
            print(f"Recommend Error: {e}")
            return {"error": "Could not fetch recommendations"}

    @classmethod
    def get_trending_schemes(cls, state: str) -> List[Dict]:
        """Get trending subsidies"""
        try:
            # Mocking trending by just returning central + state top list
            # In real app, we would query 'application_count' from DB
            data = cls.get_schemes_by_state(state)
            trending = data['central_schemes'][:2] + data['state_schemes'][:2]
            if trending:
                return trending
        except:
            pass
        
        # Fallback demo trending data when DB is unavailable
        return [
            {"name": "PM Surya Ghar: Muft Bijli Yojana", "type": "solar", "amount": "₹78,000", "users_applied": "1.2L+", "scope": "central"},
            {"name": "FAME India Phase II (EV)", "type": "ev", "amount": "₹1.5 Lakh", "users_applied": "3.5k+", "scope": "central"},
            {"name": f"{state} Solar Rooftop Policy", "type": "solar", "amount": "₹20,000", "users_applied": "800+", "scope": "state"},
            {"name": f"{state} EV Adoption Incentive", "type": "ev", "amount": "₹30,000", "users_applied": "1.1k+", "scope": "state"},
        ]

    @classmethod
    def get_coverage_stats(cls) -> Dict:
        """Get database coverage statistics"""
        return {
            "total_central_schemes": 15, # Placeholder or DB count
            "coverage": "Pan India"
        }
