import asyncio
from app.services.community_service import CommunityService
from app.services.marketplace_service import MarketplaceService
from app.services.subsidy_database import SubsidyDatabase
from app.services.carbon_credit_service import CCTSEngine as CarbonCreditService

def test_community():
    print("\n--- Testing CommunityService ---")
    try:
        feed = CommunityService.get_live_feed(limit=2)
        print(f"Feed Items: {len(feed)}")
        if feed and len(feed) > 0:
            print(f"Sample Action: {feed[0].get('action')}")
        else:
            print("Feed Empty (Expected if DB empty and seed failed, or init in progress)")
    except Exception as e:
        print(f"Community Error: {e}")

def test_marketplace():
    print("\n--- Testing MarketplaceService ---")
    try:
        products = MarketplaceService.get_all_products()
        print(f"Products Found: {len(products)}")
        if products and len(products) > 0:
            print(f"Sample Product: {products[0].get('name')}")
    except Exception as e:
        print(f"Marketplace Error: {e}")

def test_subsidy():
    print("\n--- Testing SubsidyDatabase ---")
    try:
        schemes = SubsidyDatabase.get_all_schemes()
        print(f"Schemes Found: {len(schemes)}")
    except Exception as e:
        print(f"Subsidy Error: {e}")

def test_carbon():
    print("\n--- Testing CarbonCreditService (CCTSEngine) ---")
    try:
        price = CarbonCreditService.get_current_ccc_price()
        print(f"CCC Price: {price}")
    except Exception as e:
        print(f"Carbon Error: {e}")

if __name__ == "__main__":
    print("Starting Verification...")
    test_community()
    test_marketplace()
    test_subsidy()
    test_carbon()
    print("\nVerification Complete.")
