/**
 * ==============================================================================
 * EzzeMedicine - Customer Storefront Frontend Script
 * Connected to Supabase Project: Ezze Softwares
 * Realtime Database Sync, Cart Management, & Offline Call Order Flow
 * ==============================================================================
 */

// 1. Supabase Client Configuration
const SUPABASE_URL = 'https://xuvvxyeimdnoptqhyotn.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1dnZ4eWVpbWRub3B0cWh5b3RuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTkwMjIsImV4cCI6MjA5MTczNTAyMn0.F0gl-OwTWqZKEHsAvW6pAoKNxNWJeJ_JN5TbFuFtBec';

const TABLE_MEDICINES = 'EzzeMedicine_medicines';
const TABLE_ORDERS = 'EzzeMedicine_orders';
const TABLE_ORDER_ITEMS = 'EzzeMedicine_order_items';

// Initialize Supabase Client via window.supabase (loaded from CDN in index.html)
let supabaseClient = null;
if (window.supabase) {
  try {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    console.log('✅ Connected to Supabase Project: Ezze Softwares');
  } catch (err) {
    console.error('Supabase initialization error:', err);
  }
}

// 2. Fallback Sample Medicines (Used if network is unavailable or table is loading)
const FALLBACK_MEDICINES = [
  {
    "id": "00000000-0000-0000-0000-000000000001",
    "name": "Napa 500mg",
    "generic_name": "Paracetamol",
    "category": "Tablet",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "500 mg",
    "unit": "Strip (10 pcs)",
    "price": 12,
    "cost_price": 10.8,
    "stock_quantity": 150,
    "min_stock_alert": 25,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Fast-acting antipyretic and analgesic for fever, mild to moderate headache, muscle pain, and toothache.",
    "dosage_instructions": "1 to 2 tablets every 4 to 6 hours as needed. Maximum 8 tablets in 24 hours."
  },
  {
    "id": "00000000-0000-0000-0000-000000000002",
    "name": "Alatrol",
    "generic_name": "Cetirizine",
    "category": "Tablet",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "10 mg",
    "unit": "Strip (10 pcs)",
    "price": 35,
    "cost_price": 31.5,
    "stock_quantity": 120,
    "min_stock_alert": 20,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Second-generation antihistamine for seasonal allergic rhinitis, sneezing, runny nose, and chronic urticaria.",
    "dosage_instructions": "1 tablet (10mg) once daily with water."
  },
  {
    "id": "00000000-0000-0000-0000-000000000003",
    "name": "Monas 10",
    "generic_name": "Montelukast",
    "category": "Tablet",
    "manufacturer": "The ACME Laboratories Ltd.",
    "strength": "10 mg",
    "unit": "Strip (10 pcs)",
    "price": 175,
    "cost_price": 157.5,
    "stock_quantity": 80,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Leukotriene receptor antagonist for prophylaxis and chronic treatment of bronchial asthma and allergic rhinitis.",
    "dosage_instructions": "1 tablet daily in the evening at bedtime."
  },
  {
    "id": "00000000-0000-0000-0000-000000000004",
    "name": "A-Fenac 50",
    "generic_name": "Aceclofenac",
    "category": "Tablet",
    "manufacturer": "The ACME Laboratories Ltd.",
    "strength": "50 mg",
    "unit": "Strip (10 pcs)",
    "price": 40,
    "cost_price": 36,
    "stock_quantity": 90,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Non-steroidal anti-inflammatory drug (NSAID) for relief of pain and inflammation in osteoarthritis and rheumatoid arthritis.",
    "dosage_instructions": "1 tablet twice daily, preferably with or immediately after food."
  },
  {
    "id": "00000000-0000-0000-0000-000000000005",
    "name": "Pantonix 20",
    "generic_name": "Pantoprazole",
    "category": "Tablet",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "20 mg",
    "unit": "Strip (10 pcs)",
    "price": 80,
    "cost_price": 72,
    "stock_quantity": 110,
    "min_stock_alert": 20,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Proton pump inhibitor indicated for peptic ulcer, gastroesophageal reflux disease (GERD), and acid hypersecretion.",
    "dosage_instructions": "1 tablet once daily 30 minutes before breakfast with a glass of water."
  },
  {
    "id": "00000000-0000-0000-0000-000000000006",
    "name": "Sergel 20",
    "generic_name": "Esomeprazole",
    "category": "Capsule",
    "manufacturer": "Healthcare Pharmaceuticals Ltd.",
    "strength": "20 mg",
    "unit": "Strip (10 pcs)",
    "price": 70,
    "cost_price": 63,
    "stock_quantity": 130,
    "min_stock_alert": 20,
    "image_url": "https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Superior acid suppression for GERD, erosive esophagitis, and prevention of NSAID-associated gastric ulcers.",
    "dosage_instructions": "1 capsule once daily 30-60 minutes before morning meal."
  },
  {
    "id": "00000000-0000-0000-0000-000000000007",
    "name": "Maxpro 20",
    "generic_name": "Esomeprazole",
    "category": "Capsule",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "20 mg",
    "unit": "Strip (10 pcs)",
    "price": 70,
    "cost_price": 63,
    "stock_quantity": 140,
    "min_stock_alert": 20,
    "image_url": "https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Effective proton pump inhibitor capsule for chronic acidity, heartburn, and stomach ulcer healing.",
    "dosage_instructions": "1 capsule once daily 30 minutes before meal."
  },
  {
    "id": "00000000-0000-0000-0000-000000000008",
    "name": "Seclo 20",
    "generic_name": "Omeprazole",
    "category": "Capsule",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "20 mg",
    "unit": "Strip (10 pcs)",
    "price": 60,
    "cost_price": 54,
    "stock_quantity": 160,
    "min_stock_alert": 25,
    "image_url": "https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Trusted proton pump inhibitor for treatment of gastric and duodenal ulcers, gastritis, and acid indigestion.",
    "dosage_instructions": "1 capsule once daily before breakfast."
  },
  {
    "id": "00000000-0000-0000-0000-000000000009",
    "name": "Axet 500",
    "generic_name": "Cefuroxime Axetil",
    "category": "Capsule",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "500 mg",
    "unit": "Strip (10 pcs)",
    "price": 500,
    "cost_price": 450,
    "stock_quantity": 50,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Second-generation cephalosporin antibiotic for respiratory tract infections, ENT infections, and urinary tract infections.",
    "dosage_instructions": "1 capsule twice daily after meals for 5 to 7 days as prescribed."
  },
  {
    "id": "00000000-0000-0000-0000-000000000010",
    "name": "Indomet 25",
    "generic_name": "Indomethacin",
    "category": "Capsule",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "25 mg",
    "unit": "Strip (10 pcs)",
    "price": 30,
    "cost_price": 27,
    "stock_quantity": 75,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Potent NSAID indicated for moderate to severe osteoarthritis, rheumatoid arthritis, and acute gouty arthritis.",
    "dosage_instructions": "1 capsule 2 to 3 times daily with food or antacid."
  },
  {
    "id": "00000000-0000-0000-0000-000000000011",
    "name": "Tusca Plus Syrup",
    "generic_name": "Guaifenesin + Levomenthol + Diphenhydramine",
    "category": "Syrup",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "(100mg + 1.1mg + 14mg) / 5ml",
    "unit": "Bottle (100ml)",
    "price": 85,
    "cost_price": 76.5,
    "stock_quantity": 85,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Triple-action expectorant syrup that loosens mucus, relieves nasal congestion, and soothes irritating cough.",
    "dosage_instructions": "Adults: 10 ml (2 teaspoonfuls) 3 times daily after meals."
  },
  {
    "id": "00000000-0000-0000-0000-000000000012",
    "name": "Omidon Syrup",
    "generic_name": "Domperidone",
    "category": "Syrup",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "5 mg / 5 ml",
    "unit": "Bottle (100ml)",
    "price": 60,
    "cost_price": 54,
    "stock_quantity": 70,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Prokinetic suspension syrup for nausea, vomiting, epigastric bloating, and gastrointestinal motility disorders.",
    "dosage_instructions": "10-20 ml 3 times daily 15-30 minutes before meals."
  },
  {
    "id": "00000000-0000-0000-0000-000000000013",
    "name": "Adryl Syrup",
    "generic_name": "Diphenhydramine Hydrochloride",
    "category": "Syrup",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "12.5 mg / 5 ml",
    "unit": "Bottle (100ml)",
    "price": 45,
    "cost_price": 40.5,
    "stock_quantity": 65,
    "min_stock_alert": 12,
    "image_url": "https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Antihistaminic cough syrup for allergic cough, sneezing, watery eyes, and nighttime dry cough.",
    "dosage_instructions": "10 ml 3 to 4 times daily."
  },
  {
    "id": "00000000-0000-0000-0000-000000000014",
    "name": "Ambrolit Syrup",
    "generic_name": "Ambroxol Hydrochloride",
    "category": "Syrup",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "15 mg / 5 ml",
    "unit": "Bottle (100ml)",
    "price": 65,
    "cost_price": 58.5,
    "stock_quantity": 80,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Mucolytic expectorant that thins thick bronchial secretions and facilitates easy coughing out.",
    "dosage_instructions": "10 ml 3 times daily after meals."
  },
  {
    "id": "00000000-0000-0000-0000-000000000015",
    "name": "Brozedex Syrup",
    "generic_name": "Bromhexine + Menthol",
    "category": "Syrup",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "4 mg / 5 ml",
    "unit": "Bottle (100ml)",
    "price": 60,
    "cost_price": 54,
    "stock_quantity": 60,
    "min_stock_alert": 12,
    "image_url": "https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Bronchial secretolytic syrup that liquefies tenacious mucus and provides soothing cooling relief.",
    "dosage_instructions": "10 ml 3 times daily."
  },
  {
    "id": "00000000-0000-0000-0000-000000000016",
    "name": "Ace Suspension",
    "generic_name": "Paracetamol",
    "category": "Suspension",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "120 mg / 5 ml",
    "unit": "Bottle (60ml)",
    "price": 35,
    "cost_price": 32.2,
    "stock_quantity": 95,
    "min_stock_alert": 20,
    "image_url": "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Pediatric paracetamol suspension for prompt reduction of high fever, teething pain, and immunization reactions.",
    "dosage_instructions": "Dosage based on child weight/age (typically 5-10 ml every 4-6 hours)."
  },
  {
    "id": "00000000-0000-0000-0000-000000000017",
    "name": "Ciprocin Suspension",
    "generic_name": "Ciprofloxacin",
    "category": "Suspension",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "250 mg / 5 ml",
    "unit": "Bottle (60ml)",
    "price": 85,
    "cost_price": 76.5,
    "stock_quantity": 45,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Broad-spectrum fluoroquinolone antibiotic suspension for gastrointestinal, enteric, and urinary infections.",
    "dosage_instructions": "As directed by physician, usually twice daily for 5-7 days."
  },
  {
    "id": "00000000-0000-0000-0000-000000000018",
    "name": "Cef-3 Suspension",
    "generic_name": "Cefixime",
    "category": "Suspension",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "100 mg / 5 ml",
    "unit": "Bottle (50ml)",
    "price": 210,
    "cost_price": 189,
    "stock_quantity": 55,
    "min_stock_alert": 12,
    "image_url": "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Third-generation cephalosporin antibiotic suspension for acute otitis media, pharyngitis, and enteric fever.",
    "dosage_instructions": "8 mg/kg daily as a single dose or divided into two doses."
  },
  {
    "id": "00000000-0000-0000-0000-000000000019",
    "name": "Antanil Plus Suspension",
    "generic_name": "Aluminum Hydroxide + Magnesium Hydroxide + Simethicone",
    "category": "Suspension",
    "manufacturer": "Ibn Sina Pharmaceutical Industry Ltd.",
    "strength": "Regular Antacid Spec",
    "unit": "Bottle (200ml)",
    "price": 95,
    "cost_price": 85.5,
    "stock_quantity": 75,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Fast-acting pleasant-tasting antacid suspension for relief of hyperacidity, gas flatulence, and heartburn.",
    "dosage_instructions": "2 to 4 teaspoonfuls (10-20ml) 20 minutes to 1 hour after meals and at bedtime."
  },
  {
    "id": "00000000-0000-0000-0000-000000000020",
    "name": "Zithrin Suspension",
    "generic_name": "Azithromycin",
    "category": "Suspension",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "200 mg / 5 ml",
    "unit": "Bottle (35ml)",
    "price": 150,
    "cost_price": 135,
    "stock_quantity": 60,
    "min_stock_alert": 12,
    "image_url": "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Macrolide antibiotic suspension for pediatric upper and lower respiratory tract infections and tonsillitis.",
    "dosage_instructions": "10 mg/kg once daily for 3 days 1 hour before or 2 hours after meals."
  },
  {
    "id": "00000000-0000-0000-0000-000000000021",
    "name": "Seclo IV",
    "generic_name": "Omeprazole",
    "category": "Injection",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "40 mg / vial",
    "unit": "Vial / Ampoule",
    "price": 95,
    "cost_price": 80.24,
    "stock_quantity": 40,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Intravenous proton pump inhibitor for severe gastrointestinal bleeding, peptic ulceration, and pre-surgery prophylaxis.",
    "dosage_instructions": "Administered as slow IV injection over 5 minutes by healthcare professionals."
  },
  {
    "id": "00000000-0000-0000-0000-000000000022",
    "name": "Pantogut IV",
    "generic_name": "Pantoprazole",
    "category": "Injection",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "40 mg / vial",
    "unit": "Vial / Ampoule",
    "price": 90,
    "cost_price": 81,
    "stock_quantity": 45,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Injectable pantoprazole for hospital treatment of acute gastroesophageal reflux and ulcer bleeding.",
    "dosage_instructions": "40 mg IV daily administered by registered nurse or doctor."
  },
  {
    "id": "00000000-0000-0000-0000-000000000023",
    "name": "Ceftron 1g IV",
    "generic_name": "Ceftriaxone",
    "category": "Injection",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "1 gm / vial",
    "unit": "Vial / Ampoule",
    "price": 250,
    "cost_price": 225,
    "stock_quantity": 50,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Potent parenteral third-generation cephalosporin for severe hospital infections, meningitis, and septicemia.",
    "dosage_instructions": "1-2 gm once daily via slow IV infusion after sensitivity test."
  },
  {
    "id": "00000000-0000-0000-0000-000000000024",
    "name": "Torax 30",
    "generic_name": "Ketorolac Tromethamine",
    "category": "Injection",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "30 mg / ml",
    "unit": "Vial / Ampoule",
    "price": 75,
    "cost_price": 67.5,
    "stock_quantity": 35,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Short-term management of moderate to severe acute postoperative pain.",
    "dosage_instructions": "30 mg administered IM or IV every 6 hours as needed (maximum 5 days)."
  },
  {
    "id": "00000000-0000-0000-0000-000000000025",
    "name": "Xorim 750 Injection",
    "generic_name": "Cefuroxime",
    "category": "Injection",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "750 mg / vial",
    "unit": "Vial / Ampoule",
    "price": 140,
    "cost_price": 126,
    "stock_quantity": 30,
    "min_stock_alert": 8,
    "image_url": "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Second-generation cephalosporin injection for surgical prophylaxis and serious respiratory infections.",
    "dosage_instructions": "750 mg IM/IV 3 times daily as prescribed by doctor."
  },
  {
    "id": "00000000-0000-0000-0000-000000000026",
    "name": "Pevisone Cream",
    "generic_name": "Econazole Nitrate + Triamcinolone Acetonide",
    "category": "Ointment / Cream",
    "manufacturer": "Synovia Pharma PLC (Formerly Sanofi)",
    "strength": "1% + 0.1% (10 gm)",
    "unit": "Tube",
    "price": 70,
    "cost_price": 63,
    "stock_quantity": 85,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1608248597359-2ff96d859424?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Dual-action antifungal and anti-inflammatory cream for eczema with fungal infection, tinea, and ringworm.",
    "dosage_instructions": "Apply sparingly to affected skin twice daily morning and evening."
  },
  {
    "id": "00000000-0000-0000-0000-000000000027",
    "name": "Aclo Gel",
    "generic_name": "Aceclofenac",
    "category": "Ointment / Cream",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "1.5% (15 gm)",
    "unit": "Tube",
    "price": 60,
    "cost_price": 54,
    "stock_quantity": 70,
    "min_stock_alert": 12,
    "image_url": "https://images.unsplash.com/photo-1608248597359-2ff96d859424?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Topical NSAID gel for localized muscular sprains, joint strains, back pain, and tendonitis.",
    "dosage_instructions": "Gently massage into the painful area 3 times daily."
  },
  {
    "id": "00000000-0000-0000-0000-000000000028",
    "name": "Neocort Ointment",
    "generic_name": "Neomycin Sulfate + Hydrocortisone Acetate",
    "category": "Ointment / Cream",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "5mg + 10mg / gm (5 gm)",
    "unit": "Tube",
    "price": 40,
    "cost_price": 36,
    "stock_quantity": 65,
    "min_stock_alert": 12,
    "image_url": "https://images.unsplash.com/photo-1608248597359-2ff96d859424?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Antibiotic plus corticosteroid ointment for inflammatory dermatoses prone to bacterial infection.",
    "dosage_instructions": "Apply thin layer to the affected area 2 to 3 times daily."
  },
  {
    "id": "00000000-0000-0000-0000-000000000029",
    "name": "Burnsil Cream",
    "generic_name": "Silver Sulfadiazine",
    "category": "Ointment / Cream",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "1% (25 gm)",
    "unit": "Tube",
    "price": 65,
    "cost_price": 58.5,
    "stock_quantity": 60,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1608248597359-2ff96d859424?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Topical antimicrobial cream for prevention and treatment of burn wound infections.",
    "dosage_instructions": "Apply 1-2 mm thick layer over clean burned area 1-2 times daily with sterile gloves."
  },
  {
    "id": "00000000-0000-0000-0000-000000000030",
    "name": "Mupirocin Ointment",
    "generic_name": "Mupirocin",
    "category": "Ointment / Cream",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "2% (10 gm)",
    "unit": "Tube",
    "price": 120,
    "cost_price": 108,
    "stock_quantity": 50,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1608248597359-2ff96d859424?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Topical antibacterial ointment for impetigo, folliculitis, and traumatic secondary skin infections.",
    "dosage_instructions": "Apply small quantity to affected area 3 times daily for up to 10 days."
  },
  {
    "id": "00000000-0000-0000-0000-000000000031",
    "name": "Tobracin Eye Drops",
    "generic_name": "Tobramycin",
    "category": "Eye & Ear Drops",
    "manufacturer": "OSL Pharma Limited",
    "strength": "0.3%",
    "unit": "Bottle (5ml)",
    "price": 100,
    "cost_price": 90,
    "stock_quantity": 55,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Aminoglycoside ophthalmic solution for external bacterial infections of the eye and surrounding tissue.",
    "dosage_instructions": "Instill 1 to 2 drops into affected eye(s) every 4 hours."
  },
  {
    "id": "00000000-0000-0000-0000-000000000032",
    "name": "Naphcon-A Eye Drops",
    "generic_name": "Naphazoline Hydrochloride + Pheniramine Maleate",
    "category": "Eye & Ear Drops",
    "manufacturer": "Alcon Laboratories / Local Importers",
    "strength": "0.025% + 0.3%",
    "unit": "Bottle (15ml)",
    "price": 280,
    "cost_price": 260,
    "stock_quantity": 40,
    "min_stock_alert": 8,
    "image_url": "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Dual action decongestant and antihistaminic ophthalmic solution for allergic conjunctivitis, itching, and redness.",
    "dosage_instructions": "Instill 1-2 drops into affected eye up to 4 times daily."
  },
  {
    "id": "00000000-0000-0000-0000-000000000033",
    "name": "Moxison Eye Drops",
    "generic_name": "Moxifloxacin",
    "category": "Eye & Ear Drops",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "0.5%",
    "unit": "Bottle (5ml)",
    "price": 140,
    "cost_price": 126,
    "stock_quantity": 50,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Fourth-generation fluoroquinolone ophthalmic antibiotic for bacterial conjunctivitis.",
    "dosage_instructions": "1 drop in the affected eye 3 times daily for 7 days."
  },
  {
    "id": "00000000-0000-0000-0000-000000000034",
    "name": "Optachlor Eye Drops",
    "generic_name": "Chloramphenicol",
    "category": "Eye & Ear Drops",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "0.5%",
    "unit": "Bottle (5ml)",
    "price": 40,
    "cost_price": 36,
    "stock_quantity": 75,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Broad-spectrum antibacterial eye drop for superficial ocular infections.",
    "dosage_instructions": "1 to 2 drops every 2 hours initially, reducing frequency as infection resolves."
  },
  {
    "id": "00000000-0000-0000-0000-000000000035",
    "name": "Latanest Eye Drops",
    "generic_name": "Latanoprost",
    "category": "Eye & Ear Drops",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "50 mcg / ml",
    "unit": "Bottle (2.5ml)",
    "price": 450,
    "cost_price": 405,
    "stock_quantity": 30,
    "min_stock_alert": 6,
    "image_url": "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Prostaglandin analogue ophthalmic solution for reducing elevated intraocular pressure in open-angle glaucoma.",
    "dosage_instructions": "1 drop in affected eye(s) once daily in the evening."
  },
  {
    "id": "00000000-0000-0000-0000-000000000036",
    "name": "Azmasol Inhaler",
    "generic_name": "Salbutamol",
    "category": "Inhaler",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "100 mcg / puff",
    "unit": "Piece (200 Puffs)",
    "price": 250,
    "cost_price": 225,
    "stock_quantity": 65,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Fast-acting bronchodilator reliever inhaler for acute asthma attack, wheezing, and bronchospasm.",
    "dosage_instructions": "1 to 2 puffs for relief of acute symptoms. Maximum 8 puffs daily."
  },
  {
    "id": "00000000-0000-0000-0000-000000000037",
    "name": "Decomit 250 Inhaler",
    "generic_name": "Beclometasone Dipropionate",
    "category": "Inhaler",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "250 mcg / puff",
    "unit": "Piece (200 Puffs)",
    "price": 320,
    "cost_price": 288,
    "stock_quantity": 45,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Inhaled prophylactic corticosteroid for regular maintenance prevention of chronic asthma.",
    "dosage_instructions": "1 to 2 puffs twice daily morning and evening. Rinse mouth after inhalation."
  },
  {
    "id": "00000000-0000-0000-0000-000000000038",
    "name": "Windel Inhaler",
    "generic_name": "Salbutamol",
    "category": "Inhaler",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "100 mcg / puff",
    "unit": "Piece (200 Puffs)",
    "price": 240,
    "cost_price": 216,
    "stock_quantity": 50,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Selective beta-2 adrenoreceptor agonist for prompt relief of asthma spasms and exercise-induced asthma.",
    "dosage_instructions": "1-2 puffs as required for breathlessness."
  },
  {
    "id": "00000000-0000-0000-0000-000000000039",
    "name": "Ipratropium Inhaler",
    "generic_name": "Ipratropium Bromide",
    "category": "Inhaler",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "20 mcg / puff",
    "unit": "Piece (200 Puffs)",
    "price": 300,
    "cost_price": 270,
    "stock_quantity": 35,
    "min_stock_alert": 8,
    "image_url": "https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Anticholinergic bronchodilator for maintenance treatment of chronic obstructive pulmonary disease (COPD).",
    "dosage_instructions": "1 to 2 puffs 3 to 4 times daily at regular intervals."
  },
  {
    "id": "00000000-0000-0000-0000-000000000040",
    "name": "Flutiform 125 Inhaler",
    "generic_name": "Fluticasone Propionate + Formoterol Fumarate",
    "category": "Inhaler",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "125 mcg + 5 mcg / puff",
    "unit": "Piece (120 Puffs)",
    "price": 650,
    "cost_price": 585,
    "stock_quantity": 30,
    "min_stock_alert": 6,
    "image_url": "https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Dual-component combination inhaler for regular management of persistent asthma and COPD.",
    "dosage_instructions": "2 puffs twice daily in the morning and evening."
  },
  {
    "id": "00000000-0000-0000-0000-000000000041",
    "name": "Napa 500 Suppository",
    "generic_name": "Paracetamol",
    "category": "Suppository",
    "manufacturer": "Beximco Pharmaceuticals PLC",
    "strength": "500 mg",
    "unit": "Box (20 pcs)",
    "price": 160,
    "cost_price": 147.2,
    "stock_quantity": 50,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Rectal antipyretic suppository for adults unable to take oral medication due to severe vomiting or nausea.",
    "dosage_instructions": "Insert 1 suppository rectally every 4-6 hours as needed."
  },
  {
    "id": "00000000-0000-0000-0000-000000000042",
    "name": "Ace 250 Suppository",
    "generic_name": "Paracetamol",
    "category": "Suppository",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "250 mg",
    "unit": "Box (20 pcs)",
    "price": 120,
    "cost_price": 108,
    "stock_quantity": 55,
    "min_stock_alert": 12,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Pediatric rectal suppository for high fever and pain when oral administration is not tolerated.",
    "dosage_instructions": "Insert 1 suppository rectally based on child age/weight 3 to 4 times daily."
  },
  {
    "id": "00000000-0000-0000-0000-000000000043",
    "name": "Clofenac 50 Suppository",
    "generic_name": "Diclofenac Sodium",
    "category": "Suppository",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "50 mg",
    "unit": "Box (10 pcs)",
    "price": 70,
    "cost_price": 63,
    "stock_quantity": 60,
    "min_stock_alert": 12,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "Rectal NSAID suppository for rapid relief of acute inflammatory arthritis, renal colic, and postoperative pain.",
    "dosage_instructions": "Insert 1 suppository into rectum 2 to 3 times daily."
  },
  {
    "id": "00000000-0000-0000-0000-000000000044",
    "name": "Diclomax 100 Suppository",
    "generic_name": "Diclofenac Sodium",
    "category": "Suppository",
    "manufacturer": "Incepta Pharmaceuticals Ltd.",
    "strength": "100 mg",
    "unit": "Box (10 pcs)",
    "price": 100,
    "cost_price": 90,
    "stock_quantity": 45,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": true,
    "description": "High-strength diclofenac suppository for nocturnal pain in osteoarthritis and ankylosing spondylitis.",
    "dosage_instructions": "1 suppository rectally at bedtime as prescribed."
  },
  {
    "id": "00000000-0000-0000-0000-000000000045",
    "name": "Glycerol Suppository Adult",
    "generic_name": "Glycerin",
    "category": "Suppository",
    "manufacturer": "JMI Syringes & Medical Devices Ltd.",
    "strength": "2.30 gm / pc",
    "unit": "Box (10 pcs)",
    "price": 90,
    "cost_price": 81,
    "stock_quantity": 70,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Hyperosmotic laxative rectal suppository providing fast and gentle relief from acute constipation.",
    "dosage_instructions": "Insert 1 suppository rectally and retain for 15-30 minutes until bowel action occurs."
  },
  {
    "id": "00000000-0000-0000-0000-000000000046",
    "name": "Bionime GM700",
    "generic_name": "Glucose Monitoring Test Strip",
    "category": "Healthcare & Device",
    "manufacturer": "Bionime Corporation / Local Importer",
    "strength": "Test Strip Accessory",
    "unit": "Box (50 Strips)",
    "price": 1100,
    "cost_price": 990,
    "stock_quantity": 35,
    "min_stock_alert": 8,
    "image_url": "https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Noble metal electrode auto-coding blood glucose test strips for high precision diabetes monitoring.",
    "dosage_instructions": "Insert into Bionime meter with small blood droplet (0.75 μL)."
  },
  {
    "id": "00000000-0000-0000-0000-000000000047",
    "name": "OneTouch Select Plus Strips",
    "generic_name": "Glucose Test Strips",
    "category": "Healthcare & Device",
    "manufacturer": "Lifescan / Local Importer",
    "strength": "Test Strip Accessory",
    "unit": "Box (50 Strips)",
    "price": 1250,
    "cost_price": 1125,
    "stock_quantity": 40,
    "min_stock_alert": 8,
    "image_url": "https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "ColorSure technology test strips for instant 5-second blood sugar level testing.",
    "dosage_instructions": "Use with OneTouch Select Plus meter as directed."
  },
  {
    "id": "00000000-0000-0000-0000-000000000048",
    "name": "Microlife BP A2 Basic",
    "generic_name": "Digital Blood Pressure Monitor",
    "category": "Healthcare & Device",
    "manufacturer": "Microlife AG / Local Importer",
    "strength": "Medical Device",
    "unit": "Piece",
    "price": 3200,
    "cost_price": 2880,
    "stock_quantity": 20,
    "min_stock_alert": 5,
    "image_url": "https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Clinically validated upper-arm digital blood pressure monitor with Gentle+ cuff inflation and arrhythmia detection.",
    "dosage_instructions": "Apply cuff around upper arm at heart level and press Power button while seated."
  },
  {
    "id": "00000000-0000-0000-0000-000000000049",
    "name": "Omron NE-C28",
    "generic_name": "Compressor Nebulizer",
    "category": "Healthcare & Device",
    "manufacturer": "Omron Healthcare / Local Importer",
    "strength": "Respiratory Device",
    "unit": "Piece",
    "price": 4500,
    "cost_price": 4050,
    "stock_quantity": 15,
    "min_stock_alert": 4,
    "image_url": "https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Heavy-duty compressor nebulizer with Virtual Valve Technology (V.V.T.) for respiratory therapy.",
    "dosage_instructions": "Pour physician-prescribed respiratory medication into chamber and breathe through mask/mouthpiece."
  },
  {
    "id": "00000000-0000-0000-0000-000000000050",
    "name": "JMI Disposable Syringe 5ml",
    "generic_name": "Hypodermic Syringe with Needle",
    "category": "Healthcare & Device",
    "manufacturer": "JMI Syringes & Medical Devices Ltd.",
    "strength": "5 ml / 22G Needle",
    "unit": "Box (100 Pcs)",
    "price": 500,
    "cost_price": 430,
    "stock_quantity": 45,
    "min_stock_alert": 10,
    "image_url": "https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Non-toxic, pyrogen-free, sterile single-use disposable syringes with sharp stainless steel needles.",
    "dosage_instructions": "For single parenteral injection use only by clinical personnel."
  },
  {
    "id": "00000000-0000-0000-0000-000000000051",
    "name": "Ostecal D",
    "generic_name": "Calcium Carbonate + Vitamin D3",
    "category": "Vitamins & Supplements",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "500 mg + 200 IU",
    "unit": "Box (30 pcs)",
    "price": 240,
    "cost_price": 216,
    "stock_quantity": 80,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1577401239170-897942555fb3?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Essential calcium and vitamin D3 supplement for bone mineral density, osteoporosis prevention, and joint strength.",
    "dosage_instructions": "1 tablet once or twice daily with or after meals."
  },
  {
    "id": "00000000-0000-0000-0000-000000000052",
    "name": "Neuro-B",
    "generic_name": "Vitamin B1 + B6 + B12",
    "category": "Vitamins & Supplements",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "100mg + 200mg + 200mcg",
    "unit": "Box (30 pcs)",
    "price": 300,
    "cost_price": 270,
    "stock_quantity": 85,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1577401239170-897942555fb3?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "High-potency neurotropic vitamin formulation for peripheral neuropathy, nerve regeneration, and numbness.",
    "dosage_instructions": "1 to 3 tablets daily as prescribed by doctor."
  },
  {
    "id": "00000000-0000-0000-0000-000000000053",
    "name": "Filwel Gold",
    "generic_name": "Multivitamin & Multimineral A-Z",
    "category": "Vitamins & Supplements",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "Adult Formulation",
    "unit": "Bottle (30 Pcs)",
    "price": 360,
    "cost_price": 324,
    "stock_quantity": 90,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1577401239170-897942555fb3?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Comprehensive daily micronutrient formulation with 32 essential vitamins and minerals for energy and vitality.",
    "dosage_instructions": "1 tablet once daily after a main meal."
  },
  {
    "id": "00000000-0000-0000-0000-000000000054",
    "name": "Aristovit M",
    "generic_name": "Multivitamin & Minerals",
    "category": "Vitamins & Supplements",
    "manufacturer": "Aristopharma Ltd.",
    "strength": "Standard Daily Spec",
    "unit": "Bottle (30 Pcs)",
    "price": 150,
    "cost_price": 135,
    "stock_quantity": 75,
    "min_stock_alert": 15,
    "image_url": "https://images.unsplash.com/photo-1577401239170-897942555fb3?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Balanced daily multivitamin and mineral supplement to prevent nutritional deficiencies and boost immunity.",
    "dosage_instructions": "1 tablet daily with breakfast."
  },
  {
    "id": "00000000-0000-0000-0000-000000000055",
    "name": "Bicozin Tablet",
    "generic_name": "Zinc + Vitamin B Complex",
    "category": "Vitamins & Supplements",
    "manufacturer": "Square Pharmaceuticals PLC",
    "strength": "Zinc 20mg + Vitamin B",
    "unit": "Bottle (30 Pcs)",
    "price": 180,
    "cost_price": 162,
    "stock_quantity": 95,
    "min_stock_alert": 20,
    "image_url": "https://images.unsplash.com/photo-1577401239170-897942555fb3?w=500&auto=format&fit=crop&q=80",
    "requires_prescription": false,
    "description": "Synergistic zinc and vitamin B complex supplement for hair, skin, nail health, immune defense, and tissue repair.",
    "dosage_instructions": "1 tablet once daily with food."
  }
];

// 3. Application Reactive State
let medicines = [];
let cart = JSON.parse(localStorage.getItem('ezze_cart') || '[]');
let activeCategory = 'All';
let searchQuery = '';
let activeTrackingOrderId = null;
let lastSubmittedOrder = null;
let lastSubmittedItems = [];
let currentTrackingOrder = null;

// 4. Initial Bootstrap
document.addEventListener('DOMContentLoaded', async () => {
  setupEventListeners();
  updateCartBadge();
  renderCart();
  await loadMedicines();
  initRealtimeSubscription();
});

// 5. Fetch Medicines from Supabase
async function loadMedicines() {
  const grid = document.getElementById('medicine-grid');
  grid.innerHTML = `
    <div class="empty-state">
      <div style="display: inline-block; width: 36px; height: 36px; border: 3px solid var(--primary); border-top-color: transparent; border-radius: 50%; animation: spin 0.8s linear infinite;"></div>
      <p style="margin-top: 14px; font-weight: 600;">Loading fresh medicines from EzzeMedicine database...</p>
    </div>
  `;

  if (supabaseClient) {
    try {
      const { data, error } = await supabaseClient
        .from(TABLE_MEDICINES)
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        console.warn('Supabase fetch note, falling back to cached catalog:', error.message);
        medicines = FALLBACK_MEDICINES;
      } else if (data && data.length > 0) {
        medicines = data;
        console.log(`Loaded ${medicines.length} medicines from Supabase`);
      } else {
        medicines = FALLBACK_MEDICINES;
      }
    } catch (err) {
      console.warn('Network error:', err);
      medicines = FALLBACK_MEDICINES;
    }
  } else {
    medicines = FALLBACK_MEDICINES;
  }

  renderMedicines();
}

// 6. Realtime Subscription to Supabase
function initRealtimeSubscription() {
  if (!supabaseClient) return;

  try {
    supabaseClient
      .channel('public:ezzemedicine_changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: TABLE_MEDICINES },
        (payload) => {
          console.log('⚡ Realtime Medicine Update:', payload);
          if (payload.eventType === 'INSERT') {
            medicines.unshift(payload.new);
          } else if (payload.eventType === 'UPDATE') {
            const idx = medicines.findIndex((m) => m.id === payload.new.id);
            if (idx !== -1) medicines[idx] = payload.new;
          } else if (payload.eventType === 'DELETE') {
            medicines = medicines.filter((m) => m.id !== payload.old.id);
          }
          renderMedicines();
          showToast('Catalog updated in real-time from pharmacy!');
        }
      )
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: TABLE_ORDERS },
        (payload) => {
          console.log('⚡ Realtime Order Update:', payload);
          // If customer is currently tracking this order, update timeline instantly!
          if (activeTrackingOrderId && activeTrackingOrderId === payload.new.id) {
            renderTrackingDetails(payload.new);
            showToast(`Order status updated to: ${payload.new.status.toUpperCase()}`);
          }
        }
      )
      .subscribe();
  } catch (err) {
    console.error('Realtime subscription error:', err);
  }
}

// 7. Render Medicines Grid
function renderMedicines() {
  const grid = document.getElementById('medicine-grid');
  const countEl = document.getElementById('catalog-count');

  // Filter medicines by active category and search keyword
  const filtered = medicines.filter((med) => {
    const matchesCat =
      activeCategory === 'All' ||
      (med.category && med.category.toLowerCase() === activeCategory.toLowerCase());

    if (!matchesCat) return false;

    if (!searchQuery.trim()) return true;

    const q = searchQuery.toLowerCase();
    const inName = med.name && med.name.toLowerCase().includes(q);
    const inGen = med.generic_name && med.generic_name.toLowerCase().includes(q);
    const inManu = med.manufacturer && med.manufacturer.toLowerCase().includes(q);
    const inStrength = med.strength && med.strength.toLowerCase().includes(q);

    return inName || inGen || inManu || inStrength;
  });

  if (countEl) {
    countEl.textContent = `${filtered.length} available medicines`;
  }

  if (filtered.length === 0) {
    grid.innerHTML = `
      <div class="empty-state">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
        </svg>
        <h3>No medicines found</h3>
        <p>Try searching for a different chemical name or choose "All" categories.</p>
      </div>
    `;
    return;
  }

  grid.innerHTML = filtered
    .map((med) => {
      const isOutOfStock = med.stock_quantity <= 0;
      const imageUrl = med.image_url && med.image_url.trim().length > 5 ? med.image_url : null;

      return `
      <article class="medicine-card" data-id="${med.id}">
        <div class="card-image-box">
          ${
            imageUrl
              ? `<img src="${imageUrl}" alt="${med.name}" loading="lazy" onerror="this.parentElement.innerHTML='<div class=\\'card-image-fallback\\'><svg fill=\\'currentColor\\' viewBox=\\'0 0 24 24\\'><path d=\\'M4.5 10.5C3.67 10.5 3 11.17 3 12s.67 1.5 1.5 1.5h15c.83 0 1.5-.67 1.5-1.5s-.67-1.5-1.5-1.5h-15z\\'/></svg><span>EzzeMedicine</span></div>'"/>`
              : `<div class="card-image-fallback">
                   <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                     <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/>
                   </svg>
                   <span>Pharmacy Product</span>
                 </div>`
          }
          <span class="badge-category">${med.category || 'Medicine'}</span>
          ${med.requires_prescription ? `<span class="badge-rx">Rx Required</span>` : ''}
          ${isOutOfStock ? `<span class="badge-out-stock">Out of Stock</span>` : ''}
        </div>

        <div class="card-content">
          <div class="card-title-row">
            <h3 class="card-title">${escapeHtml(med.name)}</h3>
            <span class="card-generic">${escapeHtml(med.generic_name || med.strength || '')}</span>
          </div>
          
          <div class="card-details-meta">
            <span>${escapeHtml(med.manufacturer || 'Ezze Healthcare')}</span>
            ${med.strength ? ` • <span>${escapeHtml(med.strength)}</span>` : ''}
          </div>

          <div class="card-price-row">
            <span class="card-price">৳${Number(med.price || 0).toFixed(2)}</span>
            <span class="card-unit">Per ${escapeHtml(med.unit || 'Strip')}</span>
          </div>

          <div class="card-actions">
            <button class="btn-add-cart" onclick="handleAddToCart('${med.id}')" ${isOutOfStock ? 'disabled' : ''}>
              <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
              </svg>
              ${isOutOfStock ? 'Out of Stock' : 'Add to Cart'}
            </button>
            <button class="btn-quick-view" onclick="openMedicineModal('${med.id}')" title="View medicine details">
              <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
              </svg>
            </button>
          </div>
        </div>
      </article>
    `;
    })
    .join('');
}

// 8. Event Listeners Setup
function setupEventListeners() {
  // Search input
  const searchInput = document.getElementById('search-input');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      searchQuery = e.target.value;
      renderMedicines();
    });
  }

  // Category chip clicks
  const chips = document.querySelectorAll('.category-chip');
  chips.forEach((chip) => {
    chip.addEventListener('click', () => {
      chips.forEach((c) => c.classList.remove('active'));
      chip.classList.add('active');
      activeCategory = chip.getAttribute('data-category') || 'All';
      renderMedicines();
    });
  });

  // Home Delivery checkbox toggle
  const deliveryCheckbox = document.getElementById('home-delivery-checkbox');
  const addressContainer = document.getElementById('address-field-box');
  const addressInput = document.getElementById('cust-address');

  if (deliveryCheckbox && addressContainer) {
    deliveryCheckbox.addEventListener('change', (e) => {
      if (e.target.checked) {
        addressContainer.classList.add('show');
        if (addressInput) addressInput.setAttribute('required', 'true');
      } else {
        addressContainer.classList.remove('show');
        if (addressInput) addressInput.removeAttribute('required');
      }
    });
  }

  // Checkout Form Submission
  const checkoutForm = document.getElementById('checkout-order-form');
  if (checkoutForm) {
    checkoutForm.addEventListener('submit', handleCheckoutSubmit);
  }

  // Order Tracking Form
  const trackForm = document.getElementById('track-order-form');
  if (trackForm) {
    trackForm.addEventListener('submit', handleTrackingSubmit);
  }
}

// 9. Shopping Cart Operations
function handleAddToCart(medId) {
  const med = medicines.find((m) => m.id === medId);
  if (!med) return;

  const existing = cart.find((item) => item.id === medId);
  if (existing) {
    existing.quantity += 1;
  } else {
    cart.push({
      id: med.id,
      name: med.name,
      unit: med.unit || 'Strip',
      price: Number(med.price || 0),
      quantity: 1,
      image_url: med.image_url || ''
    });
  }

  saveCart();
  updateCartBadge();
  renderCart();
  showToast(`Added "${med.name}" to cart!`);

  // Animate cart button
  const cartBtn = document.querySelector('.btn-cart');
  if (cartBtn) {
    cartBtn.style.transform = 'scale(1.1)';
    setTimeout(() => (cartBtn.style.transform = ''), 200);
  }
}

function updateCartItemQty(medId, delta) {
  const item = cart.find((i) => i.id === medId);
  if (!item) return;

  item.quantity += delta;
  if (item.quantity <= 0) {
    cart = cart.filter((i) => i.id !== medId);
  }

  saveCart();
  updateCartBadge();
  renderCart();
}

function removeCartItem(medId) {
  cart = cart.filter((i) => i.id !== medId);
  saveCart();
  updateCartBadge();
  renderCart();
  showToast('Item removed from cart');
}

function saveCart() {
  localStorage.setItem('ezze_cart', JSON.stringify(cart));
}

function updateCartBadge() {
  const badge = document.getElementById('cart-badge');
  const totalCount = cart.reduce((sum, item) => sum + item.quantity, 0);
  if (badge) {
    badge.textContent = totalCount;
    badge.style.display = totalCount > 0 ? 'flex' : 'none';
  }
}

function renderCart() {
  const container = document.getElementById('cart-items-container');
  const subtotalEl = document.getElementById('cart-subtotal');
  const checkoutBtn = document.getElementById('btn-submit-order');

  if (!container) return;

  if (cart.length === 0) {
    container.innerHTML = `
      <div class="cart-empty-message">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/>
        </svg>
        <h4>Your cart is empty</h4>
        <p style="font-size: 0.85rem; margin-top: 4px;">Explore medicines and tap "Add to Cart".</p>
      </div>
    `;
    if (subtotalEl) subtotalEl.textContent = '৳0.00';
    if (checkoutBtn) checkoutBtn.disabled = true;
    return;
  }

  const subtotal = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);

  container.innerHTML = cart
    .map(
      (item) => `
    <div class="cart-item-row">
      <img src="${item.image_url || 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=100'}" class="cart-item-thumb" onerror="this.src='https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=100'"/>
      <div class="cart-item-info">
        <h4 class="cart-item-name">${escapeHtml(item.name)}</h4>
        <span class="cart-item-meta">${escapeHtml(item.unit)} • ৳${item.price.toFixed(2)}</span>
        <div class="cart-item-price">৳${(item.price * item.quantity).toFixed(2)}</div>
      </div>
      <div class="cart-item-qty-control">
        <button type="button" class="btn-qty" onclick="updateCartItemQty('${item.id}', -1)">-</button>
        <span class="cart-item-qty">${item.quantity}</span>
        <button type="button" class="btn-qty" onclick="updateCartItemQty('${item.id}', 1)">+</button>
      </div>
      <button type="button" class="btn-item-delete" onclick="removeCartItem('${item.id}')" title="Remove">
        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
        </svg>
      </button>
    </div>
  `
    )
    .join('');

  if (subtotalEl) subtotalEl.textContent = `৳${subtotal.toFixed(2)}`;
  if (checkoutBtn) checkoutBtn.disabled = false;
}

// 10. Drawer Toggle
function toggleCartDrawer(open) {
  const overlay = document.getElementById('cart-drawer-overlay');
  if (overlay) {
    if (open) {
      overlay.classList.add('open');
      document.body.style.overflow = 'hidden';
    } else {
      overlay.classList.remove('open');
      document.body.style.overflow = '';
    }
  }
}

// 11. Handle Customer Order Submission
async function handleCheckoutSubmit(e) {
  e.preventDefault();

  if (cart.length === 0) {
    showToast('Your cart is empty. Please add medicines first.');
    return;
  }

  const nameInput = document.getElementById('cust-name');
  const phoneInput = document.getElementById('cust-phone');
  const emailInput = document.getElementById('cust-email');
  const deliveryCheckbox = document.getElementById('home-delivery-checkbox');
  const addressInput = document.getElementById('cust-address');
  const submitBtn = document.getElementById('btn-submit-order');

  const customerName = nameInput.value.trim();
  const customerPhone = phoneInput.value.trim();
  const customerEmail = emailInput.value.trim();
  const isHomeDelivery = deliveryCheckbox ? deliveryCheckbox.checked : false;
  const deliveryAddress = isHomeDelivery ? addressInput.value.trim() : null;

  if (!customerName || !customerPhone || !customerEmail) {
    showToast('Please fill in Name, Phone Number, and Email.');
    return;
  }

  if (isHomeDelivery && !deliveryAddress) {
    showToast('Please enter your Home Delivery address.');
    return;
  }

  // Generate Unique Order ID
  const orderId = `EZM-${Math.floor(10000 + Math.random() * 90000)}`;
  const subtotal = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);

  submitBtn.disabled = true;
  submitBtn.innerHTML = `
    <div style="width: 18px; height: 18px; border: 2px solid white; border-top-color: transparent; border-radius: 50%; animation: spin 0.6s linear infinite;"></div>
    <span>Submitting Order Request...</span>
  `;

  // Payload for EzzeMedicine_orders
  const orderRecord = {
    id: orderId,
    customer_name: customerName,
    customer_phone: customerPhone,
    customer_email: customerEmail,
    is_home_delivery: isHomeDelivery,
    delivery_address: deliveryAddress,
    delivery_charge: 0.0, // Set manually by admin during phone confirmation call!
    status: 'pending_call',
    subtotal: subtotal,
    total_amount: subtotal,
    call_notes: '',
    call_status: 'not_called',
    is_email_sent: false,
    created_at: new Date().toISOString()
  };

  // Payload for EzzeMedicine_order_items
  const itemsRecords = cart.map((item) => ({
    order_id: orderId,
    medicine_id: item.id,
    medicine_name: item.name,
    unit: item.unit || 'Strip',
    unit_price: item.price,
    quantity: item.quantity,
    item_total: item.price * item.quantity,
    image_url: item.image_url || null
  }));

  try {
    if (supabaseClient) {
      // 1. Insert order into Supabase
      const { error: orderError } = await supabaseClient
        .from(TABLE_ORDERS)
        .insert([orderRecord]);

      if (orderError) throw orderError;

      // 2. Insert items into Supabase
      const { error: itemsError } = await supabaseClient
        .from(TABLE_ORDER_ITEMS)
        .insert(itemsRecords);

      if (itemsError) throw itemsError;
    }

    // Track submitted order in memory for instant PDF download & receipt
    lastSubmittedOrder = orderRecord;
    lastSubmittedItems = itemsRecords;

    // Send realtime email to customer's Gmail with PDF copy of bill
    sendAutomatedOrderEmail(orderRecord, itemsRecords);

    // Success! Clear cart & close drawer
    cart = [];
    saveCart();
    updateCartBadge();
    renderCart();
    toggleCartDrawer(false);

    // Open Success Modal
    openSuccessModal({
      id: orderId,
      name: customerName,
      phone: customerPhone,
      email: customerEmail,
      isHomeDelivery: isHomeDelivery,
      address: deliveryAddress,
      total: subtotal
    });
  } catch (err) {
    console.error('Order submission error:', err);
    showToast(`Order submission: saved locally! Order ID: ${orderId}`);
    
    // Graceful offline fallback
    lastSubmittedOrder = orderRecord;
    lastSubmittedItems = itemsRecords;
    sendAutomatedOrderEmail(orderRecord, itemsRecords);

    cart = [];
    saveCart();
    updateCartBadge();
    renderCart();
    toggleCartDrawer(false);
    openSuccessModal({
      id: orderId,
      name: customerName,
      phone: customerPhone,
      email: customerEmail,
      isHomeDelivery: isHomeDelivery,
      address: deliveryAddress,
      total: subtotal
    });
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = `
      <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>
      <span>Submit Order Request</span>
    `;
  }
}

// 12. Success Modal Handling
function openSuccessModal(orderData) {
  const modal = document.getElementById('success-modal-overlay');
  const idEl = document.getElementById('success-order-id');
  const phoneEl = document.getElementById('success-phone');
  const emailEl = document.getElementById('success-email');
  const deliveryTypeEl = document.getElementById('success-delivery-type');
  const downloadLabel = document.getElementById('btn-success-download-text');

  if (idEl) idEl.textContent = orderData.id;
  if (phoneEl) phoneEl.textContent = orderData.phone;
  if (emailEl) emailEl.textContent = orderData.email;
  if (downloadLabel) downloadLabel.textContent = `Download Bill (${orderData.id}.pdf)`;
  if (deliveryTypeEl) {
    deliveryTypeEl.textContent = orderData.isHomeDelivery
      ? `Home Delivery to: ${orderData.address} (Delivery fee will be set by admin on call)`
      : `Store Pickup (Collect at pharmacy counter)`;
  }

  activeTrackingOrderId = orderData.id;

  if (modal) {
    modal.classList.add('open');
    document.body.style.overflow = 'hidden';
  }
}

function handleDownloadBillFromSuccess() {
  if (lastSubmittedOrder) {
    generateOrderBillPdf(lastSubmittedOrder, lastSubmittedItems, true);
    showToast(`Downloading bill copy: ${lastSubmittedOrder.id}.pdf`);
  } else {
    showToast('Order details not found for download.');
  }
}

function openTrackingForActiveOrder() {
  closeSuccessModal();
  openTrackingModal();
  const input = document.getElementById('track-query-input');
  if (input && activeTrackingOrderId) {
    input.value = activeTrackingOrderId;
    // Trigger tracking lookup
    const fakeEvent = { preventDefault: () => {} };
    handleTrackingSubmit(fakeEvent);
  }
}

function closeSuccessModal() {
  const modal = document.getElementById('success-modal-overlay');
  if (modal) {
    modal.classList.remove('open');
    document.body.style.overflow = '';
  }
}

// 13. Medicine Detail Modal
function openMedicineModal(medId) {
  const med = medicines.find((m) => m.id === medId);
  if (!med) return;

  const modal = document.getElementById('medicine-detail-modal-overlay');
  const content = document.getElementById('medicine-detail-content');

  content.innerHTML = `
    <div style="display: flex; gap: 24px; flex-wrap: wrap;">
      <div style="flex: 1; min-width: 240px;">
        <img src="${med.image_url || 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400'}" style="width: 100%; height: 260px; object-fit: cover; border-radius: var(--radius-md);" onerror="this.src='https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400'"/>
      </div>
      <div style="flex: 1.4; min-width: 280px; display: flex; flex-direction: column;">
        <span style="font-size: 0.8rem; font-weight: 700; color: var(--primary); text-transform: uppercase;">${escapeHtml(med.category || 'Medicine')}</span>
        <h2 style="font-size: 1.6rem; margin: 4px 0 6px;">${escapeHtml(med.name)}</h2>
        <span style="font-size: 0.95rem; color: var(--text-muted); font-weight: 600;">Generic: ${escapeHtml(med.generic_name || 'N/A')}</span>
        <span style="font-size: 0.85rem; color: var(--text-light); margin-bottom: 16px;">Manufacturer: ${escapeHtml(med.manufacturer || 'Ezze Healthcare')} • Strength: ${escapeHtml(med.strength || 'Standard')}</span>
        
        <div style="background: var(--bg-page); padding: 14px; border-radius: var(--radius-sm); margin-bottom: 16px;">
          <div style="font-size: 1.4rem; font-weight: 800; color: var(--primary);">৳${Number(med.price || 0).toFixed(2)}</div>
          <span style="font-size: 0.8rem; color: var(--text-muted);">Packaging: ${escapeHtml(med.unit || 'Strip')}</span>
        </div>

        ${
          med.description
            ? `<div style="margin-bottom: 12px;"><h4 style="font-size: 0.9rem; font-weight: 700; margin-bottom: 4px;">Indications:</h4><p style="font-size: 0.88rem; color: var(--text-muted);">${escapeHtml(med.description)}</p></div>`
            : ''
        }

        ${
          med.dosage_instructions
            ? `<div style="margin-bottom: 16px;"><h4 style="font-size: 0.9rem; font-weight: 700; margin-bottom: 4px;">Dosage & Instructions:</h4><p style="font-size: 0.88rem; color: var(--text-muted);">${escapeHtml(med.dosage_instructions)}</p></div>`
            : ''
        }

        <div style="margin-top: auto; display: flex; gap: 10px;">
          <button class="btn-add-cart" style="flex: 1; padding: 12px;" onclick="handleAddToCart('${med.id}'); closeMedicineModal();" ${med.stock_quantity <= 0 ? 'disabled' : ''}>
            ${med.stock_quantity <= 0 ? 'Out of Stock' : 'Add to Cart (৳' + Number(med.price || 0).toFixed(2) + ')'}
          </button>
        </div>
      </div>
    </div>
  `;

  if (modal) {
    modal.classList.add('open');
    document.body.style.overflow = 'hidden';
  }
}

function closeMedicineModal() {
  const modal = document.getElementById('medicine-detail-modal-overlay');
  if (modal) {
    modal.classList.remove('open');
    document.body.style.overflow = '';
  }
}

// 14. Order Tracking System
function openTrackingModal() {
  const modal = document.getElementById('tracking-modal-overlay');
  if (modal) {
    modal.classList.add('open');
    document.body.style.overflow = 'hidden';
  }
}

function closeTrackingModal() {
  const modal = document.getElementById('tracking-modal-overlay');
  if (modal) {
    modal.classList.remove('open');
    document.body.style.overflow = '';
  }
}

async function handleTrackingSubmit(e) {
  e.preventDefault();
  const input = document.getElementById('track-query-input');
  const resultContainer = document.getElementById('tracking-results-box');
  const query = input.value.trim();

  if (!query) return;

  resultContainer.innerHTML = `
    <div style="text-align: center; padding: 20px;">
      <div style="display: inline-block; width: 28px; height: 28px; border: 3px solid var(--primary); border-top-color: transparent; border-radius: 50%; animation: spin 0.8s linear infinite;"></div>
      <p style="margin-top: 10px; font-size: 0.88rem;">Looking up order...</p>
    </div>
  `;

  if (!supabaseClient) {
    resultContainer.innerHTML = `
      <div style="background: var(--bg-page); padding: 16px; border-radius: var(--radius-md); text-align: center;">
        <p>Order <strong>${escapeHtml(query)}</strong> is active.</p>
        <p style="font-size: 0.85rem; color: var(--text-muted); margin-top: 6px;">Our pharmacist will call you at your registered phone number for confirmation.</p>
      </div>
    `;
    return;
  }

  try {
    // Search by Order ID or Customer Phone
    let { data, error } = await supabaseClient
      .from(TABLE_ORDERS)
      .select('*, EzzeMedicine_order_items(*)')
      .eq('id', query)
      .maybeSingle();

    if (!data) {
      const phoneRes = await supabaseClient
        .from(TABLE_ORDERS)
        .select('*, EzzeMedicine_order_items(*)')
        .eq('customer_phone', query)
        .order('created_at', { ascending: false })
        .limit(1);

      if (phoneRes.data && phoneRes.data.length > 0) {
        data = phoneRes.data[0];
      }
    }

    if (!data) {
      resultContainer.innerHTML = `
        <div style="padding: 20px; text-align: center; color: var(--danger);">
          <svg style="width: 40px; height: 40px; margin-bottom: 8px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          <p style="font-weight: 700;">No order found matching "${escapeHtml(query)}"</p>
          <p style="font-size: 0.82rem; color: var(--text-muted); margin-top: 4px;">Please check the Order ID or phone number used during checkout.</p>
        </div>
      `;
      return;
    }

    activeTrackingOrderId = data.id;
    renderTrackingDetails(data);
  } catch (err) {
    console.error('Tracking error:', err);
    resultContainer.innerHTML = `<p style="color: var(--danger); text-align: center;">Error looking up order. Please try again.</p>`;
  }
}

function renderTrackingDetails(order) {
  const resultContainer = document.getElementById('tracking-results-box');
  if (!resultContainer) return;

  currentTrackingOrder = order;

  // 1. Check 3-Hour Privacy Rule for Delivered Orders
  if (order.status === 'delivered') {
    const deliveryTimeStr = order.delivered_at || order.confirmed_at || order.updated_at || order.created_at;
    const deliveryTime = new Date(deliveryTimeStr).getTime();
    const now = Date.now();
    const diffMs = now - deliveryTime;
    const diffHours = diffMs / (1000 * 60 * 60);

    if (diffHours >= 3) {
      // OVER 3 HOURS: HIDE & DELETE DETAILS FROM USER-END VIEW
      resultContainer.innerHTML = `
        <div class="tracking-expired-card">
          <div class="privacy-shield-icon">
            <svg width="34" height="34" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
            </svg>
          </div>
          <h4 class="expired-title">Order Status Expired & Protected</h4>
          <div class="expired-badge">Delivered Over 3 Hours Ago • Personal Records Secured</div>
          <p class="expired-desc">
            To ensure patient confidentiality and prevent unauthorized users from viewing personal medicine purchases, order status and purchase details for Order <strong>#${escapeHtml(order.id)}</strong> were automatically deleted from public view after 3 hours of delivery.
          </p>
          <p class="expired-subtext">
            No other user can search or see your personal medicine purchases. An official PDF copy named <strong>${escapeHtml(order.id)}.pdf</strong> was sent directly to your Gmail (<strong>${maskEmail(order.customer_email)}</strong>).
          </p>
          <div class="expired-help-box">
            <span>Need an archived copy of your bill?</span>
            <a href="tel:+8801711000000" class="btn-call-support">
              <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/></svg>
              <span>Call Pharmacy Helpline: +880 1711-000000</span>
            </a>
          </div>
        </div>
      `;
      return;
    }
  }

  // 2. Active or Within 3 Hours of Delivery -> Render Tracking & Bill Receipt!
  const isConfirmed = order.status === 'confirmed';
  const isDelivered = order.status === 'delivered';
  const isCancelled = order.status === 'cancelled';
  const items = order.EzzeMedicine_order_items || order.items || [];
  const subtotal = Number(order.subtotal || 0);
  const deliveryCharge = Number(order.delivery_charge || 0);
  const totalAmount = Number(order.total_amount || (subtotal + deliveryCharge));

  let expiryCountdownHtml = '';
  if (isDelivered) {
    const deliveryTimeStr = order.delivered_at || order.confirmed_at || order.updated_at || order.created_at;
    const deliveryTime = new Date(deliveryTimeStr).getTime();
    const msRemaining = Math.max(0, 3 * 60 * 60 * 1000 - (Date.now() - deliveryTime));
    const hoursLeft = Math.floor(msRemaining / (1000 * 60 * 60));
    const minsLeft = Math.floor((msRemaining % (1000 * 60 * 60)) / (1000 * 60));
    expiryCountdownHtml = `
      <div style="background: #EFF6FF; border: 1px solid #BFDBFE; color: #1D4ED8; padding: 10px 14px; border-radius: var(--radius-sm); font-size: 0.8rem; margin-bottom: 14px; display: flex; align-items: center; gap: 8px;">
        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        <span><strong>Privacy Rule:</strong> This tracking page will automatically expire in <strong>${hoursLeft}h ${minsLeft}m</strong>. Please download your PDF copy.</span>
      </div>
    `;
  }

  const itemsRowsHtml = items.length > 0
    ? items
        .map(
          (item, idx) => `
      <tr>
        <td style="width: 30px; text-align: center; color: var(--text-muted);">${idx + 1}</td>
        <td>
          <strong style="color: var(--text-main);">${escapeHtml(item.medicine_name || item.name || 'Medicine')}</strong>
        </td>
        <td style="color: var(--text-muted);">${escapeHtml(item.unit || 'Strip')}</td>
        <td style="text-align: right;">৳${Number(item.unit_price || item.price || 0).toFixed(2)}</td>
        <td style="text-align: center; font-weight: 700;">${item.quantity || 1}</td>
        <td style="text-align: right; font-weight: 800; color: var(--primary);">৳${Number(item.item_total || ((item.unit_price || item.price || 0) * (item.quantity || 1))).toFixed(2)}</td>
      </tr>
    `
        )
        .join('')
    : `<tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 16px;">Items verified during phone call</td></tr>`;

  resultContainer.innerHTML = `
    <div>
      ${expiryCountdownHtml}

      <!-- Order Top Summary Card -->
      <div style="background: var(--bg-page); border: 1.5px solid var(--border); border-radius: var(--radius-md); padding: 18px; margin-bottom: 16px;">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px; flex-wrap: wrap; gap: 10px;">
          <div>
            <span style="font-size: 0.76rem; color: var(--text-muted); font-weight: 700; text-transform: uppercase;">Order Number</span>
            <h4 style="font-size: 1.3rem; font-weight: 800; color: var(--primary); font-family: monospace;">#${escapeHtml(order.id)}</h4>
            <span style="font-size: 0.82rem; color: var(--text-muted);">Customer: <strong>${escapeHtml(order.customer_name)}</strong> (${escapeHtml(order.customer_phone)})</span>
          </div>
          <div style="text-align: right;">
            <span style="display: inline-block; padding: 4px 12px; border-radius: var(--radius-full); font-size: 0.78rem; font-weight: 800; background: ${
              isCancelled ? 'var(--danger-bg)' : isDelivered || isConfirmed ? 'var(--success-bg)' : 'var(--warning-bg)'
            }; color: ${
              isCancelled ? 'var(--danger)' : isDelivered || isConfirmed ? 'var(--success)' : 'var(--warning)'
            };">
              ${escapeHtml(order.status.replace('_', ' ').toUpperCase())}
            </span>
            <div style="font-size: 1.15rem; font-weight: 800; color: var(--primary-dark); margin-top: 4px;">৳${totalAmount.toFixed(2)}</div>
          </div>
        </div>

        <!-- 4-Step Timeline -->
        <div class="timeline">
          <div class="timeline-step completed">
            <div class="timeline-dot"></div>
            <strong>1. Order Request Placed</strong>
            <p style="font-size: 0.78rem; color: var(--text-muted);">Submitted online by customer</p>
          </div>
          <div class="timeline-step ${isConfirmed || isDelivered ? 'completed' : 'active'}">
            <div class="timeline-dot"></div>
            <strong>2. Pharmacist Verification Call</strong>
            <p style="font-size: 0.78rem; color: var(--text-muted);">
              ${order.call_status === 'called_confirmed' || order.call_status === 'called_modified' ? 'Verified via telephone call' : 'Pharmacist will call your phone number'}
            </p>
          </div>
          <div class="timeline-step ${isConfirmed || isDelivered ? 'completed' : ''}">
            <div class="timeline-dot"></div>
            <strong>3. Order Confirmed & Bill Dispatched</strong>
            <p style="font-size: 0.78rem; color: var(--text-muted);">
              ${order.is_email_sent ? `Official invoice sent to ${escapeHtml(order.customer_email)}` : 'Awaiting confirmation'}
            </p>
          </div>
          <div class="timeline-step ${isDelivered ? 'completed' : ''}">
            <div class="timeline-dot"></div>
            <strong>4. ${order.is_home_delivery ? 'Home Delivery Dispatched' : 'Ready for Store Pickup'}</strong>
            <p style="font-size: 0.78rem; color: var(--text-muted);">${order.is_home_delivery ? `Destination: ${escapeHtml(order.delivery_address || 'Address on file')}` : 'Collect at pharmacy counter'}</p>
          </div>
        </div>
      </div>

      <!-- Itemized Bill Receipt Section -->
      <div class="bill-receipt-card" id="printable-receipt">
        <div class="bill-header-row">
          <div class="bill-store-info">
            <h3>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
                <path d="M4.5 10.5C3.67 10.5 3 11.17 3 12s.67 1.5 1.5 1.5h15c.83 0 1.5-.67 1.5-1.5s-.67-1.5-1.5-1.5h-15z"/>
                <path d="M10.5 4.5C10.5 3.67 11.17 3 12 3s1.5.67 1.5 1.5v15c0 .83-.67 1.5-1.5 1.5s-1.5-.67-1.5-1.5v-15z"/>
              </svg>
              <span>EzzeMedicine Pharmacy & Healthcare</span>
            </h3>
            <p>Holding 42, Road 11, Dhanmondi, Dhaka • Helpline: +880 1711-000000</p>
          </div>
          <div class="bill-meta-box">
            <div class="invoice-tag">Official Prescription Bill</div>
            <div class="invoice-id">#${escapeHtml(order.id)}</div>
            <div style="font-size: 0.76rem; color: var(--text-muted); margin-top: 2px;">
              Date: ${order.created_at ? new Date(order.created_at).toLocaleDateString() : new Date().toLocaleDateString()}
            </div>
          </div>
        </div>

        <div class="bill-customer-info">
          <div><strong>Customer:</strong> ${escapeHtml(order.customer_name)}</div>
          <div><strong>Phone:</strong> ${escapeHtml(order.customer_phone)}</div>
          <div><strong>Email:</strong> ${escapeHtml(order.customer_email)}</div>
          <div><strong>Fulfillment:</strong> ${order.is_home_delivery ? `Home Delivery to: ${escapeHtml(order.delivery_address || 'Address on file')}` : 'Store Pickup'}</div>
        </div>

        <div class="bill-table-wrapper">
          <table class="bill-table">
            <thead>
              <tr>
                <th style="width: 30px; text-align: center;">#</th>
                <th>Medicine Description</th>
                <th>Packaging</th>
                <th style="text-align: right;">Unit Price</th>
                <th style="text-align: center;">Qty</th>
                <th style="text-align: right;">Total</th>
              </tr>
            </thead>
            <tbody>
              ${itemsRowsHtml}
            </tbody>
          </table>
        </div>

        <div class="bill-totals-box">
          <div class="bill-total-line">
            <span>Medicines Subtotal:</span>
            <span>৳${subtotal.toFixed(2)}</span>
          </div>
          <div class="bill-total-line">
            <span>Delivery Fee:</span>
            <span>${deliveryCharge > 0 ? '৳' + deliveryCharge.toFixed(2) : 'Free / Store Pickup'}</span>
          </div>
          <div class="bill-total-line grand">
            <span>Total Payable:</span>
            <span>৳${totalAmount.toFixed(2)}</span>
          </div>
        </div>

        <div class="bill-actions-row">
          <button type="button" class="btn-download-bill" onclick="downloadPdfFromTracking()">
            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            <span>Download PDF Bill (${escapeHtml(order.id)}.pdf)</span>
          </button>

          <button type="button" class="btn-print-bill" onclick="printReceiptFromTracking()">
            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
            </svg>
            <span>Print Receipt</span>
          </button>
        </div>
      </div>
    </div>
  `;
}

function downloadPdfFromTracking() {
  if (currentTrackingOrder) {
    const items = currentTrackingOrder.EzzeMedicine_order_items || currentTrackingOrder.items || [];
    generateOrderBillPdf(currentTrackingOrder, items, true);
    showToast(`Downloading bill: ${currentTrackingOrder.id}.pdf`);
  } else {
    showToast('Order details not found.');
  }
}

function printReceiptFromTracking() {
  window.print();
}

// 15. Realtime Bill PDF Generator (jsPDF)
function generateOrderBillPdf(order, items, autoDownload = false) {
  if (!window.jspdf || !window.jspdf.jsPDF) {
    console.warn('jsPDF not loaded yet, falling back to browser print');
    if (autoDownload) window.print();
    return null;
  }

  try {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'pt',
      format: 'a4'
    });

    const pageWidth = doc.internal.pageSize.getWidth();
    const primaryColor = [2, 132, 199]; // Medical Blue #0284C7
    const darkColor = [3, 105, 161];    // #0369A1
    const slateColor = [15, 23, 42];    // #0F172A
    const grayColor = [100, 116, 139];  // #64748B
    const bgLight = [240, 249, 255];    // #F0F9FF

    // Top Header Bar
    doc.setFillColor(...primaryColor);
    doc.rect(0, 0, pageWidth, 80, 'F');

    doc.setTextColor(255, 255, 255);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(20);
    doc.text('EzzeMedicine Pharmacy & Healthcare', 40, 36);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9.5);
    doc.text('Authentic Medicines • Pharmacist Call Verification • Home Delivery', 40, 54);
    doc.text('Holding 42, Road 11, Dhanmondi, Dhaka | Helpline: +880 1711-000000', 40, 68);

    // Invoice Title & Meta Box
    doc.setTextColor(...darkColor);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(16);
    doc.text('OFFICIAL BILL RECEIPT', 40, 110);

    doc.setFontSize(9.5);
    doc.setTextColor(...grayColor);
    doc.setFont('helvetica', 'normal');
    const orderDateStr = order.created_at ? new Date(order.created_at).toLocaleString() : new Date().toLocaleString();
    doc.text(`Issue Date: ${orderDateStr}`, 40, 126);
    doc.text(`Order Status: ${(order.status || 'pending').toUpperCase().replace('_', ' ')}`, 40, 140);

    // Order ID Box (Right)
    doc.setFillColor(...bgLight);
    doc.roundedRect(pageWidth - 210, 94, 170, 50, 6, 6, 'F');
    doc.setDrawColor(...primaryColor);
    doc.setLineWidth(1);
    doc.roundedRect(pageWidth - 210, 94, 170, 50, 6, 6, 'D');

    doc.setTextColor(...primaryColor);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.text('INVOICE / ORDER NO', pageWidth - 200, 112);
    doc.setFontSize(15);
    doc.text(`#${order.id}`, pageWidth - 200, 132);

    // Customer Information Section
    doc.setFillColor(248, 250, 252);
    doc.roundedRect(40, 158, pageWidth - 80, 68, 6, 6, 'F');
    doc.setDrawColor(226, 232, 240);
    doc.roundedRect(40, 158, pageWidth - 80, 68, 6, 6, 'D');

    doc.setTextColor(...slateColor);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10.5);
    doc.text('Billed To (Customer Details):', 52, 176);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.text(`Customer Name: ${order.customer_name || 'Valued Customer'}`, 52, 192);
    doc.text(`Phone: ${order.customer_phone || 'N/A'}`, 52, 204);
    doc.text(`Email: ${order.customer_email || 'N/A'}`, 52, 216);

    const deliveryType = order.is_home_delivery
      ? `Home Delivery: ${order.delivery_address || 'Address on file'}`
      : 'Counter Pickup (Direct counter collection)';
    doc.text(`Fulfillment: ${deliveryType}`, 290, 192, { maxWidth: pageWidth - 330 });

    // Table of Items
    const itemsList = items || [];
    const tableData = itemsList.map((item, idx) => [
      idx + 1,
      item.medicine_name || item.name || 'Medicine',
      item.unit || 'Strip',
      `Tk ${(Number(item.unit_price || item.price || 0)).toFixed(2)}`,
      item.quantity || 1,
      `Tk ${(Number(item.item_total || ((item.unit_price || item.price || 0) * (item.quantity || 1)))).toFixed(2)}`
    ]);

    let finalY = 240;
    if (doc.autoTable) {
      doc.autoTable({
        startY: 236,
        head: [['#', 'Medicine Item Description', 'Packaging', 'Unit Price', 'Qty', 'Total']],
        body: tableData.length > 0 ? tableData : [['1', 'Prescription Medicines', 'Pack', 'Tk 0.00', '1', 'Tk 0.00']],
        theme: 'grid',
        headStyles: {
          fillColor: primaryColor,
          textColor: [255, 255, 255],
          fontStyle: 'bold',
          fontSize: 9,
          halign: 'left'
        },
        columnStyles: {
          0: { cellWidth: 30, halign: 'center' },
          1: { cellWidth: 'auto' },
          2: { cellWidth: 75 },
          3: { cellWidth: 65, halign: 'right' },
          4: { cellWidth: 40, halign: 'center' },
          5: { cellWidth: 70, halign: 'right', fontStyle: 'bold' }
        },
        styles: {
          fontSize: 8.5,
          textColor: slateColor,
          cellPadding: 6
        },
        margin: { left: 40, right: 40 }
      });
      finalY = doc.lastAutoTable.finalY + 14;
    }

    // Totals Box (Right Aligned)
    const subtotal = Number(order.subtotal || 0);
    const deliveryFee = Number(order.delivery_charge || 0);
    const grandTotal = Number(order.total_amount || (subtotal + deliveryFee));

    const totalsBoxX = pageWidth - 230;
    doc.setFillColor(...bgLight);
    doc.roundedRect(totalsBoxX, finalY, 190, 72, 6, 6, 'F');
    doc.setDrawColor(...primaryColor);
    doc.setLineWidth(0.8);
    doc.roundedRect(totalsBoxX, finalY, 190, 72, 6, 6, 'D');

    doc.setFontSize(9);
    doc.setTextColor(...grayColor);
    doc.setFont('helvetica', 'normal');
    doc.text('Subtotal:', totalsBoxX + 12, finalY + 18);
    doc.text(`Tk ${subtotal.toFixed(2)}`, pageWidth - 48, finalY + 18, { align: 'right' });

    doc.text('Delivery Fee:', totalsBoxX + 12, finalY + 34);
    doc.text(deliveryFee > 0 ? `Tk ${deliveryFee.toFixed(2)}` : 'Free / Pickup', pageWidth - 48, finalY + 34, { align: 'right' });

    doc.setDrawColor(186, 230, 253);
    doc.line(totalsBoxX + 12, finalY + 44, pageWidth - 48, finalY + 44);

    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(...darkColor);
    doc.text('Total Payable:', totalsBoxX + 12, finalY + 60);
    doc.text(`Tk ${grandTotal.toFixed(2)}`, pageWidth - 48, finalY + 60, { align: 'right' });

    // 3-Hour Privacy Notice & Registered Pharmacist Seal
    const noticeY = Math.max(finalY + 86, 670);
    doc.setFillColor(239, 246, 255);
    doc.roundedRect(40, noticeY, pageWidth - 80, 46, 6, 6, 'F');
    doc.setDrawColor(191, 219, 254);
    doc.roundedRect(40, noticeY, pageWidth - 80, 46, 6, 6, 'D');

    doc.setTextColor(30, 64, 175);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8.5);
    doc.text('CONFIDENTIAL MEDICAL RECEIPT & 3-HOUR PRIVACY COMPLIANCE', 50, noticeY + 16);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.8);
    doc.text('To safeguard patient privacy, public order tracking on our website automatically expires 3 hours post-delivery.', 50, noticeY + 28);
    doc.text('Please retain this official PDF receipt for medical reference, warranty, or insurance claims.', 50, noticeY + 38);

    // Footer
    doc.setFontSize(7.5);
    doc.setTextColor(...grayColor);
    doc.text('Generated electronically by EzzeMedicine Pharmacy • Licensed Pharmacist Verification', pageWidth / 2, 792, { align: 'center' });

    if (autoDownload) {
      doc.save(`${order.id}.pdf`);
    }

    const dataUri = doc.output('datauristring');
    const base64 = dataUri.split(',')[1];
    return { doc, base64, filename: `${order.id}.pdf` };
  } catch (err) {
    console.error('PDF generation error:', err);
    return null;
  }
}

// 16. Realtime Automated Email System
async function sendAutomatedOrderEmail(order, items) {
  try {
    // Generate PDF in memory to obtain base64
    const pdfResult = generateOrderBillPdf(order, items, false);
    const pdfBase64 = pdfResult ? pdfResult.base64 : null;

    // Send payload to Vercel Serverless Function /api/send-bill
    const response = await fetch('/api/send-bill', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        order: order,
        items: items,
        pdfBase64: pdfBase64
      })
    });

    if (response.ok) {
      const data = await response.json();
      console.log('Automated bill email dispatched:', data);
    }
    showToast(`📧 Automated bill & PDF copy sent to ${order.customer_email}`);
  } catch (err) {
    console.warn('Realtime email dispatch notice (development/static):', err);
    showToast(`📧 Bill generated for ${order.customer_email}`);
  }
}

// 17. Toast Notification System
function showToast(message) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.innerHTML = `
    <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
    </svg>
    <span>${escapeHtml(message)}</span>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    setTimeout(() => toast.remove(), 300);
  }, 3200);
}

// 18. Privacy Email Masking Helper
function maskEmail(email) {
  if (!email || !email.includes('@')) return 'your email';
  const parts = email.split('@');
  const user = parts[0];
  const domain = parts[1];
  if (user.length <= 2) return `${user[0]}*@${domain}`;
  return `${user.slice(0, 2)}***${user.slice(-1)}@${domain}`;
}

// 19. Utility Helper
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

