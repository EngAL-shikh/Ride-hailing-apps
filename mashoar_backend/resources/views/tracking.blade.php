<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>تتبع الرحلة</title>
    <style>
        html, body { height: 100%; margin: 0; }
        #map { height: 100%; width: 100%; }
        .banner {
            position: absolute;
            top: 12px;
            left: 12px;
            right: 12px;
            z-index: 10;
            background: rgba(255,255,255,0.95);
            padding: 10px 12px;
            border-radius: 10px;
            font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            box-shadow: 0 4px 24px rgba(0,0,0,0.12);
        }
        .meta { font-size: 12px; color: #555; margin-top: 6px; }
        .error { color: #b00020; }
    </style>
</head>
<body>
<div class="banner">
    <div><strong>تتبع مباشر</strong> — رحلة رقم: <strong>{{ $tripId }}</strong></div>
    <div class="meta" id="status">جاري التحميل...</div>
    @if(empty($googleMapsKey) || empty($firebase['apiKey']) || empty($firebase['projectId']) || empty($firebase['databaseURL']))
        <div class="meta error">
            مفاتيح التتبع غير مهيئة. تأكد من إعداد متغيرات البيئة:
            <code>GOOGLE_MAPS_JS_API_KEY</code> و <code>FIREBASE_API_KEY</code> و <code>FIREBASE_PROJECT_ID</code> و <code>FIREBASE_DATABASE_URL</code>.
        </div>
    @endif
</div>
<div id="map"></div>

@if(!empty($googleMapsKey))
    <script async defer src="https://maps.googleapis.com/maps/api/js?key={{ $googleMapsKey }}&callback=initMap"></script>
@endif

<script type="module">
    // Firebase Web SDK (Realtime Database)
    import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js";
    import { getDatabase, ref, onValue } from "https://www.gstatic.com/firebasejs/10.12.5/firebase-database.js";

    const tripId = @json($tripId);
    const statusEl = document.getElementById('status');

    const firebaseConfig = {
        apiKey: @json($firebase['apiKey']),
        authDomain: @json($firebase['authDomain']),
        projectId: @json($firebase['projectId']),
        databaseURL: @json($firebase['databaseURL']),
    };

    let map = null;
    let marker = null;

    window.initMap = function initMap() {
        // Default center (Yemen/Sana'a-ish)
        map = new google.maps.Map(document.getElementById("map"), {
            center: { lat: 15.3694, lng: 44.1910 },
            zoom: 14,
        });

        marker = new google.maps.Marker({
            position: { lat: 15.3694, lng: 44.1910 },
            map,
            title: "Driver",
        });

        try {
            if (!firebaseConfig.apiKey || !firebaseConfig.projectId || !firebaseConfig.databaseURL) {
                statusEl.textContent = "Firebase config missing.";
                return;
            }

            const app = initializeApp(firebaseConfig);
            const db = getDatabase(app);
            const driverRef = ref(db, `trips/${tripId}/driver`);

            statusEl.textContent = "بانتظار موقع السائق...";

            onValue(driverRef, (snapshot) => {
                const v = snapshot.val();
                if (!v || typeof v.lat !== 'number' || typeof v.lng !== 'number') {
                    statusEl.textContent = "لا يوجد موقع بعد.";
                    return;
                }
                const pos = { lat: v.lat, lng: v.lng };
                marker.setPosition(pos);
                map.panTo(pos);
                statusEl.textContent = `آخر تحديث: ${new Date(v.ts || Date.now()).toLocaleString()}`;
            }, (err) => {
                statusEl.textContent = "خطأ في قراءة بيانات التتبع.";
                console.error(err);
            });
        } catch (e) {
            statusEl.textContent = "خطأ في تهيئة التتبع.";
            console.error(e);
        }
    }
</script>
</body>
</html>

<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تتبع الرحلة - مشوار</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Cairo', Arial, sans-serif;
            direction: rtl;
        }
        #map {
            height: 70vh;
            width: 100%;
        }
        .trip-info {
            padding: 16px;
            background: #f5f5f5;
            border-top: 2px solid #1976d2;
        }
        .trip-info h2 {
            color: #1976d2;
            margin-bottom: 12px;
        }
        .trip-info p {
            margin: 8px 0;
            color: #333;
        }
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 14px;
            font-weight: bold;
        }
        .status-requested { background: #ff9800; color: white; }
        .status-accepted { background: #2196f3; color: white; }
        .status-in_progress { background: #4caf50; color: white; }
        .status-completed { background: #8bc34a; color: white; }
        .status-cancelled { background: #f44336; color: white; }
    </style>
</head>
<body>
    <div id="map"></div>
    <div class="trip-info">
        <h2>معلومات الرحلة</h2>
        <p><strong>رقم الرحلة:</strong> #{{ $trip->id }}</p>
        <p><strong>الحالة:</strong> 
            <span class="status-badge status-{{ $trip->status }}">
                @if($trip->status == 'requested') مطلوبة
                @elseif($trip->status == 'accepted') مقبولة
                @elseif($trip->status == 'in_progress') قيد التنفيذ
                @elseif($trip->status == 'completed') مكتملة
                @elseif($trip->status == 'cancelled') ملغاة
                @endif
            </span>
        </p>
        @if($trip->driver)
        <p><strong>السائق:</strong> {{ $trip->driver->name }}</p>
        @endif
        <p><strong>السعر:</strong> {{ $trip->accepted_price ?? $trip->offered_price }} YER</p>
    </div>

    <!-- Google Maps API -->
    <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY&callback=initMap" async defer></script>
    
    <!-- Firebase SDK -->
    <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-database.js"></script>
    
    <script>
        // Firebase configuration (TODO: Replace with actual config)
        const firebaseConfig = {
            apiKey: "YOUR_FIREBASE_API_KEY",
            authDomain: "YOUR_FIREBASE_AUTH_DOMAIN",
            databaseURL: "YOUR_FIREBASE_DATABASE_URL",
            projectId: "YOUR_FIREBASE_PROJECT_ID",
            storageBucket: "YOUR_FIREBASE_STORAGE_BUCKET",
            messagingSenderId: "YOUR_FIREBASE_MESSAGING_SENDER_ID",
            appId: "YOUR_FIREBASE_APP_ID"
        };

        // Initialize Firebase
        firebase.initializeApp(firebaseConfig);
        const database = firebase.database();

        let map;
        let driverMarker;
        const tripId = '{{ $tripId }}';

        function initMap() {
            // Initialize map centered on pickup location (TODO: Get from trip data)
            map = new google.maps.Map(document.getElementById('map'), {
                center: { lat: 15.3694, lng: 44.1910 }, // Sana'a default
                zoom: 13
            });

            // Listen for driver location updates
            const driverLocRef = database.ref(`trips/${tripId}/driver_loc`);
            
            driverLocRef.on('value', (snapshot) => {
                const location = snapshot.val();
                if (location) {
                    const position = {
                        lat: location.latitude,
                        lng: location.longitude
                    };

                    if (driverMarker) {
                        // Update existing marker
                        driverMarker.setPosition(position);
                    } else {
                        // Create new marker
                        driverMarker = new google.maps.Marker({
                            position: position,
                            map: map,
                            title: 'موقع السائق',
                            icon: {
                                url: 'http://maps.google.com/mapfiles/ms/icons/blue-dot.png'
                            }
                        });
                    }

                    // Center map on driver location
                    map.setCenter(position);
                }
            });
        }
    </script>
</body>
</html>
