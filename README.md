# 🌾 Soko Tender

An enterprise-level e-procurement marketplace designed to bridge the gap between Kenyan public institutions (schools, hospitals) and local farmers/suppliers. Soko Tender digitizes the bidding process, ensuring transparency, speed, and strict adherence to the Public Procurement and Asset Disposal Act (PPADA).

## 🚀 The Architecture
Soko Tender operates on a Multi-Tenant architecture, delivering two distinct user experiences powered by a single real-time database:

### 1. The Institution Web Portal (For Procurement Officers)
* **Multi-Tenant Dashboard:** Schools securely log in to manage only their isolated data.
* **Tender Management:** Post requirements (e.g., "500kg Cabbages") with automated closing dates.
* **Smart Bid Review:** Compare offers from verified local farmers side-by-side.
* **Automated Awarding:** Accepting a bid automatically rejects competing bids, closes the tender, and notifies all participants.
* **Instant LPO Generation:** Dynamically generates and prints a formatted Local Purchase Order (PDF) upon contract award.

### 2. The Farmer Mobile App (For Suppliers)
* **Real-Time Marketplace:** View open tenders from various institutions instantly.
* **Progressive KYC Compliance:** Enforces Tier-1 government verification (National ID, KRA PIN Certificate, and Tax Compliance Certificate image uploads) before allowing bids on government contracts.
* **Live Bidding System:** Submit secure, competitive bids directly to institutions.
* **Real-Time Notifications:** Push-style architecture with live badge counters using WebSocket streams to alert farmers of new tenders, wins, and losses instantly.

## 🛠️ Tech Stack
* **Frontend:** Flutter (Mobile & Web)
* **Backend:** Supabase
  * **Auth:** Secure Email/Password Authentication
  * **Database:** PostgreSQL with strict Row Level Security (RLS) policies for tenant data isolation.
  * **Storage:** Cloud buckets for secure KYC document uploads.
  * **Realtime & Edge Functions:** Automated PostgreSQL triggers for cross-user notifications and status migrations.

## 💡 Key Engineering Highlights
* **Optimistic UI Updates:** UI updates instantly while performing secure background syncs.
* **Complex State Management:** Handles fallback data for incomplete profiles and gracefully manages null-safety.
* **Database Triggers:** Automates profile creation and broadcast notifications at the database level to reduce client-side workload.

so you have said I should add these then commit