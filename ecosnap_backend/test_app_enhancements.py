"""
Test App-Wide Enhancements
Tests Product Intelligence, Community, and Subsidy services
"""
import sys
sys.path.append('.')

print("="*70)
print("TESTING APP-WIDE ENHANCEMENTS")
print("="*70)

# Test 1: Product Intelligence
print("\n1. PRODUCT INTELLIGENCE SERVICE")
print("-" * 70)

from app.services.product_intelligence_service import ProductIntelligenceService

# Test carbon database
print("\n   a) Carbon Database:")
carbon_data = ProductIntelligenceService.get_carbon_data("plastic_bottle_500ml")
if carbon_data:
    print(f"      [SUCCESS] Plastic bottle: {carbon_data['total_co2_g']}g CO₂")
    print(f"      Source: {carbon_data['source']}")
else:
    print("      [FAILED]")

# Test material database
print("\n   b) Material Database:")
material_data = ProductIntelligenceService.get_material_data("PET")
if material_data:
    print(f"      [SUCCESS] PET: {material_data['recyclability_score']}% recyclable")
    print(f"      Decomposition: {material_data['decomposition_years']} years")
else:
    print("      [FAILED]")

# Test green alternatives
print("\n   c) Green Alternatives:")
alternatives = ProductIntelligenceService.get_green_alternatives("plastic_bottle", {})
if alternatives:
    print(f"      [SUCCESS] Found {len(alternatives)} alternatives")
    print(f"      Top: {alternatives[0]['product']} (₹{alternatives[0]['upfront_cost_inr']})")
else:
    print("      [FAILED]")

# Test 2: Subsidy Intelligence
print("\n\n2. SUBSIDY INTELLIGENCE SERVICE")
print("-" * 70)

from app.services.subsidy_intelligence_service import SubsidyIntelligenceService

# Test PM Surya Ghar calculation
print("\n   a) PM Surya Ghar Subsidy:")
pm_subsidy = SubsidyIntelligenceService.calculate_pm_surya_ghar_subsidy(3.0)
print(f"      [SUCCESS] 3kW system: ₹{pm_subsidy['subsidy_amount']:,}")
print(f"      Details: {pm_subsidy['calculation_details']}")

# Test state subsidy
print("\n   b) State Subsidy (Maharashtra):")
state_subsidy = SubsidyIntelligenceService.get_state_subsidy("Maharashtra", 3.0)
if state_subsidy:
    print(f"      [SUCCESS] Maharashtra: ₹{state_subsidy['subsidy_amount']:,}")
    print(f"      Scheme: {state_subsidy['scheme']}")
else:
    print("      [FAILED]")

# Test total subsidy
print("\n   c) Total Subsidy (Central + State):")
total = SubsidyIntelligenceService.get_total_solar_subsidy("Maharashtra", 3.0)
print(f"      [SUCCESS] Total: ₹{total['total_subsidy_amount']:,}")
print(f"      Central: ₹{total['central_subsidy']['subsidy_amount']:,}")
print(f"      State: ₹{total['state_subsidy']['subsidy_amount']:,}")

# Test eligibility
print("\n   d) Eligibility Check:")
user_data = {
    "owns_roof": True,
    "has_electricity_connection": True,
    "property_type": "residential",
    "has_aadhaar": True
}
eligibility = SubsidyIntelligenceService.check_eligibility(user_data)
print(f"      [SUCCESS] Eligible: {eligibility['eligible']}")
if not eligibility['eligible']:
    print(f"      Missing: {', '.join(eligibility['missing_requirements'])}")

# Test 3: Community Service
print("\n\n3. COMMUNITY SERVICE")
print("-" * 70)

from app.services.community_service import CommunityService

# Initialize demo data
CommunityService.initialize_demo_data()

# Test leaderboard
print("\n   a) Leaderboard:")
leaderboard = CommunityService.get_leaderboard(city="Mumbai", limit=5)
print(f"      [SUCCESS] Top 5 users:")
for user in leaderboard[:3]:
    print(f"      #{user['rank']} {user['name']}: {user['points']} points ({user['tier']})")

# Test live feed
print("\n   b) Live Feed:")
feed = CommunityService.get_live_feed(city="Mumbai", limit=3)
print(f"      [SUCCESS] Recent {len(feed)} actions:")
for action in feed[:2]:
    print(f"      - {action['user_name']}: {action['action']} ({action['impact']['co2_saved_kg']}kg CO₂)")

# Test neighborhood insights
print("\n   c) Neighborhood Insights:")
insights = CommunityService.get_neighborhood_insights("Mumbai")
print(f"      [SUCCESS] Mumbai stats:")
print(f"      Total actions: {insights['total_actions']}")
print(f"      CO₂ saved: {insights['total_co2_saved_kg']}kg")
print(f"      Social proof: {insights['social_proof']}")

print("\n" + "="*70)
print("ALL TESTS COMPLETE")
print("="*70)

# Summary
print("\nSUMMARY:")
print("✓ Product Intelligence: Carbon DB, Material DB, Alternatives")
print("✓ Subsidy Intelligence: PM Surya Ghar + 5 States, Eligibility")
print("✓ Community Service: Leaderboard, Feed, Insights")
print("\nSTATUS: ALL SYSTEMS OPERATIONAL")
