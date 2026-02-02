"""
Product Intelligence Service
Integrates barcode scanning, product databases, and carbon data
"""
import requests
from typing import Optional, Dict, Any
import io
from PIL import Image

class ProductIntelligenceService:
    """Real-world product data integration"""
    
    # Carbon database (ADEME + custom data)
    CARBON_DATABASE = {
        "plastic_bottle_500ml": {
            "total_co2_g": 127,
            "breakdown": {
                "raw_material_extraction": 45,
                "manufacturing": 38,
                "transportation": 22,
                "packaging": 12,
                "end_of_life": 10
            },
            "source": "ADEME 2023"
        },
        "aluminum_can_330ml": {
            "total_co2_g": 170,
            "breakdown": {
                "raw_material_extraction": 95,
                "manufacturing": 45,
                "transportation": 18,
                "packaging": 8,
                "end_of_life": 4
            },
            "recyclability": 0.95,
            "source": "ADEME 2023"
        },
        "glass_bottle_750ml": {
            "total_co2_g": 340,
            "breakdown": {
                "raw_material_extraction": 120,
                "manufacturing": 150,
                "transportation": 50,
                "packaging": 15,
                "end_of_life": 5
            },
            "recyclability": 0.85,
            "source": "ADEME 2023"
        }
    }
    
    # Material properties database
    MATERIAL_DATABASE = {
        "PET": {
            "code": "#1",
            "full_name": "Polyethylene Terephthalate",
            "recyclability_score": 85,
            "decomposition_years": 450,
            "recycling_rate_india": 60,
            "microplastic_risk": "High",
            "energy_savings_recycling": 70,
            "common_uses": ["Water bottles", "Soft drink bottles", "Food containers"]
        },
        "HDPE": {
            "code": "#2",
            "full_name": "High-Density Polyethylene",
            "recyclability_score": 90,
            "decomposition_years": 500,
            "recycling_rate_india": 55,
            "microplastic_risk": "Medium",
            "energy_savings_recycling": 75,
            "common_uses": ["Milk jugs", "Detergent bottles", "Shampoo bottles"]
        },
        "Aluminum": {
            "code": "ALU",
            "full_name": "Aluminum",
            "recyclability_score": 95,
            "decomposition_years": 200,
            "recycling_rate_india": 70,
            "microplastic_risk": "None",
            "energy_savings_recycling": 95,
            "common_uses": ["Beverage cans", "Food cans"]
        },
        "Glass": {
            "code": "GL",
            "full_name": "Glass",
            "recyclability_score": 85,
            "decomposition_years": 1000000,
            "recycling_rate_india": 45,
            "microplastic_risk": "None",
            "energy_savings_recycling": 30,
            "common_uses": ["Bottles", "Jars", "Containers"]
        }
    }
    
    @staticmethod
    def scan_barcode(image_bytes: bytes) -> Optional[str]:
        """
        Extract barcode/QR code from image using pyzbar
        Returns barcode string or None
        """
        try:
            from pyzbar.pyzbar import decode
            
            image = Image.open(io.BytesIO(image_bytes))
            barcodes = decode(image)
            
            if barcodes:
                barcode_data = barcodes[0].data.decode('utf-8')
                barcode_type = barcodes[0].type
                print(f"Barcode detected: {barcode_data} (Type: {barcode_type})")
                return barcode_data
            
            return None
        except ImportError:
            print("WARNING: pyzbar not installed. Barcode scanning disabled.")
            return None
        except Exception as e:
            print(f"Barcode scanning error: {e}")
            return None
    
    @staticmethod
    def get_product_from_openfoodfacts(barcode: str) -> Optional[Dict[str, Any]]:
        """
        Get product data from Open Food Facts API
        2.8M+ products, completely free
        """
        try:
            url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get('status') == 1:  # Product found
                    product = data['product']
                    
                    return {
                        "found": True,
                        "barcode": barcode,
                        "name": product.get('product_name', 'Unknown'),
                        "brand": product.get('brands', 'Unknown'),
                        "categories": product.get('categories', ''),
                        "ingredients": product.get('ingredients_text', ''),
                        "packaging": product.get('packaging', ''),
                        "eco_score": product.get('ecoscore_grade', 'Unknown'),
                        "nutriscore": product.get('nutriscore_grade', 'Unknown'),
                        "carbon_footprint_100g": product.get('carbon_footprint_from_known_ingredients_100g'),
                        "image_url": product.get('image_url'),
                        "source": "Open Food Facts"
                    }
            
            return {"found": False, "barcode": barcode}
        
        except Exception as e:
            print(f"Open Food Facts API error: {e}")
            return None
    
    @staticmethod
    def get_carbon_data(product_type: str) -> Optional[Dict[str, Any]]:
        """
        Get carbon footprint data from database
        """
        # Normalize product type
        product_type_lower = product_type.lower()
        
        # Try exact match first
        if product_type_lower in ProductIntelligenceService.CARBON_DATABASE:
            return ProductIntelligenceService.CARBON_DATABASE[product_type_lower]
        
        # Try partial match
        for key, value in ProductIntelligenceService.CARBON_DATABASE.items():
            if any(word in product_type_lower for word in key.split('_')):
                return value
        
        return None
    
    @staticmethod
    def get_material_data(material: str) -> Optional[Dict[str, Any]]:
        """
        Get material properties from database
        """
        material_upper = material.upper()
        
        # Try exact match
        if material_upper in ProductIntelligenceService.MATERIAL_DATABASE:
            return ProductIntelligenceService.MATERIAL_DATABASE[material_upper]
        
        # Try partial match
        for key, value in ProductIntelligenceService.MATERIAL_DATABASE.items():
            if material_upper in key or key in material_upper:
                return value
        
        return None
    
    @staticmethod
    def get_green_alternatives(product_category: str, location: Dict[str, Any]) -> list:
        """
        Get sustainable alternatives for product
        """
        # Common alternatives database
        ALTERNATIVES = {
            "plastic_bottle": [
                {
                    "product": "Milton Duo DLX 1000 Thermosteel Bottle",
                    "brand": "Milton",
                    "material": "Stainless Steel",
                    "upfront_cost_inr": 450,
                    "lifespan_years": 5,
                    "co2_per_use_grams": 0.5,  # Washing only
                    "break_even_uses": 23,
                    "annual_savings_co2_kg": 4.6,
                    "annual_savings_money_inr": 1200,
                    "availability": "Amazon, Flipkart, Local stores",
                    "rating": 4.5
                },
                {
                    "product": "Cello Puro Steel-X Bottle",
                    "brand": "Cello",
                    "material": "Stainless Steel",
                    "upfront_cost_inr": 350,
                    "lifespan_years": 5,
                    "co2_per_use_grams": 0.5,
                    "break_even_uses": 19,
                    "annual_savings_co2_kg": 4.6,
                    "annual_savings_money_inr": 1200,
                    "availability": "Amazon, Flipkart",
                    "rating": 4.3
                }
            ],
            "aluminum_can": [
                {
                    "product": "SodaStream Sparkling Water Maker",
                    "brand": "SodaStream",
                    "material": "Reusable System",
                    "upfront_cost_inr": 8500,
                    "lifespan_years": 10,
                    "co2_per_use_grams": 2,
                    "break_even_uses": 150,
                    "annual_savings_co2_kg": 12,
                    "annual_savings_money_inr": 3600,
                    "availability": "Amazon, Croma",
                    "rating": 4.6
                }
            ]
        }
        
        # Find matching alternatives
        category_lower = product_category.lower()
        for key, alternatives in ALTERNATIVES.items():
            if key in category_lower or category_lower in key:
                return alternatives
        
        return []
    
    @staticmethod
    def get_enhanced_product_context(image_bytes: bytes, detected_product: str) -> Dict[str, Any]:
        """
        Combine all product intelligence sources
        """
        context = {
            "barcode_detected": False,
            "product_database_match": False,
            "carbon_data_available": False,
            "material_data_available": False
        }
        
        # Try barcode scanning
        barcode = ProductIntelligenceService.scan_barcode(image_bytes)
        if barcode:
            context["barcode_detected"] = True
            context["barcode"] = barcode
            
            # Try Open Food Facts
            product_data = ProductIntelligenceService.get_product_from_openfoodfacts(barcode)
            if product_data and product_data.get('found'):
                context["product_database_match"] = True
                context["product_data"] = product_data
        
        # Get carbon data
        carbon_data = ProductIntelligenceService.get_carbon_data(detected_product)
        if carbon_data:
            context["carbon_data_available"] = True
            context["carbon_data"] = carbon_data
        
        # Get material data (try to detect from product name)
        for material in ["PET", "HDPE", "Aluminum", "Glass"]:
            if material.lower() in detected_product.lower():
                material_data = ProductIntelligenceService.get_material_data(material)
                if material_data:
                    context["material_data_available"] = True
                    context["material_data"] = material_data
                    break
        
        return context
