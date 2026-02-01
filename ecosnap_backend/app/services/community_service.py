"""
Enhanced Community Service
Real-time leaderboard, neighborhood insights, social proof engine
Note: GCP Firestore integration ready but using in-memory for demo
"""
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from enum import Enum
import random

class ActionType(str, Enum):
    SOLAR_INSTALLED = "solar_installed"
    EV_PURCHASED = "ev_purchased"
    RECYCLED = "recycled"
    TREE_PLANTED = "tree_planted"
    ENERGY_SAVED = "energy_saved"
    CARBON_OFFSET = "carbon_offset"

class CommunityService:
    """Enhanced community features with social proof"""
    
    # In-memory storage (replace with Firestore in production)
    _actions_db = []
    _leaderboard_db = {}
    _achievements_db = {}
    
    # Demo data for realistic leaderboard
    DEMO_USERS = [
        {"id": "u1", "name": "Priya Sharma", "city": "Mumbai", "avatar": "👩"},
        {"id": "u2", "name": "Rahul Verma", "city": "Mumbai", "avatar": "👨"},
        {"id": "u3", "name": "Anjali Patel", "city": "Mumbai", "avatar": "👩"},
        {"id": "u4", "name": "Vikram Singh", "city": "Mumbai", "avatar": "👨"},
        {"id": "u5", "name": "Sneha Reddy", "city": "Mumbai", "avatar": "👩"},
        {"id": "u6", "name": "Arjun Mehta", "city": "Mumbai", "avatar": "👨"},
        {"id": "u7", "name": "Kavya Iyer", "city": "Mumbai", "avatar": "👩"},
        {"id": "u8", "name": "Rohan Gupta", "city": "Mumbai", "avatar": "👨"},
        {"id": "u9", "name": "Divya Nair", "city": "Mumbai", "avatar": "👩"},
        {"id": "u10", "name": "Aditya Kumar", "city": "Mumbai", "avatar": "👨"},
    ]
    
    @classmethod
    def initialize_demo_data(cls):
        """Initialize demo leaderboard data"""
        if cls._leaderboard_db:
            return  # Already initialized
        
        for i, user in enumerate(cls.DEMO_USERS):
            points = random.randint(500, 5000)
            cls._leaderboard_db[user['id']] = {
                "user_id": user['id'],
                "name": user['name'],
                "city": user['city'],
                "avatar": user['avatar'],
                "points": points,
                "rank": i + 1,
                "actions_count": random.randint(5, 50),
                "co2_saved_kg": points * 2.5,
                "streak_days": random.randint(1, 30),
                "tier": cls._calculate_tier(points),
                "badges": cls._generate_badges(points)
            }
        
        # Generate demo actions
        action_types = list(ActionType)
        for _ in range(50):
            user = random.choice(cls.DEMO_USERS)
            action = random.choice(action_types)
            cls._actions_db.append({
                "id": f"action_{len(cls._actions_db)}",
                "user_id": user['id'],
                "user_name": user['name'],
                "action": action.value,
                "impact": cls._calculate_impact(action),
                "timestamp": (datetime.now() - timedelta(hours=random.randint(1, 72))).isoformat(),
                "city": user['city'],
                "verified": True
            })
    
    @classmethod
    def _calculate_tier(cls, points: int) -> str:
        """Calculate user tier based on points"""
        if points >= 5000:
            return "Circular Hero 🏆"
        elif points >= 3000:
            return "Green Champion 🌟"
        elif points >= 1500:
            return "Eco Warrior 🌱"
        elif points >= 500:
            return "Sustainability Starter 🌿"
        else:
            return "Beginner 🌾"
    
    @classmethod
    def _generate_badges(cls, points: int) -> List[str]:
        """Generate achievement badges"""
        badges = []
        if points >= 1000:
            badges.append("Solar Pioneer ☀️")
        if points >= 2000:
            badges.append("Carbon Neutral 🌍")
        if points >= 3000:
            badges.append("Community Leader 👑")
        if points >= 5000:
            badges.append("Sustainability Legend 🎖️")
        return badges
    
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
        """Get leaderboard for a city"""
        cls.initialize_demo_data()
        
        leaderboard = list(cls._leaderboard_db.values())
        
        if city:
            leaderboard = [u for u in leaderboard if u['city'] == city]
        
        # Sort by points
        leaderboard.sort(key=lambda x: x['points'], reverse=True)
        
        # Update ranks
        for i, user in enumerate(leaderboard):
            user['rank'] = i + 1
        
        return leaderboard[:limit]
    
    @classmethod
    def get_live_feed(cls, city: Optional[str] = None, limit: int = 20) -> List[Dict]:
        """Get live community feed"""
        cls.initialize_demo_data()
        
        actions = cls._actions_db.copy()
        
        if city:
            actions = [a for a in actions if a['city'] == city]
        
        # Sort by timestamp (newest first)
        actions.sort(key=lambda x: x['timestamp'], reverse=True)
        
        return actions[:limit]
    
    @classmethod
    def get_neighborhood_insights(cls, city: str, user_location: Optional[Dict] = None) -> Dict:
        """Get neighborhood insights and social proof"""
        cls.initialize_demo_data()
        
        # Filter actions by city
        city_actions = [a for a in cls._actions_db if a['city'] == city]
        
        # Count actions by type
        action_counts = {}
        for action in city_actions:
            action_type = action['action']
            action_counts[action_type] = action_counts.get(action_type, 0) + 1
        
        # Find top action
        top_action = max(action_counts.items(), key=lambda x: x[1]) if action_counts else ("solar_installed", 0)
        
        # Calculate total impact
        total_co2_saved = sum(a['impact']['co2_saved_kg'] for a in city_actions)
        
        # Get recent adopters
        recent_solar = [a for a in city_actions if a['action'] == 'solar_installed'][-5:]
        
        return {
            "city": city,
            "total_actions": len(city_actions),
            "total_co2_saved_kg": round(total_co2_saved, 2),
            "top_action": {
                "type": top_action[0],
                "count": top_action[1],
                "trend": "↑ 45% this month"
            },
            "solar_installations": action_counts.get('solar_installed', 0),
            "ev_purchases": action_counts.get('ev_purchased', 0),
            "social_proof": f"{action_counts.get('solar_installed', 41)} homes in your area went solar",
            "trending": "Solar panels (+45% this month)",
            "recent_adopters": [
                {"name": a['user_name'], "action": a['action'], "days_ago": random.randint(1, 7)}
                for a in recent_solar
            ],
            "neighborhood_rank": random.randint(1, 50),
            "total_neighborhoods": 150
        }
    
    @classmethod
    def post_action(cls, user_id: str, user_name: str, action: ActionType, city: str) -> Dict:
        """Post a new action to the feed"""
        cls.initialize_demo_data()
        
        impact = cls._calculate_impact(action)
        
        new_action = {
            "id": f"action_{len(cls._actions_db)}",
            "user_id": user_id,
            "user_name": user_name,
            "action": action.value,
            "impact": impact,
            "timestamp": datetime.now().isoformat(),
            "city": city,
            "verified": True
        }
        
        cls._actions_db.append(new_action)
        
        # Update leaderboard
        if user_id in cls._leaderboard_db:
            cls._leaderboard_db[user_id]['points'] += impact['points']
            cls._leaderboard_db[user_id]['actions_count'] += 1
            cls._leaderboard_db[user_id]['co2_saved_kg'] += impact['co2_saved_kg']
        else:
            cls._leaderboard_db[user_id] = {
                "user_id": user_id,
                "name": user_name,
                "city": city,
                "avatar": "👤",
                "points": impact['points'],
                "rank": len(cls._leaderboard_db) + 1,
                "actions_count": 1,
                "co2_saved_kg": impact['co2_saved_kg'],
                "streak_days": 1,
                "tier": cls._calculate_tier(impact['points']),
                "badges": []
            }
        
        return {
            "action": new_action,
            "points_earned": impact['points'],
            "new_total_points": cls._leaderboard_db[user_id]['points'],
            "new_rank": cls._calculate_rank(user_id),
            "tier": cls._leaderboard_db[user_id]['tier']
        }
    
    @classmethod
    def _calculate_rank(cls, user_id: str) -> int:
        """Calculate user's current rank"""
        leaderboard = sorted(
            cls._leaderboard_db.values(),
            key=lambda x: x['points'],
            reverse=True
        )
        for i, user in enumerate(leaderboard):
            if user['user_id'] == user_id:
                return i + 1
        return len(leaderboard)
    
    @classmethod
    def get_user_stats(cls, user_id: str) -> Dict:
        """Get user statistics"""
        cls.initialize_demo_data()
        
        if user_id not in cls._leaderboard_db:
            return {
                "user_id": user_id,
                "message": "No activity yet. Start your sustainability journey!"
            }
        
        user = cls._leaderboard_db[user_id]
        user_actions = [a for a in cls._actions_db if a['user_id'] == user_id]
        
        return {
            **user,
            "recent_actions": user_actions[-5:],
            "total_actions": len(user_actions),
            "achievements": cls._achievements_db.get(user_id, [])
        }
    
    @classmethod
    def get_challenges(cls, city: str) -> List[Dict]:
        """Get active community challenges"""
        return [
            {
                "id": "challenge_1",
                "name": "Solar Sprint",
                "description": "100 homes go solar in Mumbai this month",
                "progress": 67,
                "target": 100,
                "participants": 234,
                "reward": "500 bonus points",
                "ends_in": "12 days"
            },
            {
                "id": "challenge_2",
                "name": "Zero Waste Week",
                "description": "Recycle 1000kg of waste",
                "progress": 450,
                "target": 1000,
                "participants": 89,
                "reward": "300 bonus points",
                "ends_in": "5 days"
            },
            {
                "id": "challenge_3",
                "name": "Green Commute",
                "description": "50 EV purchases this quarter",
                "progress": 23,
                "target": 50,
                "participants": 156,
                "reward": "1000 bonus points",
                "ends_in": "45 days"
            }
        ]
