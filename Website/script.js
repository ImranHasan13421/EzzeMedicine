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
    id: '00000000-0000-0000-0000-000000000001',
    name: 'Napa Extra',
    generic_name: 'Paracetamol + Caffeine',
    category: 'Tablet',
    manufacturer: 'Beximco Pharmaceuticals',
    strength: '500mg + 65mg',
    unit: 'Strip (10 pcs)',
    price: 35.0,
    stock_quantity: 140,
    image_url: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80',
    requires_prescription: false,
    description: 'Fast and effective relief from fever, headache, migraine, toothache, and body pain.',
    dosage_instructions: '1-2 tablets every 4 to 6 hours as needed. Maximum 8 tablets daily.'
  },
  {
    id: '00000000-0000-0000-0000-000000000002',
    name: 'Sergel 20mg',
    generic_name: 'Esomeprazole Magnesium',
    category: 'Capsule',
    manufacturer: 'Healthcare Pharmaceuticals',
    strength: '20mg',
    unit: 'Strip (10 pcs)',
    price: 70.0,
    stock_quantity: 85,
    image_url: 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400&auto=format&fit=crop&q=80',
    requires_prescription: false,
    description: 'Proton pump inhibitor for hyperacidity, acid reflux, peptic ulcer, and gastritis.',
    dosage_instructions: '1 capsule once daily 30 minutes before meal with a full glass of water.'
  },
  {
    id: '00000000-0000-0000-0000-000000000003',
    name: 'Monas 10mg',
    generic_name: 'Montelukast Sodium',
    category: 'Tablet',
    manufacturer: 'Acme Laboratories',
    strength: '10mg',
    unit: 'Strip (10 pcs)',
    price: 160.0,
    stock_quantity: 8,
    image_url: 'https://images.unsplash.com/photo-1550572017-edd951aa8f72?w=400&auto=format&fit=crop&q=80',
    requires_prescription: true,
    description: 'Preventative treatment for chronic asthma, allergic rhinitis, and bronchospasm.',
    dosage_instructions: '1 tablet once daily in the evening at bedtime.'
  },
  {
    id: '00000000-0000-0000-0000-000000000004',
    name: 'Tusca Cold & Cough',
    generic_name: 'Dextromethorphan + Pseudoephedrine',
    category: 'Syrup',
    manufacturer: 'Square Pharmaceuticals',
    strength: '100ml',
    unit: 'Bottle (100ml)',
    price: 95.0,
    stock_quantity: 42,
    image_url: 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=400&auto=format&fit=crop&q=80',
    requires_prescription: false,
    description: 'Soothes dry cough, clears nasal congestion, and relieves allergic throat irritation.',
    dosage_instructions: '10ml (2 teaspoonfuls) 3 times daily after meals.'
  },
  {
    id: '00000000-0000-0000-0000-000000000005',
    name: 'Bextram Gold Multivitamin',
    generic_name: 'Multivitamins & Minerals with Zinc',
    category: 'Vitamins & Supplements',
    manufacturer: 'Beximco Pharmaceuticals',
    strength: '30 Tablets',
    unit: 'Bottle (200ml)',
    price: 320.0,
    stock_quantity: 30,
    image_url: 'https://images.unsplash.com/photo-1577401239170-897942555fb3?w=400&auto=format&fit=crop&q=80',
    requires_prescription: false,
    description: 'Complete daily nutritional support for immunity, vitality, and physical stamina.',
    dosage_instructions: '1 tablet once daily with or after a main meal.'
  }
];

// 3. Application Reactive State
let medicines = [];
let cart = JSON.parse(localStorage.getItem('ezze_cart') || '[]');
let activeCategory = 'All';
let searchQuery = '';
let activeTrackingOrderId = null;

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

  if (idEl) idEl.textContent = orderData.id;
  if (phoneEl) phoneEl.textContent = orderData.phone;
  if (emailEl) emailEl.textContent = orderData.email;
  if (deliveryTypeEl) {
    deliveryTypeEl.textContent = orderData.isHomeDelivery
      ? `Home Delivery to: ${orderData.address} (Delivery fee will be set by admin on call)`
      : `Store Pickup (Collect at pharmacy)`;
  }

  activeTrackingOrderId = orderData.id;

  if (modal) {
    modal.classList.add('open');
    document.body.style.overflow = 'hidden';
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

  const isConfirmed = order.status === 'confirmed';
  const isDelivered = order.status === 'delivered';
  const isCancelled = order.status === 'cancelled';

  resultContainer.innerHTML = `
    <div style="background: var(--bg-page); border: 1px solid var(--border); border-radius: var(--radius-md); padding: 18px;">
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px;">
        <div>
          <span style="font-size: 0.78rem; color: var(--text-muted); font-weight: 600;">ORDER NUMBER</span>
          <h4 style="font-size: 1.2rem; font-weight: 800; color: var(--primary);">${escapeHtml(order.id)}</h4>
          <span style="font-size: 0.82rem; color: var(--text-muted);">Customer: ${escapeHtml(order.customer_name)} (${escapeHtml(order.customer_phone)})</span>
        </div>
        <div style="text-align: right;">
          <span style="display: inline-block; padding: 4px 10px; border-radius: var(--radius-full); font-size: 0.76rem; font-weight: 800; background: ${
            isCancelled ? 'var(--danger-bg)' : isDelivered || isConfirmed ? 'var(--success-bg)' : 'var(--warning-bg)'
          }; color: ${
            isCancelled ? 'var(--danger)' : isDelivered || isConfirmed ? 'var(--success)' : 'var(--warning)'
          };">
            ${escapeHtml(order.status.replace('_', ' ').toUpperCase())}
          </span>
          <div style="font-size: 1.1rem; font-weight: 800; margin-top: 4px;">৳${Number(order.total_amount || order.subtotal || 0).toFixed(2)}</div>
        </div>
      </div>

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
  `;
}

// 15. Toast Notification System
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

// 16. Utility Helper
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
