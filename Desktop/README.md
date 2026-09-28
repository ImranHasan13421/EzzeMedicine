# 💊 EzzeMedicine - Smart Pharmacy & Healthcare Platform

EzzeMedicine is a comprehensive, production-grade pharmacy and healthcare system comprising:
1. **Flutter Admin App** (Desktop & Android) for pharmacists to manage inventory, handle incoming customer orders, perform offline verification calls, edit items live on call, set delivery charges, and dispatch itemized invoice emails.
2. **Public Storefront Website** (`Website/`) for customers to browse authentic medicines, search by brand or generic name, manage carts, submit order requests without passwords, and track real-time verification status.
3. **Supabase PostgreSQL Database** configured on the `Ezze Softwares` multi-tenant project using isolated `EzzeMedicine_*` table prefixes with real-time websocket synchronization.

---

## 🌟 Architecture & Workflow

```
[ Customer Storefront (Website/) ]
              │
              │ 1. Browse Catalog / Add to Cart
              │ 2. Submit Order (Name, Phone, Email, optional Delivery)
              ▼
    [ Supabase PostgreSQL ]
    • EzzeMedicine_medicines
    • EzzeMedicine_orders
    • EzzeMedicine_order_items
              ▲
              │ Real-time WebSockets
              ▼
[ Flutter Admin App (Desktop/Android) ]
              │
              │ 3. Instant Order Alert ('Pending Call')
              │ 4. Pharmacist Verification Call (tel: / copy)
              │ 5. Live Order Modification on Call (add/remove items)
              │ 6. Set Home Delivery Fee manually
              │ 7. Confirm Order & Send Invoice to Customer Email
              ▼
    [ Customer Receives Verification Call & Email Bill ]
```

---

## 🚀 Key Features

### 🖥️ 1. Flutter Admin App (`lib/`)
- **Admin Authentication**: Multi-session authentication pre-configured for Lead Pharmacist **Md. Imran Hasan** (`imranhasan13421@gmail.com`).
- **Dashboard & Analytics**: Live revenue, pending calls counter, low stock alert counter, and monthly order metrics.
- **Medicine Catalog Management**: Create, edit, and delete medicines with image upload, categories, dosage guidelines, price, cost, and minimum stock alerts.
- **Order Processing & Call Flow**:
  - One-click phone calling (`tel:`) and phone copying for desktop.
  - Call status tracking: `Not Called`, `Customer Confirmed`, `Called & Modified`, `Cancelled`.
  - Live order modification: add extra medicines requested by the customer directly while on the call.
  - Manual delivery charge input for home deliveries.
  - Automated itemized email bill dispatch.
- **Admin Profile & Readme Screen**: Clean profile overview, live database status, workflow guide, and sign-out controls.

### 🌐 2. Public Storefront Website (`Website/`)
- **Zero Friction Checkout**: No password required. Customers enter only Name, Phone, Email, and Delivery Address.
- **Live Inventory**: Real-time Supabase connection reflects stock changes and new catalog items instantly.
- **Responsive & Modern Design**: Crafted with Google Fonts (Inter & Outfit), emerald-mint healthcare palette, smooth micro-animations, and full mobile + desktop scalability.
- **Real-Time Order Tracking**: Customers can check order verification status anytime by entering their Order ID (e.g. `EZM-83503`) or phone number.

---

## 🛠️ Local Development & Testing

### Running the Public Website Locally
The website is static HTML/CSS/JS and can be served with any HTTP server:

```powershell
# Using Python
cd Website
python -m http.server 5000

# Open in browser: http://localhost:5000
```

### Running the Flutter Admin App
```powershell
# Get dependencies
flutter pub get

# Run on Windows Desktop
flutter run -d windows

# Run on Android Device / Emulator
flutter run -d android
```

---

## 📦 Deployment Guide

### 1. Pushing Code to GitHub
```powershell
git init
git add .
git commit -m "feat: EzzeMedicine pharmacy system with Flutter admin and public website"
git branch -M main
git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/EzzeMedicine.git
git push -u origin main
```

### 2. Deploying Website to Vercel
You can deploy the website to Vercel in seconds:

#### Option A: Via Vercel Web Dashboard (Recommended)
1. Go to [vercel.com](https://vercel.com) and click **Add New > Project**.
2. Select your imported `EzzeMedicine` GitHub repository.
3. In the project settings, set:
   - **Framework Preset**: `Other`
   - **Root Directory**: `Website` (or leave as root; root `vercel.json` will automatically route to `Website/`)
4. Click **Deploy**. Your storefront will be live with free global CDN and HTTPS!

#### Option B: Via Vercel CLI
```powershell
npm i -g vercel
cd Website
vercel --prod
```

---

## 🗄️ Database Configuration (Supabase)

Connected to Supabase project `Ezze Softwares`:
- **Tables**:
  - `EzzeMedicine_medicines`: Medicine catalog, pricing, category, and inventory.
  - `EzzeMedicine_orders`: Customer orders, call verification status, delivery charges, and email statuses.
  - `EzzeMedicine_order_items`: Order line items with quantity, unit prices, and subtotal.
- **RLS**: Row-Level Security is set to unrestricted for seamless anon storefront operations and authenticated admin controls.

---

## 👨‍⚕️ Admin Credentials
- **Lead Pharmacist**: Md. Imran Hasan
- **Email**: `imranhasan13421@gmail.com`
- **Store Name**: EzzeMedicine Pharmacy
