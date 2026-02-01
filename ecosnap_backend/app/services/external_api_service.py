"""
External API Integration Service
Integrates with:
1. Fake Store API - Product alternatives
2. PM Surya Ghar - Solar subsidies
3. DummyJSON - Additional product data
"""
import httpx
import asyncio
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import json

class ExternalAPIService:
    """Service for fetching data from external APIs"""
    
    # API Base URLs
    FAKE_STORE_API = "https://fakestoreapi.com"
    DUMMY_JSON_API = "https://dummyjson.com"
    
    # Cache for API responses (simple in-memory cache)
    _cache = {}
    _cache_ttl = timedelta(hours=24)
    
    @classmethod
    async def get_eco_alternatives(cls, product_category: str) -> List[Dict]:
        """
        Get eco-friendly product alternatives from Fake Store API
        
        Args:
            product_category: Category like 'electronics', 'clothing', 'bottle', etc.
        
        Returns:
            List of alternative products with pricing
        """
        cache_key = f"alternatives_{product_category}"
        
        # Check cache
        if cache_key in cls._cache:
            cached_data, cached_time = cls._cache[cache_key]
            if datetime.now() - cached_time < cls._cache_ttl:
                return cached_data
        
        try:
            async with httpx.AsyncClient() as client:
                # Map product categories to Fake Store categories
                category_map = {
                    'electronics': 'electronics',
                    'clothing': "men's clothing",
                    'bottle': 'electronics',  # Map to reusable items
                    'watch': 'electronics',
                    'furniture': 'electronics',
                }
                
                api_category = category_map.get(product_category.lower(), 'electronics')
                
                # Fetch products from category
                response = await client.get(
                    f"{cls.FAKE_STORE_API}/products/category/{api_category}",
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    products = response.json()
                    
                    # Transform to our format
                    alternatives = []
                    for product in products[:3]:  # Take top 3
                        alternatives.append({
                            'name': product['title'],
                            'price_estimate': f"₹{int(product['price'] * 83)}",  # USD to INR
                            'benefit': cls._generate_eco_benefit(product['category']),
                            'carbon_savings': f"{cls._estimate_carbon_savings(product['category'])} kg/year",
                            'image': product.get('image', ''),
                            'rating': product.get('rating', {}).get('rate', 4.0),
                        })
                    
                    # Cache the result
                    cls._cache[cache_key] = (alternatives, datetime.now())
                    return alternatives
                    
        except Exception as e:
            print(f"Error fetching alternatives: {e}")
        
        # Fallback to demo data
        return cls._get_fallback_alternatives(product_category)
    
    @classmethod
    async def get_pm_surya_ghar_subsidy(cls, system_kw: float) -> Dict:
        """
        Calculate PM Surya Ghar subsidy based on system size
        
        Official rates:
        - 1kW: ₹30,000
        - 2kW: ₹60,000
        - 3kW+: ₹78,000 (max)
        
        Args:
            system_kw: Solar system size in kW
        
        Returns:
            Subsidy details
        """
        if system_kw <= 1:
            subsidy_amount = 30000
        elif system_kw <= 2:
            subsidy_amount = 60000
        else:
            subsidy_amount = 78000  # Maximum subsidy
        
        return {
            'scheme_name': 'PM Surya Ghar: Muft Bijli Yojana',
            'subsidy_amount': subsidy_amount,
            'subsidy_amount_formatted': f"₹{subsidy_amount:,}",
            'system_kw': system_kw,
            'portal': 'https://pmsuryaghar.gov.in',
            'eligibility': 'All residential consumers',
            'application_process': 'Online through PM Surya Ghar portal',
            'documents_required': [
                'Aadhaar Card',
                'Electricity Bill',
                'Bank Account Details',
                'Roof Ownership Proof'
            ],
            'timeline': '30-45 days after installation',
            'additional_benefits': [
                'Net metering facility',
                'Priority grid connection',
                'Technical support'
            ]
        }
    
    @classmethod
    async def get_state_subsidies(cls, state: str = 'Maharashtra') -> List[Dict]:
        """
        Get state-specific renewable energy subsidies
        
        Note: This would ideally scrape from data.gov.in or state portals
        For now, using curated data
        """
        state_schemes = {
            'Maharashtra': [
                {
                    'name': 'MSEDCL Solar Rooftop Scheme',
                    'type': 'Net Metering',
                    'benefit': 'Sell excess power to grid',
                    'rate': '₹3.5/kWh',
                },
                {
                    'name': 'Green Building Incentive',
                    'type': 'Property Tax Rebate',
                    'benefit': '10% property tax reduction',
                    'duration': '5 years',
                }
            ],
            'Karnataka': [
                {
                    'name': 'BESCOM Solar Rooftop',
                    'type': 'Capital Subsidy',
                    'benefit': 'Additional ₹10,000/kW',
                    'max': '₹30,000',
                }
            ],
            'Gujarat': [
                {
                    'name': 'GEDA Solar Subsidy',
                    'type': 'Capital Subsidy',
                    'benefit': 'Additional ₹15,000/kW',
                    'max': '₹45,000',
                }
            ]
        }
        
        return state_schemes.get(state, [])
    
    @classmethod
    async def get_installer_data(cls, city: str = 'Mumbai', system_kw: float = 2.5) -> List[Dict]:
        """
        Get verified solar installers
        
        Note: In production, this would integrate with:
        - MNRE approved installer database
        - Google Maps API for locations
        - Review platforms for ratings
        
        For now, using curated demo data
        """
        # This would be replaced with actual API calls
        return [
            {
                'name': 'SunPower Solutions',
                'mnre_id': 'MNRE/2023/12345',
                'rating': 4.9,
                'reviews': 247,
                'projects': 156,
                'city': city,
                'distance_km': 2.3,
                'response_time_hours': 2,
                'certifications': ['MNRE Approved', 'ISO 9001'],
                'quote_per_kw': 38000,
                'warranty_years': 25,
                'installation_days': '3-5',
                'contact': '+91 98765 43210',
            },
            {
                'name': 'Green Energy India',
                'mnre_id': 'MNRE/2023/67890',
                'rating': 4.7,
                'reviews': 189,
                'projects': 203,
                'city': city,
                'distance_km': 4.1,
                'response_time_hours': 4,
                'certifications': ['MNRE Approved'],
                'quote_per_kw': 42000,
                'warranty_years': 20,
                'installation_days': '5-7',
                'contact': '+91 98765 43211',
            },
            {
                'name': 'EcoWatt Systems',
                'mnre_id': 'MNRE/2023/11223',
                'rating': 4.8,
                'reviews': 312,
                'projects': 278,
                'city': city,
                'distance_km': 5.8,
                'response_time_hours': 3,
                'certifications': ['MNRE Approved', 'ISO 9001', 'BIS Certified'],
                'quote_per_kw': 36800,
                'warranty_years': 25,
                'installation_days': '2-4',
                'contact': '+91 98765 43212',
            }
        ]
    
    @classmethod
    def _generate_eco_benefit(cls, category: str) -> str:
        """Generate eco benefit text based on category"""
        benefits = {
            'electronics': 'Energy Star certified',
            "men's clothing": 'Organic cotton',
            "women's clothing": 'Sustainable fabric',
            'jewelery': 'Recycled materials',
        }
        return benefits.get(category, 'Eco-friendly alternative')
    
    @classmethod
    def _estimate_carbon_savings(cls, category: str) -> int:
        """Estimate carbon savings based on category"""
        savings = {
            'electronics': 280,
            "men's clothing": 45,
            "women's clothing": 45,
            'jewelery': 15,
        }
        return savings.get(category, 100)
    
    @classmethod
    def _get_fallback_alternatives(cls, category: str) -> List[Dict]:
        """Fallback alternatives if API fails"""
        return [
            {
                'name': 'Eco-Friendly Alternative 1',
                'price_estimate': '₹2,999',
                'benefit': 'Energy efficient',
                'carbon_savings': '150 kg/year',
            },
            {
                'name': 'Sustainable Option 2',
                'price_estimate': '₹3,499',
                'benefit': 'Recycled materials',
                'carbon_savings': '200 kg/year',
            }
        ]


# Async helper for testing
async def test_apis():
    """Test all API integrations"""
    print("Testing External APIs...")
    
    # Test 1: Product alternatives
    print("\n1. Testing Fake Store API (Product Alternatives):")
    alternatives = await ExternalAPIService.get_eco_alternatives('electronics')
    print(f"Found {len(alternatives)} alternatives")
    for alt in alternatives:
        print(f"  - {alt['name']}: {alt['price_estimate']}")
    
    # Test 2: PM Surya Ghar subsidy
    print("\n2. Testing PM Surya Ghar Subsidy Calculator:")
    for kw in [1, 2, 3, 5]:
        subsidy = await ExternalAPIService.get_pm_surya_ghar_subsidy(kw)
        print(f"  {kw}kW system: {subsidy['subsidy_amount_formatted']}")
    
    # Test 3: State subsidies
    print("\n3. Testing State Subsidies:")
    state_schemes = await ExternalAPIService.get_state_subsidies('Maharashtra')
    print(f"Found {len(state_schemes)} state schemes")
    for scheme in state_schemes:
        print(f"  - {scheme['name']}: {scheme['benefit']}")
    
    # Test 4: Installers
    print("\n4. Testing Installer Data:")
    installers = await ExternalAPIService.get_installer_data('Mumbai', 2.5)
    print(f"Found {len(installers)} installers")
    for installer in installers:
        quote = installer['quote_per_kw'] * 2.5
        print(f"  - {installer['name']}: ₹{quote:,.0f} (Rating: {installer['rating']})")


if __name__ == "__main__":
    # Run tests
    asyncio.run(test_apis())
