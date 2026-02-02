"""
Enhanced Geospatial Intelligence Service
Integrates multiple open-source geospatial data sources for stronger analysis
"""
import requests
from typing import Optional, Dict, Any
import math

class GeospatialService:
    """Open-source geospatial data integration"""
    
    @staticmethod
    def get_elevation(lat: float, lon: float) -> Optional[float]:
        """
        Get elevation data from Open-Elevation API (free, open-source)
        Useful for solar panel tilt calculations and drainage analysis
        """
        try:
            url = "https://api.open-elevation.com/api/v1/lookup"
            params = {"locations": f"{lat},{lon}"}
            response = requests.get(url, params=params, timeout=10)
            if response.status_code == 200:
                data = response.json()
                return data['results'][0]['elevation']
        except Exception as e:
            print(f"Elevation API Error: {e}")
            return None
    
    @staticmethod
    def get_nasa_solar_data(lat: float, lon: float) -> Optional[Dict[str, Any]]:
        """
        Get solar irradiance data from NASA POWER API (free, open-source)
        Provides accurate solar radiation data for solar panel calculations
        """
        try:
            url = "https://power.larc.nasa.gov/api/temporal/daily/point"
            params = {
                "parameters": "ALLSKY_SFC_SW_DWN",  # Solar irradiance
                "community": "RE",
                "longitude": lon,
                "latitude": lat,
                "start": "20230101",
                "end": "20231231",
                "format": "JSON"
            }
            response = requests.get(url, params=params, timeout=15)
            if response.status_code == 200:
                data = response.json()
                # Calculate average annual irradiance
                values = list(data['properties']['parameter']['ALLSKY_SFC_SW_DWN'].values())
                avg_irradiance = sum(values) / len(values) if values else 5.0
                
                return {
                    "avg_daily_irradiance_kwh_m2": round(avg_irradiance, 2),
                    "annual_irradiance_kwh_m2": round(avg_irradiance * 365, 2),
                    "source": "NASA POWER"
                }
        except Exception as e:
            print(f"NASA POWER API Error: {e}")
            return None
    
    @staticmethod
    def get_osm_building_data(lat: float, lon: float, radius: int = 50) -> Optional[Dict[str, Any]]:
        """
        Get building data from OpenStreetMap (free, open-source)
        Provides building footprints, heights, materials
        """
        try:
            # Overpass API query for buildings near location
            overpass_url = "https://overpass-api.de/api/interpreter"
            query = f"""
            [out:json];
            (
              way["building"](around:{radius},{lat},{lon});
              relation["building"](around:{radius},{lat},{lon});
            );
            out body;
            >;
            out skel qt;
            """
            
            response = requests.post(overpass_url, data={"data": query}, timeout=15)
            if response.status_code == 200:
                data = response.json()
                buildings = []
                
                for element in data.get('elements', []):
                    if element.get('type') == 'way' and 'tags' in element:
                        tags = element['tags']
                        buildings.append({
                            "building_type": tags.get('building', 'yes'),
                            "height": tags.get('height'),
                            "levels": tags.get('building:levels'),
                            "material": tags.get('building:material'),
                            "roof_shape": tags.get('roof:shape'),
                            "roof_material": tags.get('roof:material')
                        })
                
                return {
                    "buildings_found": len(buildings),
                    "nearest_building": buildings[0] if buildings else None,
                    "source": "OpenStreetMap"
                }
        except Exception as e:
            print(f"OSM API Error: {e}")
            return None
    
    @staticmethod
    def get_air_quality(lat: float, lon: float) -> Optional[Dict[str, Any]]:
        """
        Get air quality data from OpenAQ (free, open-source)
        Useful for solar panel efficiency calculations (pollution affects output)
        """
        try:
            url = "https://api.openaq.org/v2/latest"
            params = {
                "coordinates": f"{lat},{lon}",
                "radius": 25000,  # 25km radius
                "limit": 1
            }
            response = requests.get(url, params=params, timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get('results'):
                    measurements = data['results'][0].get('measurements', [])
                    pm25 = next((m['value'] for m in measurements if m['parameter'] == 'pm25'), None)
                    
                    return {
                        "pm25": pm25,
                        "air_quality_impact": "High pollution reduces solar efficiency by 5-15%",
                        "source": "OpenAQ"
                    }
        except Exception as e:
            print(f"Air Quality API Error: {e}")
            return None
    
    @staticmethod
    def calculate_sun_position(lat: float, lon: float, month: int = 6) -> Dict[str, Any]:
        """
        Calculate sun position and optimal panel angles
        Uses astronomical calculations (no API needed)
        """
        # Optimal tilt angle ≈ latitude for year-round performance
        optimal_tilt = abs(lat)
        
        # Seasonal adjustments
        summer_tilt = max(abs(lat) - 15, 0)
        winter_tilt = min(abs(lat) + 15, 90)
        
        # Azimuth (direction): South in Northern hemisphere, North in Southern
        optimal_azimuth = 180 if lat > 0 else 0
        
        return {
            "optimal_tilt_year_round": round(optimal_tilt, 1),
            "optimal_tilt_summer": round(summer_tilt, 1),
            "optimal_tilt_winter": round(winter_tilt, 1),
            "optimal_azimuth": optimal_azimuth,
            "hemisphere": "Northern" if lat > 0 else "Southern"
        }
    
    @staticmethod
    def get_climate_zone(lat: float, lon: float) -> str:
        """
        Determine climate zone for HVAC sizing
        Based on latitude and elevation
        """
        abs_lat = abs(lat)
        
        if abs_lat < 23.5:
            return "Tropical"
        elif abs_lat < 35:
            return "Subtropical"
        elif abs_lat < 50:
            return "Temperate"
        elif abs_lat < 66.5:
            return "Cold"
        else:
            return "Polar"
    
    @staticmethod
    def get_enhanced_geospatial_context(lat: float, lon: float) -> Dict[str, Any]:
        """
        Combine all geospatial data sources
        """
        context = {
            "location": {"lat": lat, "lon": lon},
            "data_sources": []
        }
        
        # Elevation
        elevation = GeospatialService.get_elevation(lat, lon)
        if elevation is not None:
            context["elevation_m"] = elevation
            context["data_sources"].append("Open-Elevation")
        
        # NASA Solar Data
        nasa_solar = GeospatialService.get_nasa_solar_data(lat, lon)
        if nasa_solar:
            context["nasa_solar"] = nasa_solar
            context["data_sources"].append("NASA POWER")
        
        # OpenStreetMap Buildings
        osm_buildings = GeospatialService.get_osm_building_data(lat, lon)
        if osm_buildings:
            context["osm_buildings"] = osm_buildings
            context["data_sources"].append("OpenStreetMap")
        
        # Air Quality
        air_quality = GeospatialService.get_air_quality(lat, lon)
        if air_quality:
            context["air_quality"] = air_quality
            context["data_sources"].append("OpenAQ")
        
        # Sun Position Calculations
        sun_position = GeospatialService.calculate_sun_position(lat, lon)
        context["sun_position"] = sun_position
        context["data_sources"].append("Astronomical Calculations")
        
        # Climate Zone
        climate_zone = GeospatialService.get_climate_zone(lat, lon)
        context["climate_zone"] = climate_zone
        
        return context
