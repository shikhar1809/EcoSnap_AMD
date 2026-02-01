from fastapi import APIRouter, HTTPException
from typing import Optional
from app.services.external_api_service import ExternalAPIService

router = APIRouter()

@router.get("/pm-surya-ghar/{system_kw}")
async def get_pm_surya_ghar_subsidy(system_kw: float):
    """
    Get PM Surya Ghar subsidy details for a given system size
    
    Official rates:
    - 1kW: ₹30,000
    - 2kW: ₹60,000
    - 3kW+: ₹78,000 (max)
    """
    try:
        subsidy_data = await ExternalAPIService.get_pm_surya_ghar_subsidy(system_kw)
        return subsidy_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/state-schemes")
async def get_state_schemes(state: str = "Maharashtra"):
    """
    Get state-specific renewable energy subsidies
    """
    try:
        schemes = await ExternalAPIService.get_state_subsidies(state)
        return {
            "state": state,
            "schemes": schemes,
            "count": len(schemes)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/installers")
async def get_verified_installers(
    city: str = "Mumbai",
    system_kw: float = 2.5
):
    """
    Get verified solar installers near user location
    """
    try:
        installers = await ExternalAPIService.get_installer_data(city, system_kw)
        
        # Calculate quotes for each installer
        for installer in installers:
            installer['total_quote'] = int(installer['quote_per_kw'] * system_kw)
            installer['total_quote_formatted'] = f"₹{installer['total_quote']:,}"
        
        return {
            "city": city,
            "system_kw": system_kw,
            "installers": installers,
            "count": len(installers)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/eco-alternatives/{category}")
async def get_eco_alternatives(category: str):
    """
    Get eco-friendly product alternatives from Fake Store API
    
    Categories: electronics, clothing, bottle, watch, furniture
    """
    try:
        alternatives = await ExternalAPIService.get_eco_alternatives(category)
        return {
            "category": category,
            "alternatives": alternatives,
            "count": len(alternatives),
            "source": "Fake Store API"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/complete-subsidy-info/{system_kw}")
async def get_complete_subsidy_info(
    system_kw: float,
    state: str = "Maharashtra"
):
    """
    Get complete subsidy information including central + state schemes
    """
    try:
        # Get PM Surya Ghar (central)
        central_subsidy = await ExternalAPIService.get_pm_surya_ghar_subsidy(system_kw)
        
        # Get state subsidies
        state_schemes = await ExternalAPIService.get_state_subsidies(state)
        
        # Calculate total potential savings
        total_subsidy = central_subsidy['subsidy_amount']
        
        # Add state capital subsidy if available
        for scheme in state_schemes:
            if 'Capital Subsidy' in scheme.get('type', ''):
                # Extract amount from benefit string (e.g., "Additional ₹10,000/kW")
                if 'Additional' in scheme.get('benefit', ''):
                    try:
                        amount_per_kw = int(scheme['benefit'].split('₹')[1].split('/')[0].replace(',', ''))
                        max_amount = int(scheme.get('max', '0').replace('₹', '').replace(',', ''))
                        state_subsidy = min(amount_per_kw * system_kw, max_amount)
                        total_subsidy += state_subsidy
                    except:
                        pass
        
        return {
            "system_kw": system_kw,
            "state": state,
            "central_scheme": central_subsidy,
            "state_schemes": state_schemes,
            "total_subsidy": total_subsidy,
            "total_subsidy_formatted": f"₹{total_subsidy:,}",
            "net_system_cost": int(system_kw * 50000 - total_subsidy),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
