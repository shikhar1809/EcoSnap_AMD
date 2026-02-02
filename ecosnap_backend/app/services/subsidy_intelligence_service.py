"""
Subsidy Intelligence Service
Real government subsidy data, eligibility checking, and application tracking
"""
from typing import Optional, Dict, Any, List
from datetime import datetime

class SubsidyIntelligenceService:
    """Government subsidy integration and eligibility checking"""
    
    # PM Surya Ghar Yojana (Central Government)
    PM_SURYA_GHAR_SCHEME = {
        "name": "PM Surya Ghar: Muft Bijli Yojana",
        "type": "Central Government",
        "category": "Solar Rooftop",
        "description": "Free electricity through rooftop solar panels",
        "website": "https://pmsuryaghar.gov.in",
        "last_updated": "2026-02-01"
    }
    
    # State-wise solar subsidies (India)
    STATE_SUBSIDIES = {
        "Maharashtra": {
            "solar_residential": {
                "scheme_name": "Maharashtra Solar Policy 2024",
                "1-3kw": {"amount_per_kw": 10000, "max_amount": 30000},
                "3-10kw": {"amount_per_kw": 5000, "max_amount": 35000},
                "authority": "MSEDCL",
                "website": "https://www.mahadiscom.in"
            },
            "ev_subsidy": {
                "two_wheeler": 15000,
                "four_wheeler": 150000,
                "scheme_name": "Maharashtra EV Policy 2025"
            }
        },
        "Gujarat": {
            "solar_residential": {
                "scheme_name": "Gujarat Solar Power Policy 2024",
                "1-3kw": {"amount_per_kw": 12000, "max_amount": 36000},
                "3-10kw": {"amount_per_kw": 6000, "max_amount": 42000},
                "authority": "GEDA"
            }
        },
        "Karnataka": {
            "solar_residential": {
                "scheme_name": "Karnataka Solar Policy 2024",
                "1-3kw": {"amount_per_kw": 11000, "max_amount": 33000},
                "3-10kw": {"amount_per_kw": 5500, "max_amount": 38500},
                "authority": "KREDL"
            }
        },
        "Tamil Nadu": {
            "solar_residential": {
                "scheme_name": "Tamil Nadu Solar Energy Policy 2024",
                "1-3kw": {"amount_per_kw": 10000, "max_amount": 30000},
                "3-10kw": {"amount_per_kw": 5000, "max_amount": 35000},
                "authority": "TANGEDCO"
            }
        },
        "Delhi": {
            "solar_residential": {
                "scheme_name": "Delhi Solar Policy 2024",
                "1-3kw": {"amount_per_kw": 15000, "max_amount": 45000},
                "3-10kw": {"amount_per_kw": 7500, "max_amount": 52500},
                "authority": "BSES/TPDDL"
            }
        }
    }
    
    @staticmethod
    def calculate_pm_surya_ghar_subsidy(capacity_kw: float) -> Dict[str, Any]:
        """
        Calculate PM Surya Ghar subsidy (Official formula)
        - Up to 2kW: ₹30,000/kW
        - 2-3kW: ₹18,000/kW for additional capacity
        - Above 3kW: No additional subsidy
        """
        if capacity_kw <= 0:
            return {"amount": 0, "details": "Invalid capacity"}
        
        if capacity_kw <= 2:
            amount = 30000 * capacity_kw
            details = f"₹30,000/kW for {capacity_kw}kW"
        elif capacity_kw <= 3:
            amount = 60000 + (18000 * (capacity_kw - 2))
            details = f"₹60,000 (first 2kW) + ₹18,000/kW for {capacity_kw - 2}kW"
        else:
            amount = 78000  # Maximum subsidy
            details = f"Maximum subsidy: ₹78,000 (for 3kW+)"
        
        return {
            "scheme": "PM Surya Ghar Yojana",
            "capacity_kw": capacity_kw,
            "subsidy_amount": int(amount),
            "calculation_details": details,
            "max_subsidy": 78000,
            "source": "Ministry of New and Renewable Energy"
        }
    
    @staticmethod
    def get_state_subsidy(state: str, capacity_kw: float) -> Optional[Dict[str, Any]]:
        """Get state-specific solar subsidy"""
        if state not in SubsidyIntelligenceService.STATE_SUBSIDIES:
            return None
        
        state_data = SubsidyIntelligenceService.STATE_SUBSIDIES[state]
        solar_scheme = state_data.get("solar_residential")
        
        if not solar_scheme:
            return None
        
        # Determine subsidy tier
        if capacity_kw <= 3:
            tier = solar_scheme.get("1-3kw", {})
        else:
            tier = solar_scheme.get("3-10kw", {})
        
        if not tier:
            return None
        
        # Calculate amount
        amount_per_kw = tier.get("amount_per_kw", 0)
        max_amount = tier.get("max_amount", 0)
        calculated_amount = min(amount_per_kw * capacity_kw, max_amount)
        
        return {
            "scheme": solar_scheme.get("scheme_name", f"{state} Solar Subsidy"),
            "state": state,
            "capacity_kw": capacity_kw,
            "subsidy_amount": int(calculated_amount),
            "authority": solar_scheme.get("authority", "State Energy Department"),
            "website": solar_scheme.get("website", "Contact state authority")
        }
    
    @staticmethod
    def get_total_solar_subsidy(state: str, capacity_kw: float) -> Dict[str, Any]:
        """Get combined central + state subsidy"""
        # Central subsidy
        central = SubsidyIntelligenceService.calculate_pm_surya_ghar_subsidy(capacity_kw)
        
        # State subsidy
        state_subsidy = SubsidyIntelligenceService.get_state_subsidy(state, capacity_kw)
        
        total_subsidy = central["subsidy_amount"]
        if state_subsidy:
            total_subsidy += state_subsidy["subsidy_amount"]
        
        return {
            "capacity_kw": capacity_kw,
            "state": state,
            "central_subsidy": central,
            "state_subsidy": state_subsidy,
            "total_subsidy_amount": total_subsidy,
            "currency": "INR"
        }
    
    @staticmethod
    def check_eligibility(user_data: Dict[str, Any], subsidy_type: str = "pm_surya_ghar") -> Dict[str, Any]:
        """Check user eligibility for subsidy"""
        if subsidy_type == "pm_surya_ghar":
            requirements = {
                "owns_roof": {
                    "required": True,
                    "met": user_data.get("owns_roof", False),
                    "description": "Must own the rooftop/property"
                },
                "electricity_connection": {
                    "required": True,
                    "met": user_data.get("has_electricity_connection", False),
                    "description": "Must have active electricity connection"
                },
                "residential_property": {
                    "required": True,
                    "met": user_data.get("property_type") == "residential",
                    "description": "Property must be residential"
                },
                "aadhaar": {
                    "required": True,
                    "met": user_data.get("has_aadhaar", False),
                    "description": "Aadhaar card required"
                }
            }
            
            eligible = all(req["met"] for req in requirements.values())
            missing = [req["description"] for req in requirements.values() if not req["met"]]
            
            return {
                "subsidy_scheme": "PM Surya Ghar Yojana",
                "eligible": eligible,
                "requirements": requirements,
                "missing_requirements": missing,
                "next_steps": SubsidyIntelligenceService._get_application_steps("pm_surya_ghar") if eligible else ["Fulfill missing requirements first"]
            }
        
        return {"error": "Unknown subsidy type"}
    
    @staticmethod
    def _get_application_steps(subsidy_type: str) -> List[str]:
        """Get application steps for subsidy"""
        if subsidy_type == "pm_surya_ghar":
            return [
                "1. Visit https://pmsuryaghar.gov.in",
                "2. Register with Aadhaar and electricity bill",
                "3. Get technical feasibility assessment",
                "4. Choose empaneled vendor from portal",
                "5. Install solar system as per specifications",
                "6. Submit installation certificate",
                "7. Receive subsidy via DBT (Direct Benefit Transfer)"
            ]
        return []
    
    @staticmethod
    def get_subsidy_recommendations(analysis_result: Dict[str, Any], location: Dict[str, Any]) -> Dict[str, Any]:
        """Get personalized subsidy recommendations based on analysis"""
        state = location.get("state", "Maharashtra")
        
        # Extract capacity from analysis
        capacity_kw = 0
        if "solar_potential" in analysis_result:
            capacity_kw = analysis_result["solar_potential"].get("recommended_capacity_kw", 0)
        
        if capacity_kw == 0:
            return {"message": "No solar potential detected"}
        
        # Get subsidies
        subsidies = SubsidyIntelligenceService.get_total_solar_subsidy(state, capacity_kw)
        
        # Estimate system cost
        cost_per_kw = 50000  # Average ₹50,000/kW in India
        total_cost = capacity_kw * cost_per_kw
        net_cost = total_cost - subsidies["total_subsidy_amount"]
        
        # Calculate payback
        monthly_savings = analysis_result.get("financial_analysis", {}).get("monthly_savings_inr", 5000)
        payback_months = net_cost / monthly_savings if monthly_savings > 0 else 0
        
        return {
            "system_capacity_kw": capacity_kw,
            "estimated_cost_inr": total_cost,
            "subsidies": subsidies,
            "net_cost_after_subsidy": net_cost,
            "subsidy_percentage": round((subsidies["total_subsidy_amount"] / total_cost) * 100, 1),
            "payback_period_years": round(payback_months / 12, 1),
            "monthly_savings_inr": monthly_savings,
            "application_links": {
                "central": "https://pmsuryaghar.gov.in",
                "state": subsidies.get("state_subsidy", {}).get("website", "Contact state authority")
            }
        }
