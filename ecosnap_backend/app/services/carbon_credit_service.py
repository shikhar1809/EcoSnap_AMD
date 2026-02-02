"""
Carbon Credit Trading Scheme (CCTS) 2023 Service
Implements India's official carbon market framework under BEE
"""
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from enum import Enum

class Sector(str, Enum):
    """9 energy-intensive sectors under CCTS 2023"""
    ALUMINIUM = "aluminium"
    CEMENT = "cement"
    IRON_STEEL = "iron_steel"
    CHLOR_ALKALI = "chlor_alkali"
    FERTILIZER = "fertilizer"
    PAPER_PULP = "paper_pulp"
    PETROCHEMICAL = "petrochemical"
    REFINERY = "refinery"
    TEXTILE = "textile"

class CCTSEngine:
    """
    Bureau of Energy Efficiency (BEE) approved emission intensity targets
    Effective from April 2025
    """
    
    # GHG Emission Intensity Targets (tCO2e per tonne of product)
    SECTOR_TARGETS = {
        Sector.CEMENT: 0.62,        # tCO2/tonne cement
        Sector.IRON_STEEL: 2.4,     # tCO2/tonne steel
        Sector.ALUMINIUM: 16.5,     # tCO2/tonne aluminium
        Sector.CHLOR_ALKALI: 1.8,   # tCO2/tonne caustic soda
        Sector.FERTILIZER: 3.2,     # tCO2/tonne ammonia
        Sector.PAPER_PULP: 0.9,     # tCO2/tonne paper
        Sector.PETROCHEMICAL: 2.1,  # tCO2/tonne ethylene
        Sector.REFINERY: 0.045,     # tCO2/tonne crude processed
        Sector.TEXTILE: 0.7,        # tCO2/tonne fabric
    }
    
    # Carbon Credit Certificate (CCC) pricing (₹ per tCO2e)
    # Based on CERC-approved power exchange rates
    CCC_BASE_PRICE = 1500  # ₹1,500 per tCO2e
    CCC_PRICE_VOLATILITY = 0.15  # ±15% market fluctuation
    
    @classmethod
    def calculate_emission_intensity(cls, sector: Sector, emissions_tco2: float, production_tonnes: float) -> float:
        """Calculate actual emission intensity"""
        if production_tonnes == 0:
            return 0
        return emissions_tco2 / production_tonnes
    
    @classmethod
    def calculate_ccc_eligibility(cls, sector: Sector, emissions_tco2: float, production_tonnes: float) -> Dict:
        """
        Calculate Carbon Credit Certificates (CCCs) eligibility
        
        Returns:
            - status: SURPLUS (can sell) or DEFICIT (must buy)
            - credits/deficit: Amount of CCCs
            - compliance: Whether entity meets target
        """
        actual_intensity = cls.calculate_emission_intensity(sector, emissions_tco2, production_tonnes)
        target_intensity = cls.SECTOR_TARGETS.get(sector, 0)
        
        if target_intensity == 0:
            return {
                "status": "NOT_OBLIGATED",
                "message": "Sector not under CCTS 2023 compliance mechanism"
            }
        
        # Calculate surplus or deficit
        intensity_diff = target_intensity - actual_intensity
        ccc_amount = abs(intensity_diff * production_tonnes)
        
        if intensity_diff > 0:
            # Below target = Surplus = Can sell CCCs
            return {
                "status": "SURPLUS",
                "credits": round(ccc_amount, 2),
                "actual_intensity": round(actual_intensity, 3),
                "target_intensity": target_intensity,
                "compliance": True,
                "message": f"Congratulations! You can sell {round(ccc_amount, 2)} CCCs",
                "estimated_value": round(ccc_amount * cls.CCC_BASE_PRICE, 2)
            }
        else:
            # Above target = Deficit = Must buy CCCs
            return {
                "status": "DEFICIT",
                "deficit": round(ccc_amount, 2),
                "actual_intensity": round(actual_intensity, 3),
                "target_intensity": target_intensity,
                "compliance": False,
                "message": f"You must purchase {round(ccc_amount, 2)} CCCs to comply",
                "estimated_cost": round(ccc_amount * cls.CCC_BASE_PRICE, 2)
            }
    
    @classmethod
    def get_current_ccc_price(cls) -> Dict:
        """
        Get current CCC market price.
        In a production environment, this would fetch from IEX (Indian Energy Exchange) API.
        For now, we return the BEE baseline reference price to avoid 'fake' random fluctuations.
        """
        current_price = cls.CCC_BASE_PRICE 
        
        return {
            "price_per_tco2": round(current_price, 2),
            "currency": "INR",
            "exchange": "IEX (Indian Energy Exchange)",
            "timestamp": datetime.now().isoformat(),
            "24h_change": 0.0, # Stable until real feed connected
            "volume_traded": "Market Data Unavailable", 
            "note": "Price based on BEE Reference Rate"
        }


class OffsetProjectEngine:
    """
    Offset Mechanism for non-obligated entities
    Renewable energy, reforestation, waste management projects
    """
    
    PROJECT_TYPES = {
        "solar_rooftop": {
            "name": "Rooftop Solar Installation",
            "credits_per_kw_year": 1.25,  # tCO2e per kW per year
            "verification_period": "Annual",
            "eligibility": "Residential/Commercial solar systems"
        },
        "reforestation": {
            "name": "Tree Plantation",
            "credits_per_tree_year": 0.02,  # tCO2e per tree per year
            "verification_period": "Quarterly",
            "eligibility": "Verified plantation projects"
        },
        "waste_to_energy": {
            "name": "Waste-to-Energy Plant",
            "credits_per_tonne_waste": 0.5,  # tCO2e per tonne waste processed
            "verification_period": "Monthly",
            "eligibility": "CPCB authorized facilities"
        },
        "biogas": {
            "name": "Biogas Plant",
            "credits_per_m3_day": 0.8,  # tCO2e per m³/day capacity per year
            "verification_period": "Quarterly",
            "eligibility": "Agricultural/Municipal biogas plants"
        },
        "energy_efficiency": {
            "name": "Energy Efficiency Upgrade",
            "credits_per_kwh_saved": 0.00082,  # tCO2e per kWh saved (India grid factor)
            "verification_period": "Annual",
            "eligibility": "Verified energy audits"
        }
    }
    
    @classmethod
    def calculate_offset_credits(cls, project_type: str, project_data: Dict) -> Dict:
        """
        Calculate offset credits for voluntary projects
        
        Args:
            project_type: Type of offset project
            project_data: Project-specific data (capacity, duration, etc.)
        """
        if project_type not in cls.PROJECT_TYPES:
            return {"error": "Invalid project type"}
        
        project_info = cls.PROJECT_TYPES[project_type]
        
        if project_type == "solar_rooftop":
            capacity_kw = project_data.get("capacity_kw", 0)
            years = project_data.get("years", 1)
            credits = capacity_kw * project_info["credits_per_kw_year"] * years
            
        elif project_type == "reforestation":
            trees = project_data.get("trees_planted", 0)
            years = project_data.get("years", 1)
            credits = trees * project_info["credits_per_tree_year"] * years
            
        elif project_type == "waste_to_energy":
            waste_tonnes_year = project_data.get("waste_tonnes_year", 0)
            years = project_data.get("years", 1)
            credits = waste_tonnes_year * project_info["credits_per_tonne_waste"] * years
            
        elif project_type == "biogas":
            capacity_m3_day = project_data.get("capacity_m3_day", 0)
            years = project_data.get("years", 1)
            credits = capacity_m3_day * project_info["credits_per_m3_day"] * years
            
        elif project_type == "energy_efficiency":
            kwh_saved_year = project_data.get("kwh_saved_year", 0)
            years = project_data.get("years", 1)
            credits = kwh_saved_year * project_info["credits_per_kwh_saved"] * years
        
        else:
            credits = 0
        
        return {
            "project_type": project_type,
            "project_name": project_info["name"],
            "credits_earned": round(credits, 2),
            "verification_period": project_info["verification_period"],
            "estimated_value": round(credits * CCTSEngine.CCC_BASE_PRICE, 2),
            "eligibility": project_info["eligibility"],
            "next_verification": (datetime.now() + timedelta(days=90)).strftime("%Y-%m-%d")
        }


class PersonalCarbonWallet:
    """
    Personal carbon wallet for households
    Track emissions, earn offset credits, trade CCCs
    """
    
    # Household emission factors (India-specific)
    EMISSION_FACTORS = {
        "electricity_kwh": 0.82,      # kgCO2 per kWh (India grid average)
        "lpg_kg": 2.98,                # kgCO2 per kg LPG
        "petrol_liter": 2.31,          # kgCO2 per liter
        "diesel_liter": 2.68,          # kgCO2 per liter
        "cng_kg": 2.75,                # kgCO2 per kg CNG
        "water_liter": 0.0003,         # kgCO2 per liter (treatment + pumping)
        "waste_kg": 0.5,               # kgCO2 per kg waste (landfill methane)
    }
    
    @classmethod
    def calculate_household_emissions(cls, monthly_consumption: Dict) -> Dict:
        """
        Calculate monthly household carbon footprint
        
        Args:
            monthly_consumption: Dict with consumption data
                {
                    "electricity_kwh": 300,
                    "lpg_kg": 14.2,
                    "petrol_liter": 40,
                    ...
                }
        """
        total_emissions = 0
        breakdown = {}
        
        for category, consumption in monthly_consumption.items():
            if category in cls.EMISSION_FACTORS:
                emissions = consumption * cls.EMISSION_FACTORS[category]
                breakdown[category] = round(emissions, 2)
                total_emissions += emissions
        
        # Convert to tCO2e
        total_tco2 = total_emissions / 1000
        
        # Calculate offset credits earned (if any green actions)
        offset_credits = monthly_consumption.get("offset_credits", 0)
        
        # Net emissions
        net_emissions = total_tco2 - offset_credits
        
        return {
            "total_emissions_kgco2": round(total_emissions, 2),
            "total_emissions_tco2": round(total_tco2, 3),
            "breakdown": breakdown,
            "offset_credits": offset_credits,
            "net_emissions_tco2": round(net_emissions, 3),
            "comparison": {
                "india_avg_household": 2.5,  # tCO2/month
                "your_percentile": round((net_emissions / 2.5) * 100, 1)
            },
            "trees_to_offset": round(net_emissions / 0.02, 0),  # Trees needed to offset
            "recommendations": cls._get_reduction_recommendations(breakdown)
        }
    
    @classmethod
    def _get_reduction_recommendations(cls, breakdown: Dict) -> List[str]:
        """Generate personalized reduction recommendations"""
        recommendations = []
        
        if breakdown.get("electricity_kwh", 0) > 200:
            recommendations.append("Switch to solar: Save 80% on electricity emissions")
        
        if breakdown.get("lpg_kg", 0) > 10:
            recommendations.append("Install solar water heater: Reduce LPG by 30%")
        
        if breakdown.get("petrol_liter", 0) > 30:
            recommendations.append("Consider EV or carpooling: Cut transport emissions by 50%")
        
        if not recommendations:
            recommendations.append("Great job! You're below average emissions")
        
        return recommendations


# Demo data for testing
DEMO_COMPLIANCE_DATA = {
    "cement_plant_a": {
        "sector": Sector.CEMENT,
        "emissions_tco2": 62000,
        "production_tonnes": 100000,
        "company": "ABC Cement Ltd"
    },
    "steel_mill_b": {
        "sector": Sector.IRON_STEEL,
        "emissions_tco2": 240000,
        "production_tonnes": 100000,
        "company": "XYZ Steel Industries"
    }
}

DEMO_OFFSET_PROJECTS = {
    "solar_home_1": {
        "type": "solar_rooftop",
        "data": {"capacity_kw": 2.5, "years": 1},
        "owner": "Residential User"
    },
    "tree_plantation_1": {
        "type": "reforestation",
        "data": {"trees_planted": 1000, "years": 1},
        "owner": "NGO Green Earth"
    }
}
