# 📋 **EcoSnap PRD (Product Requirements Document)**

**Version:** 1.0  
**Date:** January 28, 2026  
**Status:** Final - Ready for Development  
**Timeline:** 12 weeks to MVP

---

## **EXECUTIVE SUMMARY**

EcoSnap is a green home upgrade platform that organizes India's ₹1 trillion home improvement market. Users scan their room with AI, get personalized energy upgrade recommendations, book verified installers, and track impact. Five core features differentiate EcoSnap:

1. **Govt Certification Tiers** - Official "Green Citizen" progression with govt partnerships
2. **Community Q&A** - Peer learning + installer expertise monetization
3. **Govt Subsidy Integration** - Auto-apply for UJALA/PM Surya Ghar
4. **Predictive Maintenance AI** - Predict appliance failures before breakdowns
5. **Carbon Credits** - Tradeable verified carbon from user actions

**Expected Outcome:** 500+ users, 40% Day 30 retention, 30+ installers, ₹33K revenue by Week 12.

---

## **THE 5 CORE FEATURES**

### **FEATURE 1: GOVT CERTIFICATION TIERS**

**Purpose:** Official "Green Citizen" progression with govt backing, social proof, shareable credentials

**Tier Structure:**
- **Tier 1: Green Starter** - 1st upgrade, 100kg CO₂, ₹2K saved, instant unlock
- **Tier 2: Eco Warrior** - 3+ upgrades, 500kg CO₂, ₹10K saved, automatic unlock
- **Tier 3: Climate Champion** - 10+ upgrades, 2000kg CO₂, ₹50K saved, automatic unlock

**Key Features:**
- Downloadable PDF certificates with verification code
- Public API to verify certificate authenticity
- Social sharing (LinkedIn, WhatsApp, Instagram)
- Profile badge display
- Govt portal integration (aspirational)

**Success Metrics:**
- 200+ users reach Tier 1
- 50+ certificates downloaded
- 30+ social media shares
- Official govt recognition

---

### **FEATURE 2: COMMUNITY Q&A**

**Purpose:** Peer learning + installer expertise monetization + network effect

**Reward System:**
- Base ₹5 per answer
- Upvote bonus: ₹0.50 per upvote (max ₹20)
- Expert bonus: ₹10 if marked helpful
- Max reward per answer: ₹50

**Community Groups:**
- Auto-create by location (city-level)
- Weekly challenges (team goals)
- Leaderboard (top contributor ₹200/week, ₹500/month)
- Success stories (before/after + timeline)

**Success Metrics:**
- 200+ questions by Week 12
- 50+ installers actively answering
- 1000+ community members
- ₹5K total paid in rewards
- 10+ community experts created

---

### **FEATURE 3: GOVT SUBSIDY INTEGRATION**

**Purpose:** Remove bureaucratic friction, auto-apply for government subsidies

**Supported Schemes:**
- UJALA (₹8,000 for efficient AC)
- PM Surya Ghar (up to ₹3,00,000 for solar)
- Super Efficient Fan
- State-specific schemes

**Process:**
1. User selects appliance for upgrade
2. App checks eligibility (state, consumption, income)
3. Auto-fills form with user data
4. User reviews & confirms
5. Submits to govt system
6. Real-time status tracking (Submitted → Approved → Credited)

**Success Metrics:**
- 50+ applications submitted
- ₹50K+ total subsidy accessed
- 80%+ approval rate
- < 2 weeks average processing
- 30+ referral commissions

---

### **FEATURE 4: PREDICTIVE MAINTENANCE AI**

**Purpose:** Predict appliance failures before they happen

**ML Model:**
- Algorithm: XGBoost (gradient boosting)
- Training data: 10K+ historical repair records
- Features: age, usage hours, model, repair history, temperature
- Output: Days to failure + failure probability

**Alert System:**
- Notify if >60% probability of failure in <90 days
- Show health score (0-100%) on appliance card
- Show confidence level ("85% confident")
- Preventive maintenance recommendation

**Success Metrics:**
- 200+ appliances tracked
- 20+ alerts triggered (accurate)
- 10+ preventive maintenance jobs
- 80%+ user confidence in predictions
- Model accuracy improving monthly

---

### **FEATURE 5: CARBON CREDITS (Tradeable)**

**Purpose:** New monetization, gamify sustainability, create carbon economy

**Credit System:**
- Daily challenge: 1kg CO₂ = 0.01 credits
- Weekly challenge: 5-20kg CO₂ = 0.05-0.2 credits
- Appliance upgrade: 100-500kg CO₂/year = 1-5 credits
- 1 credit = 100kg CO₂

**Trading:**
- Market price: ₹50-100 per credit (fixed initially)
- Order book: Buy/sell orders matching
- Settlement: 24-hour Razorpay settlement
- Corporate buyers: CSR companies for climate impact

**Success Metrics:**
- 400+ total credits earned
- 50+ credits traded
- ₹3,000+ trading volume
- 20+ corporate buyers
- 95%+ settlement success

---

## **SUCCESS METRICS (WEEK 12)**

### **User Metrics**
- 500+ registered users
- 40% Day 30 retention (2x industry)
- 300+ daily active
- 35% Day 7 retention

### **Installer Metrics**
- 30+ verified installers
- 5+ jobs per installer (150+ total)
- 4.8★+ average rating
- ₹3,000+ monthly earnings

### **Feature Adoption**
- Govt Certs: 200+ Tier 1 badges
- Community: 200+ questions, 1000+ answers
- Subsidies: 50 applications, ₹50K accessed
- Predictive: 20+ alerts, 10+ preventive jobs
- Carbon: 50+ trades

### **Impact**
- 500+ kg CO₂ reduced
- ₹5L+ user savings
- 200+ before/after photos
- ₹50K+ govt subsidies

### **Revenue**
- Total: ₹33K
- Marketplace: ₹20K (5% on ₹400K GMV)
- Subsidies: ₹5K (50 apps × ₹100)
- Q&A: ₹5K (1000 answers × ₹5)
- Credits: ₹3K (10% on ₹30K volume)

---

## **TECH STACK**

**Backend:** Node.js/FastAPI, PostgreSQL, Redis  
**Frontend:** React/Next.js, React Native/Flutter, TailwindCSS  
**ML/AI:** Python, XGBoost, MLflow, Airflow  
**Payments:** Razorpay  
**APIs:** Govt systems, IoT sensors, SMS service

---

**Status:** 🟢 **APPROVED - READY FOR DEVELOPMENT**

