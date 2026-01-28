# EcoSnap - Complete Product Requirements Document (PRD)

**Version:** 1.0  
**Last Updated:** January 27, 2026  
**Status:** MVP Ready for Development  
**Target Launch:** April 2026 (AMD Slingshot)

---

## 📋 Executive Summary

**EcoSnap** is an AI-powered mobile application that analyzes users' living spaces via computer vision, provides personalized green upgrade recommendations with exact ROI calculations, and gamifies sustainable behavior change through points, leaderboards, and real monetary rewards.

**Core Value:** Transform "going green" from abstract environmental goal into a profitable personal investment, delivered in 2 minutes, visualized in 3D, and tracked in real-time.

**Target Market:** Urban India (18-45 years, middle-class, tech-savvy, cost-conscious)

**Revenue Model:** Freemium subscriptions + Affiliate commissions + Contractor partnerships + Enterprise ESG reporting

**MVP Timeline:** 12 weeks (hackathon scope)  
**Full Product Timeline:** 6 months (3D + AR features)

---

## 🎯 Product Vision

### Mission Statement
*"Empower Indians to reduce their carbon footprint while increasing personal wealth through AI-driven home optimization and gamified behavior change."*

### Key Differentiators
1. **AI-Powered Room Analysis** - YOLOv8 + Gemini Vision instantly identifies appliances and calculates CO₂
2. **Exact ROI Calculation** - Shows payback period in years, not vague "save energy" tips
3. **3D Thermal Visualization** - Users see heat maps and optimization scenarios in 3D (Phase 2)
4. **Real Money Incentives** - Points = ₹1 (redeemable), not gamified vanity points
5. **End-to-End Marketplace** - Analyze → Quote → Install → Track earnings
6. **India-Native Design** - Repair culture, local appliance brands, government subsidies built-in

### Success Criteria (Year 1)
- 8,000 active users
- 40%+ 30-day retention
- ₹45 lakhs revenue
- 100,000 kg CO₂ reduction (cumulative)
- 20%+ habit change rate (users take action)

---

## 👥 User Personas

### Persona 1: Cost-Conscious Priya (28, IT Professional)
- **Income:** ₹60-80K/month
- **Pain Points:** Rising electricity bills (₹8-10K/month), poor room comfort in summer
- **Motivation:** Save money AND help planet (50/50 split)
- **App Behavior:** Daily engagement, shares on social media, likely to upgrade to premium
- **Value:** "Show me exact payback periods and monthly savings"

### Persona 2: Eco-Conscious Rajesh (32, Startup Founder)
- **Income:** ₹100K+/month
- **Pain Points:** ESG reporting for company, personal carbon guilt
- **Motivation:** Planet first, then financial optimization
- **App Behavior:** Weekly check-in, interested in enterprise features
- **Value:** "Give me detailed CO₂ reduction metrics and corporate reporting"

### Persona 3: Competitive Ankit (24, College Student)
- **Income:** ₹15-25K/month (limited budget)
- **Pain Points:** Wants to game social status, save on dorm energy costs
- **Motivation:** Leaderboard ranking, badges, community recognition
- **App Behavior:** Highly engaged with gamification, daily challenges
- **Value:** "Make green actions competitive and visible on social media"

### Persona 4: Budget-Conscious Zara (35, Homemaker)
- **Income:** ₹30-40K household
- **Pain Points:** Managing household budget, reducing expenses
- **Motivation:** Maximize household savings
- **App Behavior:** Moderate engagement, practical about investments
- **Value:** "Show me cost-benefit of every upgrade before I invest"

---

## 📱 Product Features (MVP Phase 1 - Hackathon)

### Feature 1: Room Analysis (Photo Upload + AI Detection)

**Description:** User uploads 1-3 room photos → AI reconstructs 3D space and detects appliances

**User Flow:**
```
1. Tap "Scan Room" button
2. Grant camera permission
3. Take 3 photos (different angles)
4. AI processing (5-10 seconds)
5. Results: Appliance list + CO₂ calculation + Score
```

**Technical Implementation:**
- **Frontend:** React Native (iOS/Android)
- **Backend:** FastAPI + Google Cloud Run
- **CV Model:** YOLOv8 (pre-trained on appliance dataset)
- **Processing:** YOLO detects objects → Gemini Vision estimates specs → Backend calculates CO₂

**Output:**
```json
{
  "room_id": "uuid-123",
  "analysis_date": "2026-01-27",
  "appliances": [
    {
      "type": "AC",
      "detected_brand": "LG",
      "estimated_power_watts": 1500,
      "estimated_age_years": 8,
      "annual_co2_kg": 450,
      "replacement_priority": "HIGH",
      "estimated_replacement_cost": 35000
    },
    {
      "type": "Refrigerator",
      "detected_brand": "Godrej",
      "estimated_power_watts": 600,
      "estimated_age_years": 8,
      "annual_co2_kg": 105,
      "replacement_priority": "MEDIUM",
      "estimated_replacement_cost": 25000
    }
  ],
  "total_annual_co2_kg": 679,
  "efficiency_score": 45,
  "room_characteristics": {
    "estimated_size_sqft": 150,
    "natural_light_score": 65,
    "insulation_quality": "poor",
    "ventilation": "good"
  }
}
```

**Error Handling:**
- If detection confidence <70%, show "confidence score" to user
- Fallback to average power for unrecognized appliances
- Allow manual override (user provides specs)

**Dependencies:**
- YOLOv8 nano model (3.2MB, optimized for mobile inference)
- Google Gemini Vision API
- Cloud Storage for image temporary caching
- Vertex AI for batch processing (optional, Phase 2)

---

### Feature 2: CO₂ Score & Efficiency Rating

**Description:** Dynamic carbon rating (0-100) based on appliance efficiency

**Calculation Logic:**
```python
def calculate_co2_score(appliances: List[Appliance]) -> int:
    """
    Score = 100 - (current_co2 / max_co2_for_room_type * 100)
    Adjustments:
    - Solar installed: +30 points
    - All 5-star appliances: +20 points
    - Natural light usage: +5 points
    - Energy monitoring: +3 points
    """
    
    # Baseline
    current_co2 = sum(a.annual_co2 for a in appliances)
    
    # Room type baseline (1BHK = 650 kg, 2BHK = 950 kg)
    baseline_co2 = get_baseline_for_room_type(appliances)
    
    # Calculate score
    score = 100 - (current_co2 / baseline_co2 * 100)
    score = max(0, min(100, score))  # Clamp 0-100
    
    # Apply adjustments
    if solar_installed: score += 30
    if all_5star_appliances: score += 20
    if solar_generated > consumed: score = 100  # Net positive
    
    return round(score)
```

**UI Display:**
```
┌────────────────────────────┐
│  Your Efficiency Score     │
│  58/100 🟡 Fair            │
│                            │
│  Annual CO₂: 395 kg        │
│  vs Indian avg: 450 kg     │
│  Status: ✅ Below average  │
│                            │
│  Top 3 Improvements:       │
│  1. AC: +15 points         │
│  2. Lights: +8 points      │
│  3. Insulation: +12 points │
│                            │
└────────────────────────────┘
```

**Real-Time Updates:**
- Score updates immediately when user logs upgrade
- Push notification: "⬆️ +15 points! AC upgrade unlocked badge"
- Monthly trend chart showing score progression

---

### Feature 3: Recommendations Engine

**Description:** Ranked list of green upgrades sorted by ROI

**Algorithm:**
```python
def rank_recommendations(appliances: List[Appliance]) -> List[Recommendation]:
    """
    Ranking logic:
    1. Calculate savings/cost ratio for each upgrade
    2. Filter by payback <10 years (realistic threshold)
    3. Sort by: payback_years, then co2_reduction, then cost
    4. Group by tier (Quick wins, Medium-term, Long-term)
    """
    
    recommendations = []
    
    for appliance in appliances:
        if should_replace(appliance):
            upgrade = get_best_replacement(appliance)
            payback = upgrade['cost'] / upgrade['annual_savings']
            
            if payback < 10:
                recommendations.append({
                    'appliance': appliance.type,
                    'action': 'Replace',
                    'cost': upgrade['cost'],
                    'annual_savings': upgrade['annual_savings'],
                    'payback_years': payback,
                    'co2_reduction': upgrade['co2_reduction'],
                    'priority': get_priority(payback, co2_reduction),
                    'options': get_flipkart_products(upgrade)
                })
    
    return sorted(recommendations, key=lambda x: x['priority'])
```

**Output Display (Tier-Based):**
```
TIER 1: QUICK WINS (Payback <1 year)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ Replace Lights with LEDs
   💰 Cost: ₹500
   💵 Annual savings: ₹1,920
   ⏱️ Payback: 3.1 months ⚡
   🌍 CO₂ reduction: 180 kg/year
   [Ask AI] [Shop on Flipkart]

2️⃣ Install Smart Power Strips
   💰 Cost: ₹2,000
   💵 Annual savings: ₹1,800
   ⏱️ Payback: 13.3 months ✅
   🌍 CO₂ reduction: 150 kg/year

TIER 2: MEDIUM-TERM (1-5 years)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3️⃣ Replace AC (5-star inverter)
   💰 Cost: ₹35,000 (- ₹8,700 scrap)
   💵 Annual savings: ₹4,800
   ⏱️ Payback: 5.8 years
   🌍 CO₂ reduction: 400 kg/year
   [Get Quotes] [Finance Options]

4️⃣ Double-Glazed Windows
   💰 Cost: ₹10,000
   💵 Annual savings: ₹3,120
   ⏱️ Payback: 3.2 years ✅
   🌍 CO₂ reduction: 150 kg/year

TIER 3: LONG-TERM INVESTMENTS (5+ years)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5️⃣ Solar System (2.5kW)
   💰 Cost: ₹80,000 (- ₹30,000 subsidy)
   💵 Annual savings: ₹40,000
   ⏱️ Payback: 1.3 years 🚀
   🌍 CO₂ reduction: 450 kg/year
   [Apply for Subsidy] [Get Quotes]
```

**Data Source:**
- Power consumption from appliance specs database
- Electricity rates from state (default ₹8/unit for UP)
- CO₂ conversion: 0.7 kg CO₂ per kWh (national average)
- Replacement prices from Flipkart API (cached hourly)
- Government subsidies database (manual updates)

---

### Feature 4: AI Chat Advisor (Gemini Integration)

**Description:** Conversational AI that answers sustainability questions about user's specific room

**System Prompt:**
```
You are EcoSnap, an AI sustainability advisor helping Indian users reduce carbon footprints.

Your expertise:
1. Analyze user's room data (appliances, CO₂ score, efficiency)
2. Provide repair vs replacement recommendations
3. Calculate costs, payback periods, CO₂ savings
4. Guide to responsible e-waste disposal
5. Suggest energy-efficient upgrades
6. Find local repair/contractor services

Communication style:
- Practical, action-oriented
- Use Indian context (₹ currency, local brands, repair culture)
- Reference relatable metrics (trees planted, km driven less)
- Be India-specific (mention UJALA scheme, BEE ratings, etc.)

Example response:
"Your 8-year AC costs ₹270/month in electricity. A 5-star AC costs ₹150/month.
Payback: 24 months. But repair (₹8000) gives 2-3 more years. I found 3 local technicians nearby - want their contacts?"
```

**User Interactions:**
1. **Repair vs Replace Queries**
   - User: "Is my 8-year AC worth replacing?"
   - AI: [Analyzes AC specs] → Shows: cost, savings, payback, local repair options

2. **Upgrade Recommendations**
   - User: "What's the best AC to buy?"
   - AI: [Recommends top 5 5-star ACs] → Shows: prices, efficiency, payback, affiliate links

3. **Scrap Value Guidance**
   - User: "How do I dispose my old AC?"
   - AI: [Calculates scrap value] → Shows: e-waste facilities, pickup options, payment methods

4. **Government Subsidy Info**
   - User: "Can I get subsidy for solar?"
   - AI: [Checks eligibility] → Shows: PM Surya Ghar scheme, ₹30K subsidy, application process

**API Integration:**
```python
@router.post("/api/chat/ask")
async def chat_with_advisor(request: ChatRequest):
    """
    request.message: User query
    request.room_data: Current appliance data
    request.user_id: For personalization
    """
    
    # Add context
    context = format_room_context(request.room_data)
    
    # Call Gemini API
    response = gemini_client.generate_content(
        [
            system_prompt,
            context,
            f"User: {request.message}"
        ]
    )
    
    return {
        "response": response.text,
        "suggestions": extract_actionable_items(response.text),
        "local_services": search_nearby_services(request.room_data)
    }
```

**Error Handling:**
- If Gemini API fails, show: "Our advisor is busy. Try again in 30 seconds"
- If response is vague, add: "[Ask a specific question like 'repair cost for AC?']"
- Rate limit: 10 chats/hour per user (prevent API overload)

---

### Feature 5: Gamification System (Points + Leaderboards + Badges)

#### 5a. Points System
```
Core Rule: 10 points = ₹1 (redeemable to cash/vouchers)

Daily Actions (Recurring):
├─ Unplug 3 devices: 10 points (₹1)
├─ Turn off AC 1 hour: 15 points (₹1.50)
├─ Use natural light 8am-5pm: 20 points (₹2)
├─ Chat with AI: 25 points (₹2.50)
├─ Log energy reading: 30 points (₹3)
└─ Max: 100 points/day without multiplier

Multipliers:
├─ 7-day streak: 1.5x
├─ 14-day streak: 1.75x
├─ 30-day streak: 2x
└─ Special badges (Solar Master): 2x permanently

One-Time Actions:
├─ First photo: 50 points
├─ Profile setup: 25 points
├─ Link Flipkart: 30 points
└─ Share profile: 100 points (max 3/week)

Purchase Actions:
├─ LED bulbs (₹500): 100 points
├─ 5-star AC (₹35K): 1000 points
├─ Solar system (₹80K): 2000 points
└─ E-waste disposal: 500 points

Monthly Leaderboard Prizes:
├─ 1st place: ₹5,000
├─ 2nd place: ₹3,000
├─ 3rd place: ₹1,000
├─ 4-10th: ₹500 each
└─ Random raffle (all users): ₹20K total
```

**Database Schema:**
```sql
CREATE TABLE user_points (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    action_type VARCHAR(50),  -- "daily_action", "purchase", "challenge"
    points_earned INT,
    multiplier FLOAT DEFAULT 1.0,
    final_points INT,
    created_at TIMESTAMP,
    verified BOOLEAN DEFAULT true,
    verification_proof TEXT  -- e.g., photo URL for e-waste
);

CREATE TABLE user_streaks (
    user_id UUID PRIMARY KEY,
    current_streak_days INT,
    max_streak_days INT,
    last_action_date DATE,
    multiplier_active FLOAT DEFAULT 1.0
);
```

#### 5b. Leaderboards
```python
@router.get("/api/leaderboard/monthly")
async def get_monthly_leaderboard(city: str = "Lucknow", limit: int = 100):
    """Returns top 100 users by points for the month"""
    
    return await db.query("""
        SELECT 
            u.name,
            u.profile_pic,
            u.city,
            SUM(up.final_points) as total_points,
            u.co2_score,
            u.active_badges
        FROM user_points up
        JOIN users u ON up.user_id = u.id
        WHERE u.city = ? 
            AND DATE_PART('month', up.created_at) = CURRENT_MONTH
        GROUP BY u.id
        ORDER BY total_points DESC
        LIMIT ?
    """, (city, limit))
```

**Leaderboard Types:**
1. **City Leaderboard** (Points this month, Lucknow)
2. **CO₂ Score Leaderboard** (Efficiency ranking, India)
3. **Challenge Leaderboard** (Weekly, rotating challenges)
4. **Friends Leaderboard** (Optional, social competition)

**UI Display:**
```
Rank | Name              | Points | CO₂ Score | Prize
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🥇 1 | Rahul Singh      | 3,840  | 88/100    | ₹5,000
🥈 2 | Priya Sharma     | 3,200  | 75/100    | ₹3,000
🥉 3 | Arjun Verma      | 2,890  | 72/100    | ₹1,000
...
847  | You              | 1,240  | 58/100    | —
```

#### 5c. Badges (Achievements)

**Badge Tiers:**

Tier 1 (Early Adoption):
- 🌱 Green Starter: Complete first room analysis
- 🔥 Streak Collector: 7-day action streak
- 💡 Energy Detective: Log 10 energy readings

Tier 2 (Upgrades):
- 🔌 LED Master: Replace 5+ bulbs
- ❄️ AC Optimizer: Replace old AC
- 🌊 Water Warrior: Install water heating

Tier 3 (Premium):
- ☀️ Solar Master: Install solar (2x points permanently!)
- ♻️ E-Waste Hero: Dispose 5 devices properly
- 🏅 Platinum Room: Achieve 90+ CO₂ score

**Badge Storage & Display:**
```json
{
  "user_id": "uuid-123",
  "badges": [
    {
      "id": "solar_master",
      "name": "Solar Master",
      "emoji": "☀️",
      "tier": 3,
      "unlocked_date": "2026-06-15",
      "benefit": "2x points multiplier (permanent)",
      "shareable": true
    }
  ]
}
```

**Social Sharing:**
- One-click Instagram story template
- ShareKit integration for Twitter, Facebook
- Unique referral link for each user

---

### Feature 6: Recommendations Marketplace

**Description:** Show filtered product recommendations with real-time pricing and affiliate links

**Data Source:**
- Flipkart API (cached hourly)
- Manual database for non-API products
- Alternate: Web scraping (Selenium) as fallback

**Product Recommendations Algorithm:**
```python
def get_replacement_products(
    appliance_type: str,  # "AC", "Refrigerator", "LED"
    budget: Optional[int] = None,
    preferences: Optional[List[str]] = None
) -> List[Product]:
    """
    Returns top 5 products ranked by:
    1. BEE star rating (5-star preferred)
    2. User reviews (4.5+ stars)
    3. Energy efficiency (lowest power consumption)
    4. Payback period (shortest ROI)
    5. Price (within budget if specified)
    """
    
    base_query = {
        'category': appliance_type,
        'min_rating': 4.5,
        'bee_star': 5
    }
    
    if budget:
        base_query['max_price'] = budget
    
    products = flipkart_api.search(**base_query)
    
    for product in products:
        # Calculate annual savings
        product['annual_savings'] = calculate_savings(product)
        product['payback_months'] = (product['price'] / product['annual_savings']) * 12
        product['affiliate_link'] = generate_affiliate_link(product['id'])
    
    return sorted(products, key=lambda x: x['payback_months'])[:5]
```

**Display Format:**
```
Top 5 AC Replacements for Your ₹35K Budget

1️⃣ LG 5-Star Inverter (1.5 Ton)
   ⭐ 4.8/5 (2,340 reviews)
   💰 Price: ₹34,999
   💵 Annual savings: ₹4,800
   ⏱️ Payback: 5.8 years
   🌍 Energy: 2.8 kWh/day
   [View Details] [Buy on Flipkart]

2️⃣ Daikin 5-Star Inverter (1.5 Ton)
   ⭐ 4.7/5 (1,856 reviews)
   💰 Price: ₹36,500
   💵 Annual savings: ₹5,100
   ⏱️ Payback: 5.4 years
   🌍 Energy: 2.6 kWh/day
   [View Details] [Buy on Flipkart]

...

📍 Need help choosing? [Ask AI Advisor]
```

**Repair Services Integration:**
```python
def search_repair_services(
    appliance_type: str,
    location: str = "Lucknow",
    radius_km: int = 10
) -> List[RepairService]:
    """
    Returns list of certified repair centers
    Data source: Google Maps API + manual curated list
    """
    
    services = []
    
    # Google Maps search
    places = google_maps.nearby_search(
        query=f"certified {appliance_type} repair {location}",
        radius=radius_km * 1000
    )
    
    for place in places:
        services.append({
            'name': place['name'],
            'rating': place['rating'],
            'distance_km': place['distance'],
            'phone': place['phone'],
            'address': place['address'],
            'typical_cost_low': estimate_repair_cost(appliance_type),
            'typical_cost_high': estimate_repair_cost(appliance_type) + 2000,
            'warranty': get_typical_warranty(appliance_type),
            'maps_link': place['maps_url']
        })
    
    return sorted(services, key=lambda x: (x['rating'], x['distance_km']), reverse=True)
```

---

### Feature 7: User Profile & Settings

**Profile Data Model:**
```json
{
  "user_id": "uuid-123",
  "name": "Priya Sharma",
  "email": "priya@example.com",
  "phone": "+91-XXXXXXXXXX",
  "profile_pic": "https://...",
  "city": "Lucknow",
  "pincode": "226001",
  "co2_score": 58,
  "total_points": 1240,
  "total_points_redeemed": 1500,
  "active_badges": ["🌱", "🔥", "💡"],
  "leaderboard_rank_city": 847,
  "leaderboard_rank_country": 45230,
  "lifetime_co2_saved_kg": 150,
  "created_at": "2025-12-15",
  "subscription": {
    "tier": "premium",
    "expires_at": "2026-02-27",
    "auto_renew": true
  },
  "preferences": {
    "notifications_enabled": true,
    "daily_challenge_reminder": true,
    "leaderboard_visibility": "public",
    "share_stats_on_social": true
  }
}
```

**Settings Options:**
- Notification preferences (daily challenges, achievements, leaderboard updates)
- Privacy settings (profile visibility, data sharing)
- Subscription management (upgrade/downgrade)
- Account deletion (GDPR compliance)
- Language (future: Hindi, Marathi, Tamil support)

---

### Feature 8: Analytics Dashboard (Premium Feature)

**Available to Premium Users (₹299/month):**

```
┌─────────────────────────────────────────────┐
│    YOUR IMPACT DASHBOARD (Premium)          │
├─────────────────────────────────────────────┤
│                                             │
│  📊 This Month                              │
│  ├─ CO₂ Saved: 45 kg                       │
│  ├─ Electricity Saved: 150 kWh              │
│  ├─ Money Saved: ₹1,200                    │
│  └─ Points Earned: 1,240                    │
│                                             │
│  📈 6-Month Trend                           │
│  [Graph showing CO₂ reduction over time]   │
│                                             │
│  💰 Cost vs Savings Analysis               │
│  [Compare investment vs returns]           │
│                                             │
│  🌍 Appliance Breakdown                     │
│  ├─ AC: 45% of CO₂ (highest impact)        │
│  ├─ Fridge: 25%                            │
│  ├─ Lighting: 15%                          │
│  └─ Other: 15%                             │
│                                             │
│  📍 ESG Report (Export)                     │
│  [Download PDF for company reporting]      │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🗄️ Data Models & Schemas

### Core Tables

#### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(15),
    profile_pic_url TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    subscription_tier ENUM('free', 'premium', 'enterprise'),
    subscription_expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);
```

#### Room Analysis Table
```sql
CREATE TABLE room_analyses (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    analysis_date TIMESTAMP,
    room_name VARCHAR(100),  -- "Bedroom", "Living Room", etc.
    room_size_sqft INT,
    total_co2_annual_kg DECIMAL(10, 2),
    efficiency_score INT,
    image_urls TEXT[],  -- Array of uploaded photo URLs
    analysis_json JSONB,  -- Full analysis data
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

#### Appliances Table
```sql
CREATE TABLE appliances (
    id UUID PRIMARY KEY,
    analysis_id UUID NOT NULL REFERENCES room_analyses(id),
    type VARCHAR(50),  -- "AC", "Refrigerator", "Fan", etc.
    detected_brand VARCHAR(100),
    estimated_model VARCHAR(100),
    estimated_age_years INT,
    estimated_power_watts INT,
    annual_co2_kg DECIMAL(10, 2),
    estimated_replacement_cost INT,
    replacement_priority VARCHAR(20),  -- "HIGH", "MEDIUM", "LOW"
    detection_confidence FLOAT,  -- 0-1
    user_overridden BOOLEAN DEFAULT FALSE,
    user_overridden_specs JSONB
);
```

#### Points & Gamification Tables
```sql
CREATE TABLE user_points (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    action_type VARCHAR(50),
    points_earned INT,
    multiplier FLOAT DEFAULT 1.0,
    final_points INT GENERATED AS (points_earned * multiplier),
    created_at TIMESTAMP,
    verified BOOLEAN DEFAULT TRUE,
    verification_proof TEXT  -- e.g., photo URL
);

CREATE TABLE user_streaks (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    current_streak_days INT DEFAULT 0,
    max_streak_days INT DEFAULT 0,
    last_action_date DATE,
    multiplier_active FLOAT DEFAULT 1.0,
    updated_at TIMESTAMP
);

CREATE TABLE user_badges (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    badge_id VARCHAR(100),
    unlocked_date TIMESTAMP,
    shareable BOOLEAN DEFAULT TRUE
);

CREATE TABLE leaderboard_cache (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    rank_city INT,
    rank_country INT,
    total_points INT,
    co2_score INT,
    updated_at TIMESTAMP,
    INDEX (rank_city, rank_country)
);
```

---

## 🎬 User Flows

### Flow 1: First-Time User (Onboarding)
```
1. Download app
   ↓
2. Sign up (phone/email)
   ↓
3. Grant permissions (camera, location, notifications)
   ↓
4. Take room photos (3x)
   ↓
5. AI analyzes (5-10 sec)
   ↓
6. See CO₂ score + recommendations
   ↓
7. Complete daily action (earn first points)
   ↓
8. Set notification reminders
   ↓
9. Done! (First 50 points earned)
```

### Flow 2: Purchase Journey
```
1. View recommendation: "Replace AC"
   ↓
2. Click [Shop on Flipkart]
   ↓
3. Affiliate link opens Flipkart (EcoSnap earns 2%)
   ↓
4. User buys AC (₹35,000)
   ↓
5. EcoSnap webhook: Purchase confirmed
   ↓
6. User earns: 1000 points (₹100)
   ↓
7. Get ₹30K subsidy via app
   ↓
8. Schedule installation
   ↓
9. Log upgrade in app
   ↓
10. CO₂ score jumps: 45 → 75 ✅
```

### Flow 3: Leaderboard & Premium Upgrade
```
1. User sees leaderboard (rank #847)
   ↓
2. Sees premium features: "Unlock thermal analysis"
   ↓
3. Clicks [Upgrade to Premium]
   ↓
4. Payment (₹299/month, Razorpay)
   ↓
5. Gets access to:
   - 3D thermal visualization (Phase 2)
   - Detailed ROI analysis
   - Export ESG reports
   ↓
6. Premium user for 30 days
   ↓
7. Auto-renew or cancel anytime
```

---

## 💻 Technology Stack

### Frontend
- **Mobile:** React Native (iOS + Android)
- **Web:** React.js (future, Phase 3)
- **State Management:** Redux Toolkit
- **Navigation:** React Navigation
- **UI Components:** React Native Paper
- **Image Handling:** React Native Image Crop Picker
- **Maps:** Google Maps API (for repair services)

### Backend
- **Framework:** FastAPI (Python 3.10+)
- **Deployment:** Google Cloud Run (serverless)
- **Database:** PostgreSQL (CloudSQL)
- **Cache:** Redis (CloudMemorystore)
- **Message Queue:** Cloud Pub/Sub (async tasks)
- **Auth:** Firebase Auth + JWT

### AI/ML
- **CV Model:** YOLOv8n (nano, 3.2MB)
- **Vision API:** Google Gemini Vision
- **LLM:** Google Gemini 2.0 Flash (chat advisor)
- **Model Serving:** Google Vertex AI (batch inference)
- **3D Reconstruction:** COLMAP (Phase 2)

### Infrastructure
- **Cloud Provider:** Google Cloud Platform (GCP)
- **Compute:** Cloud Run (API), Compute Engine (batch jobs)
- **Storage:** Cloud Storage (images), BigQuery (analytics)
- **Monitoring:** Cloud Monitoring, Cloud Logging
- **CDN:** Cloud CDN + CloudFlare
- **Payment:** Razorpay (subscriptions, payouts)

### Integration APIs
- **Flipkart:** Affiliate program + web scraping
- **Amazon:** Affiliate program
- **Google Maps:** Repair service locator
- **NRDC/EESL:** E-waste pickup (manual partnerships)
- **Government Schemes:** Manual database (UJALA, PM Surya Ghar)

---

## 📊 Success Metrics (MVP - 12 weeks)

### Acquisition
- 500 beta testers (internal + GDG + college ambassadors)
- 10% install rate from sign-ups = 50 active users by week 12
- 5 media mentions (TechInAsia, Indian startups)

### Engagement
- 30-day retention: 40%+ (vs 20% industry average)
- Daily active users: 20+ (of 50)
- Average session length: 5+ minutes
- Gamification engagement: 60% complete daily challenge

### Monetization
- Conversion to premium: 5-10% (2-5 paying users)
- Average revenue per user: ₹50-100/month
- 0 affiliate sales (MVP, not marketplace-focused)
- Total MVP revenue: ₹3,000-5,000

### Product Quality
- AI detection accuracy: >85% for common appliances
- Chat response satisfaction: >4/5 stars
- App crash rate: <0.5%
- API uptime: >99%

### Impact
- 50 users × 350 kg CO₂ reduction = 17,500 kg CO₂ saved
- 50 users × ₹2,000 appliance savings = ₹1 lakh utility savings
- 50 users × ₹500 points earned = ₹25K distributed to users

---

## 🚀 Release Timeline

### Phase 1: MVP (Weeks 1-12, Hackathon)
**Features:** Room analysis + CO₂ score + Recommendations + Chat + Gamification (basic)
**Deliverables:** iOS app, Android app, Backend API, Gemini integration
**Launch:** AMD Slingshot hackathon (mid-April 2026)

### Phase 2: Post-Hackathon (Weeks 13-24, 3 months)
**Features:** 3D visualization + Thermal simulation + Premium subscription + Advanced analytics
**Deliverables:** COLMAP 3D module, Thermal engine, Payment integration
**Launch:** June 2026 (public beta)

### Phase 3: Scale (Weeks 25-52, 6 months)
**Features:** AR preview + Contractor marketplace + Bulk API (corporate) + Multi-city expansion
**Deliverables:** AR module (ARCore/ARKit), Contractor dashboard, Admin panel
**Launch:** September 2026 (full production)

---

## 🎯 Go-to-Market Strategy

### Pre-Launch (Hackathon Preparation)
- Build buzz with AI + sustainability narrative
- Target: 50K social media impressions
- Influencer partnerships: 2-3 eco-influencers
- PR: Pitch to TechCrunch India, YourStory, Mint

### Launch (AMD Slingshot)
- Exclusive partnership with AMD (Sustainable AI track)
- Demo at hackathon (live room analysis)
- Sponsor announcement with AMD branding
- User acquisition: 500 beta testers from hackathon audience

### Post-Launch (Weeks 1-8)
- College ambassador program: 10 campus reps (₹1K/50 signups)
- Google Developer Groups: Workshops in Lucknow, Delhi, Bangalore
- Reddit/Twitter: Build community around eco-gaming
- Organic: Referral bonuses (₹50 per referred friend)

### Year 1 Growth
- Content marketing: Blog posts on green architecture + ROI
- Corporate partnerships: B2B ESG reporting (enterprise contracts)
- Franchise partnerships: Appliance sellers, contractors
- Expansion: 5 major Indian cities (Delhi, Bangalore, Mumbai, Chennai, Hyderabad)

---

## 💰 Financial Projections (Year 1)

### Cost Structure
```
Infrastructure & Hosting:    ₹5,00,000
  (GCP, Razorpay, APIs)

AI/ML Costs:                 ₹3,00,000
  (Gemini API, Vertex AI)

Gamification & Prizes:       ₹12,00,000
  (₹100K/month leaderboard prizes)

Team (3 people):             ₹24,00,000
  (Salary + benefits)

Marketing & Sales:           ₹6,00,000
  (Social, influencers, content)

TOTAL OPEX:                  ₹50,00,000 (₹50L)
```

### Revenue Projections
```
Users by Month:
  Month 1: 50 (beta)
  Month 3: 500
  Month 6: 3,000
  Month 12: 10,000

ARPU (Average Revenue Per User):
  Free tier (60%): ₹0
  Premium tier (30%, ₹299/mo): ₹90
  Enterprise tier (10%, ₹5K/mo): ₹500
  Blended ARPU: ₹168/user/month

Revenue by Source (Month 12):
  Premium subscriptions (30% × 10K × ₹299): ₹29,90,000
  Affiliate commissions (6% of appliance sales): ₹15,00,000
  Contractor partnerships (10% margin): ₹5,00,000
  ESG/Corporate (50 accounts × ₹5K/mo): ₹30,00,000
  TOTAL: ₹79,90,000 (₹80L)

Profitability:
  Revenue: ₹80,00,000
  OPEX: ₹50,00,000
  NET: ₹30,00,000 (₹30L) profit 🎯
  Margin: 37.5%
```

---

## 🔐 Privacy & Security

### Data Protection
- All user data encrypted (AES-256)
- GDPR-compliant (user can export/delete anytime)
- No 3rd party data selling
- Room photos deleted after 24 hours (only analysis kept)
- Sensitive image areas auto-blurred (faces, documents)

### Compliance
- Terms of Service (drafted)
- Privacy Policy (drafted)
- Data Processing Agreement (DPA)
- ISO 27001 certification (Year 2 goal)
- DGFT compliance (for government subsidies)

### User Consent
- Camera permission required
- Location permission optional
- Notification opt-in
- Social share opt-in
- Analytics tracking opt-in

---

## 🤝 Partnerships & Integrations

### Essential (MVP)
- **Flipkart:** Affiliate program + product API (or web scraping)
- **Google Cloud:** GCP credits for startup (₹1,00,000)
- **Google Maps:** Repair service locator

### Strategic (Phase 2)
- **NRDC:** E-waste disposal verification
- **Sunrun/Blue Tokai:** Solar installer partnerships
- **BEE (Bureau of Energy Efficiency):** Appliance rating validation

### Potential Monetization (Phase 3)
- **Contractor Network:** 10% commission on installations
- **Insurance Companies:** Green home insurance partnerships
- **Utility Companies:** Demand-side management programs
- **Real Estate Developers:** Green building certification

---

## 📝 Acceptance Criteria & Testing

### Functional Testing
- [ ] Room photo upload works on iOS/Android
- [ ] YOLOv8 detects AC, fridge, lights with >85% accuracy
- [ ] CO₂ score updates in real-time after appliance changes
- [ ] Chat responds within 5 seconds
- [ ] Points awarded correctly with multipliers
- [ ] Leaderboard shows correct ranking
- [ ] Flipkart affiliate links work and track sales
- [ ] Payment processing (Razorpay) works

### Non-Functional Testing
- [ ] App <100MB (for 4G users)
- [ ] API response time <2 seconds
- [ ] Database handles 10,000 concurrent users
- [ ] No crashes or memory leaks
- [ ] 99%+ uptime SLA

### User Testing
- [ ] Onboarding flow completable in <5 minutes
- [ ] First-time users understand CO₂ score
- [ ] Chat responses are helpful (4+/5 rating)
- [ ] 40%+ users complete daily challenge

---

## 📞 Support & Feedback

### Support Channels
- In-app chat (powered by Gemini)
- Email: support@ecosnap.co
- Twitter: @EcoSnapIndia
- WhatsApp: +91-XXXXXXXXXX (Phase 2)

### Feedback Loops
- In-app survey after major actions
- Monthly feedback form
- Reddit: r/EcoSnap community
- Discord: Private community server

### Bug Reporting
- In-app "Report Bug" button (captures logs)
- Automatic crash reporting (Sentry)
- GitHub issues (for transparency)

---

## ✅ Conclusion

**EcoSnap** is a data-driven, monetarily-incentivized sustainability app that turns green upgrades into a competitive game with real prizes and measurable ROI.

**Why it works:**
1. ✅ Solves real problem (rising electricity bills, carbon guilt)
2. ✅ Money-first messaging (₹ savings before planet)
3. ✅ Gamification with real rewards (not just badges)
4. ✅ AI-powered personalization (not generic tips)
5. ✅ India-native (repair culture, subsidy knowledge)
6. ✅ End-to-end (analyze → quote → install → track)
7. ✅ Viral potential (shareable badges, leaderboards)
8. ✅ Sustainable revenue model (subscriptions + affiliate)

**MVP is launchable in 12 weeks.** Core tech is proven (YOLOv8, Gemini, GCP). Market opportunity is massive (300M+ Indian homes). Team has domain expertise (AI, products, sustainability).

**Let's build. 🚀**

---

**Document Status:** ✅ Ready for Development  
**Last Updated:** January 27, 2026  
**Next Review:** After Week 4 of development