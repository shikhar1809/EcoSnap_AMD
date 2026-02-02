from typing import Dict, List, Optional
from datetime import datetime, timedelta
from enum import Enum
import random
from app.database import supabase

class ActionType(str, Enum):
    SOLAR_INSTALLED = "solar_installed"
    EV_PURCHASED = "ev_purchased"
    RECYCLED = "recycled"
    TREE_PLANTED = "tree_planted"
    ENERGY_SAVED = "energy_saved"
    CARBON_OFFSET = "carbon_offset"

class CommunityService:
    """
    Real-time Community Service backed by Supabase.
    """
    
    @classmethod
    def _ensure_initialized(cls):
        """Check if DB has data, if not, seed it."""
        try:
            res = supabase.table("actions").select("count", count="exact").execute()
            if res.count == 0:
                print("Seeding Community DB...")
                cls._seed_db()
        except Exception as e:
            print(f"DB Init Error (Table likely missing): {e}")

    @classmethod
    def _seed_db(cls):
        """Seed initial real-world like data into Supabase"""
        demo_users = [
            {"id": "u1", "name": "Priya Sharma", "city": "Mumbai", "avatar_url": "https://i.pravatar.cc/150?u=1"},
            {"id": "u2", "name": "Rahul Verma", "city": "Delhi", "avatar_url": "https://i.pravatar.cc/150?u=2"},
            {"id": "u3", "name": "Anjali Patel", "city": "Bangalore", "avatar_url": "https://i.pravatar.cc/150?u=3"},
            {"id": "u4", "name": "Vikram Singh", "city": "Jaipur", "avatar_url": "https://i.pravatar.cc/150?u=4"},
            {"id": "u5", "name": "Sneha Reddy", "city": "Hyderabad", "avatar_url": "https://i.pravatar.cc/150?u=5"},
        ]
        
        # Seed Users
        for user in demo_users:
            try:
                supabase.table("users").upsert(user).execute()
            except: pass

        # Seed Actions
        actions = []
        action_types = list(ActionType)
        for _ in range(20):
            user = random.choice(demo_users)
            action = random.choice(action_types)
            impact = cls._calculate_impact(action)
            
            actions.append({
                "user_id": user['id'],
                "user_name": user['name'],
                "action": action.value,
                "impact": impact,
                "city": user['city'],
                "created_at": (datetime.now() - timedelta(hours=random.randint(1, 120))).isoformat(),
                "verified": True
            })
        
        try:
            supabase.table("actions").insert(actions).execute()
        except Exception as e:
            print(f"Seeding Actions Error: {e}")

    @classmethod
    def _calculate_impact(cls, action: ActionType) -> Dict:
        """Calculate impact of an action"""
        impacts = {
            ActionType.SOLAR_INSTALLED: {"co2_saved_kg": 2800, "points": 1000},
            ActionType.EV_PURCHASED: {"co2_saved_kg": 1500, "points": 800},
            ActionType.RECYCLED: {"co2_saved_kg": 50, "points": 50},
            ActionType.TREE_PLANTED: {"co2_saved_kg": 20, "points": 30},
            ActionType.ENERGY_SAVED: {"co2_saved_kg": 100, "points": 100},
            ActionType.CARBON_OFFSET: {"co2_saved_kg": 500, "points": 200},
        }
        return impacts.get(action, {"co2_saved_kg": 10, "points": 10})

    @classmethod
    def get_leaderboard(cls, city: Optional[str] = None, limit: int = 10) -> List[Dict]:
        """Get real-time leaderboard from Supabase"""
        cls._ensure_initialized()
        
        try:
            # We aggregate points from the actions table for "Real" calculation
            # Or use a materialized view. For simplicity, we fetch top users.
            # Assuming 'users' table has 'points' column updated via triggers or we calculate on fly.
            # Simplified: Fetch users sorted by points if column exists, else mock calc from actions
            
            query = supabase.table("leaderboard_view").select("*").order("points", desc=True)
            if city:
                query = query.eq("city", city)
            
            res = query.limit(limit).execute()
            
            if not res.data:
                 # Fallback if view doesn't exist (likely in this setup), calculate from actions
                 all_actions = supabase.table("actions").select("*").execute().data
                 user_points = {}
                 for a in all_actions:
                     uid = a.get('user_id')
                     if isinstance(a.get('impact'), dict):
                         pts = a['impact'].get('points', 0)
                     else:
                         pts = 0
                     
                     if uid not in user_points:
                         user_points[uid] = {"user_id": uid, "name": a.get('user_name'), "points": 0, "city": a.get('city')}
                     user_points[uid]['points'] += pts
                 
                 sorted_users = sorted(user_points.values(), key=lambda x: x['points'], reverse=True)
                 for i, u in enumerate(sorted_users):
                     u['rank'] = i + 1
                     u['tier'] = cls._calculate_tier(u['points'])
                     u['badges'] = cls._generate_badges(u['points'])
                 
                 return sorted_users[:limit]

            return res.data
        except Exception as e:
            print(f"Leaderboard Error: {e}")
            return []

    @classmethod
    def get_live_feed(cls, city: Optional[str] = None, limit: int = 20) -> List[Dict]:
        """Get live feed from Supabase"""
        cls._ensure_initialized()
        try:
            query = supabase.table("actions").select("*").order("created_at", desc=True)
            if city:
                query = query.eq("city", city)
            
            res = query.limit(limit).execute()
            return res.data
        except Exception as e:
            print(f"Feed Error: {e}")
            return []

    @classmethod
    def post_action(cls, user_id: str, user_name: str, action: ActionType, city: str) -> Dict:
        """Post action to Supabase"""
        impact = cls._calculate_impact(action)
        
        new_action = {
            "user_id": user_id,
            "user_name": user_name,
            "action": action.value,
            "impact": impact,
            "timestamp": datetime.now().isoformat(), # Some legacy fields kept for frontend compat
            "created_at": datetime.now().isoformat(),
            "city": city,
            "verified": True
        }
        
        try:
            res = supabase.table("actions").insert(new_action).execute()
            return {"success": True, "action": res.data[0] if res.data else new_action}
        except Exception as e:
            print(f"Post Action Error: {e}")
            return {"error": str(e)}

    @classmethod
    def get_neighborhood_insights(cls, city: str) -> Dict:
        """Real stats from DB"""
        cls._ensure_initialized()
        try:
            res = supabase.table("actions").select("*").eq("city", city).execute()
            actions = res.data
            
            total = len(actions)
            solar = sum(1 for a in actions if a['action'] == 'solar_installed')
            return {
                "city": city,
                "total_actions": total,
                "solar_installations": solar,
                "social_proof": f"{solar} homes in {city} went solar recently."
            }
        except:
            return {"city": city, "error": "Could not fetch insights"}

    # Helpers
    @staticmethod
    def _calculate_tier(points):
        if points > 5000: return "Legend"
        elif points > 1000: return "Pro"
        else: return "Rookie"

    @staticmethod
    def _generate_badges(points):
        badges = []
        if points > 100: badges.append("First Step")
        if points > 1000: badges.append("Eco Warrior")
        return badges

    @classmethod
    def get_challenges(cls, city: str) -> List[Dict]:
        """
        Challenges are currently global configuration, 
        but we fetch progress from Real DB.
        """
        # In a full Real app, challenges would be a table.
        # Here we mock the CONFIG but calculate REAL PROGRESS.
        
        # Real calculation: Count solar installs in DB
        try:
            res = supabase.table("actions").select("count", count="exact").eq("action", "solar_installed").execute()
            solar_count = res.count
        except:
            solar_count = 0

        return [
            {
                "id": "c1", 
                "name": "Solar Sprint", 
                "target": 100, 
                "progress": solar_count, 
                "description": "Reach 100 Solar Installs",
                "ends_in": "30 days"
            }
        ]

    # Legacy method stubs if needed
    @classmethod
    def get_user_stats(cls, user_id: str) -> Dict:
        try:
            res = supabase.table("actions").select("*").eq("user_id", user_id).execute()
            actions = res.data
            return {"user_id": user_id, "total_actions": len(actions), "recent_actions": actions[:5]}
        except:
            return {}
