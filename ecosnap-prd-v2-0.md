# EcoSnap PRD - UPDATED with Winning Mechanics
## Version 2.0 - Incorporating Successful Competitor Features

**Updated:** January 28, 2026  
**Based on Research:** JouleBug, AWorld, Oroeco, Klima, CoGo, Refilled, Strava, Habitica  
**Status:** Ready for MVP Development

---

## 🎯 Key Changes from Research

### 1. **AI-Driven Personalization (NEW FEATURE)**

**What's changing:** Instead of showing 50 generic tips, the app learns user behavior and suggests only 3-5 custom actions.

**Implementation:**
- Analyze user's budget, motivation type (money vs planet), past actions
- Only suggest actions within their constraints
- Example: If user has ₹2K budget, don't show ₹35K AC replacement

**Why it works:**
- AWorld's IEI = 500K users
- CoGo: 14+ NPS uplift in banking (unprecedented)
- Personalization > Generic tips (every app data confirms)

**MVP Integration:**
```
Step 1: User uploads room → YOLOv8 detects appliances
Step 2: User sets budget (₹500, ₹2K, ₹5K, ₹10K+)
Step 3: Gemini personalizes 5 actions for THIS user
Step 4: Only show actions user can realistically do

Example:
Priya (₹2K, money-motivated): Smart thermostat, AC service, remaining LEDs
Rajesh (busy founder): One solar installation, we handle rest
Zara (homemaker): Cheap fixes first (aerators ₹300, valves ₹2K)
```

---

### 2. **Financial Data Integration (NEW)**

**What's changing:** App tracks spending-based carbon, not just appliances

**Implementation:**
```
User's purchases → Carbon footprint calculation
- Buy eco-conscious shampoo → Lower carbon score
- Buy fast fashion → Higher carbon score
- Shop secondhand → Get bonus points
```

**India-specific:**
- UPI integration (track spending through Razorpay)
- Flipkart affiliate purchases tracked
- Monthly spending breakdown by carbon
- Show ₹ savings + CO₂ savings together (money first)

**Why it works:**
- Oroeco: Shows spending-carbon connection
- CoGo: 4-6 min dwell time (high engagement)
- Reality: People care about MONEY + PLANET

---

### 3. **Personal Bests Leaderboard (CHANGE)**

**What's changing:** 
- Primary leaderboard = Personal progress (not global rank)
- Secondary = Percentile rank (top 30%, not just top 1)
- Monthly "Most Improved" awards (celebrate everyone)

**Why it works:**
- Strava research: Leaderboards backfire unless personalized
- Cohorty: 80% prefer seeing personal progress
- 70% of users demoralized by all-or-nothing ranking

**New UI:**
```
┌─────────────────────────────────┐
│ YOUR PROGRESS                   │
│ CO₂ Score: 45 → 58 (+13) 📈    │
│ This month: ↑ 15 points         │
│                                 │
│ YOUR RANK (Lucknow)            │
│ Top 30% of users ⭐             │
│ Rank: #847 out of 2,800        │
│                                 │
│ MONTHLY AWARDS                  │
│ 🏆 Most Improved: You!          │
│ Prize: ₹500                     │
└─────────────────────────────────┘
```

---

### 4. **Minimal Gamification ONLY (CRITICAL CHANGE)**

**What's changing:** Remove complexity, keep only what works

**Research finding:** Cohorty (2025)
- Heavy gamification: 41% retention at 90 days
- Minimal gamification: 53% retention at 90 days
- Conclusion: Less is more

**KEEPING:**
- ✅ Streaks (7-day, 14-day, 30-day with multipliers)
- ✅ Badges (Tier 1, 2, 3 only - not 50 badges)
- ✅ Points system (simple: 10 points = ₹1)
- ✅ Weekly leaderboard (resets, everyone equal chance)

**REMOVING:**
- ❌ Class systems (no "Mage" or "Rogue")
- ❌ Loot boxes (no randomness, no FOMO)
- ❌ Pet evolution (no digital pets)
- ❌ Cosmetics shop (no skins, no equipment)
- ❌ Boss battles (no fake enemies)
- ❌ Levels beyond CO₂ score (keep it simple)

**Why:** Overcomplication drives 67% abandonment by week 4

---

### 5. **Party/Team System (NEW)**

**What's changing:** Friends/family form teams for group challenges

**Implementation:**
```
Create team "Living Room Warriors"
├─ Invite: Priya, Rajesh, Zara
├─ Team leaderboard (private, monthly ₹5K prize)
├─ Shared goal: Save 500 kg CO₂ this month
├─ Weekly challenges (all team members can contribute)
└─ Accountability: Missed challenge = team sees (gentle pressure)

Benefits:
- Peer accountability (don't want to let team down)
- Social motivation (see friends' progress)
- Celebration (team milestones)
- Split prizes (incentive to play)
```

**Why it works:**
- Habitica: Team penalties = 30% better retention
- JouleBug: 10 years using team challenges

---

### 6. **Weekly Rotating Challenges (NEW)**

**What's changing:** Challenges rotate every Monday (not static leaderboard)

**Examples:**
```
Week 1: "Unplug Warrior"
- Unplug devices 5 days → 100 bonus points
- Leaderboard resets (fresh start for everyone)
- Creates urgency (only 7 days)

Week 2: "Light Switch Master"
- Use natural light 8am-5pm for 7 days → 100 points

Week 3: "Thermostat Tamer"
- Keep AC at 27°C for 7 days → 100 points

Week 4: "E-Waste Hero"
- Dispose of 1 electronic device properly → 100 points
```

**Why it works:**
- Variety beats monotony
- Fresh start weekly (motivates mid-performers)
- FOMO drives engagement
- AWorld, JouleBug use this

---

### 7. **Behavioral Nudges at Right Moments (NEW)**

**What's changing:** Push notifications triggered by context, not random

**Examples:**
```
❌ Generic: "Join our community!"
✅ Contextual: "Your 7-day streak is about to break. Unplug 3 devices to continue!"

❌ Generic: "Reduce carbon footprint"
✅ Contextual: "Your AC used 8 hours today (vs avg 5h). Save ₹400/mo with auto-OFF at 27°C?"

❌ Generic: "You earned a badge"
✅ Contextual: "🌱 Green Starter badge! Next: Replace 1 light bulb for LED Master"

❌ Generic: "Try premium"
✅ Contextual: "Your points reached ₹500. Unlock 3D thermal analysis for ₹299/month?"
```

**Timing:**
- After 7-day streak (reinforce)
- After action completion (celebrate)
- When about to churn (bring back)
- When ready for upgrade (contextual CTA)

**Why it works:**
- CoGo: 4-6 min average dwell time (industry-leading)
- Behavioral science: Context = 3x higher conversion

---

### 8. **Subscription + Carbon Offset Model (NEW)**

**What's changing:** Optional ₹299/month subscription for carbon offsetting

**Implementation:**
```
User pays ₹299/month
├─ 70% → Carbon offsets (choose from menu)
├─ 20% → EcoSnap operations
└─ 10% → Marketing

Offset options (user chooses):
- Tree planting in Madhya Pradesh
- Solar projects in rural UP
- Clean cook stoves in villages
- Water conservation programs

Real-time counter:
"Your ₹209 this month has:
🌳 Planted 5 trees
☀️ Enabled 40 kWh solar
👩‍🍳 Provided 3 clean stoves"
```

**Why it works:**
- Klima: $5.8M funded on this model
- Transparency = Trust
- Tangible impact = Habit formation
- Monthly recurring revenue

---

### 9. **Achievement Roadmap (NEW)**

**What's changing:** Clear progression path from novice → expert

```
🌱 Tier 1 (Green Starter):
├─ Complete room analysis
├─ Join any challenge
├─ Earn first ₹50
└─ Unlock: Daily notifications

🔥 Tier 2 (Habit Hero):
├─ Achieve 7-day streak
├─ Make first upgrade (LED bulb)
├─ Earn ₹500 total
└─ Unlock: Premium features preview

☀️ Tier 3 (Solar Master):
├─ Install solar system
├─ Reach 90+ CO₂ score
├─ Earn ₹5,000+ total
└─ Benefit: Permanent 2x points
```

**Why it works:**
- Users know what to aim for
- Keeps engagement through month 6+
- Habitica: Progression = long-term stickiness

---

### 10. **Referral + Social Sharing (NEW)**

**What's changing:** One-tap sharing with viral incentives

**Implementation:**
```
User clicks "Share"
├─ Pre-filled Instagram Story template
│  "I saved 45 kg CO₂ in January! 🌱
│   Join EcoSnap and compete with me!
│   [Unique referral link]"
│
├─ Pre-filled Twitter: "Gamifying sustainability with EcoSnap ⚡"
│
└─ Both get ₹100 bonus if friend installs

First 1000 installs: 2x points on all actions (limited time)
```

**Why it works:**
- Strava/Snapchat: Viral loops drive adoption
- Free user acquisition
- Early user incentive

---

## 📊 Feature Priority for MVP (12 weeks)

### Week 1-4: Core + Personalization
- ✅ Room Analysis (existing)
- ✅ CO₂ Score + Recommendations (existing)
- ✅ **AI-Driven Personalization** (NEW)
- ✅ **Minimal Gamification** (simplified from original)

### Week 5-8: Social + Engagement
- ✅ Chat Advisor (existing)
- ✅ **Personal Bests Leaderboard** (NEW)
- ✅ **Weekly Rotating Challenges** (NEW)
- ✅ **Behavioral Nudges** (NEW)

### Week 9-12: Polish + Growth
- ✅ **Party/Team System** (NEW)
- ✅ **Referral System** (NEW)
- ✅ **Achievement Roadmap** (NEW)
- ✅ Demo + Bug fixes

### Phase 2 (Weeks 13-24):
- ✅ **Financial Data Integration** (if time allows MVP)
- ✅ **Subscription + Offset Model**
- ✅ Community features
- ✅ Educational content

---

## 🎯 MVP Success Metrics (Updated)

### Acquisition (Teams)
- 500 beta testers organized into teams
- 50 teams of 5-10 users

### Engagement
- 40%+ 30-day retention (vs 20% industry baseline)
- 60%+ complete weekly challenge
- 80% engage with personalized actions
- 3.5+ avg session time

### Retention
- Team members: 50%+ retention (vs individuals: 35%)
- Weekly challenge participants: 70% return next week
- Leaderboard viewers: 45% take action

### Monetization
- 5-10% premium conversion
- 3-5 affiliate sales
- ₹3K-5K MVP revenue

---

## 🏆 Winning Principles (Integrated)

1. **Money First** - Show ₹ savings before CO₂ ✅ (Oroeco, CoGo)
2. **Personal > Global** - Celebrate individual progress ✅ (Strava)
3. **Simplicity Wins** - Minimal gamification ✅ (Cohorty research)
4. **AI Matters** - Personalization not tips ✅ (AWorld)
5. **Team = Stickiness** - Party system ✅ (Habitica)
6. **Context is Key** - Nudges at right time ✅ (CoGo)
7. **Transparency Builds Trust** - Show offset impact ✅ (Klima)
8. **Impact-based Points** - Not vanity ✅ (JouleBug)
9. **Weekly Refresh** - Challenges reset ✅ (AWorld, JouleBug)
10. **Celebrate Small Wins** - Most Improved awards ✅ (Strava)

---

## 📝 Implementation Notes

### Complexity Trade-off
- Original PRD: 50+ features (impossible in 12 weeks)
- Research shows: 10-15 well-executed features > 50 mediocre ones
- Dropping: 3D visualization for MVP (Phase 2), heavy cosmetics, pet systems

### Focus Areas
- Personalization (AI-driven, not generic)
- Social/team features (accountability = retention)
- Simplicity (Cohorty proves minimalism wins)
- Right-time nudges (CoGo's secret sauce)

### Competitive Advantage
**vs JouleBug:** + Personalization, + Financial data, + India-native  
**vs AWorld:** + Playback period focus, + Affiliate marketplace, + Simpler UX  
**vs Klima:** + Gamification, + Team challenges, + Actionable insights  
**vs Oroeco:** + Real rewards (points), + Marketplace integration  

---

## ✅ Conclusion

EcoSnap 2.0 combines the **best mechanics from 10 proven apps** while maintaining simplicity and India-native focus.

**Key differentiators:**
- AI-driven personalization (not generic tips)
- Financial + carbon tracking (money + planet)
- Team-based engagement (accountability)
- Minimal but engaging gamification (not overwhelming)
- Right-time behavioral nudges (context matters)

**Timeline:** MVP in 12 weeks with 15-20 core features (quality over quantity)

**Expected outcome:** 40%+ Day 30 retention (vs 20% industry baseline), 500 beta testers, ₹3-5K MVP revenue, strong foundation for funding.

---

**Document prepared by:** Research & Product Team  
**Date:** January 28, 2026  
**Status:** Ready for development kickoff
