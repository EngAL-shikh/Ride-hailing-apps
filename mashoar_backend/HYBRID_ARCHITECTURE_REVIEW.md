# Hybrid Real-Time Architecture Review

This document outlines the hybrid real-time architecture implemented for the MotoYemen application, detailing how Firebase Cloud Messaging (FCM) and Firebase Realtime Database (RTDB) are utilized for different trip states, with MySQL remaining the single source of truth.

## Hybrid Rule Summary:
- **Wake-Up (FCM)**: Used ONLY for initial notifications to "wake up" users (e.g., new ride request to drivers, new bid to rider). These are typically one-time alerts.
- **Live Flow (RTDB)**: Used for continuous, low-latency updates during active phases of a trip (e.g., bidding, price negotiation, trip acceptance, status changes like `in_progress`, `completed`). This ensures instant UI updates without constant polling.
- **Single Source of Truth (MySQL)**: All persistent data is stored in the MySQL database. Firebase RTDB acts as a temporary, real-time cache for active trip data.

---

## الحالات المراجعة

### 1. ✅ طلب رحلة جديدة (Request Trip)
**Backend:**
- ✅ FCM: إشعار للسائقين القريبين (`new_trip`)
- ✅ RTDB: `/trips/{trip_id}` (في `TripService->requestTrip()`)
- ✅ RTDB: `/trips/available/{trip_id}` (في `TripController->request()`)

**Frontend:**
- ✅ السائق يستمع إلى `/trips/available` (في `DriverController`)
- ✅ الراكب يستمع إلى `/trips/{trip_id}` و `/trips/{trip_id}/bids` (في `RideController`)

---

### 2. ✅ وضع مزايدة (Place Bid)
**Backend:**
- ✅ FCM: إشعار للراكب (`new_bid`) - اختياري
- ✅ RTDB: `/trips/{trip_id}/bids/{driver_id}` (في `TripService->placeBid()`)

**Frontend:**
- ✅ الراكب يستمع إلى `/trips/{trip_id}/bids` (في `RideController`)
- ✅ يتم تحديث `activeTrip` و `bids_count` تلقائياً

---

### 3. ✅ قبول المزايدة (Accept Bid)
**Backend:**
- ✅ FCM: إشعار للسائق (`your_bid_accepted`)
- ✅ FCM: إشعار للراكب (`bid_accepted`)
- ✅ RTDB: `/trips/{trip_id}` (status: `assigned`) (في `TripService->acceptBid()`)
- ✅ RTDB: حذف من `/trips/available/{trip_id}` (في `TripService->acceptBid()`)

**Frontend:**
- ✅ السائق يستمع إلى `/trips/{trip_id}` (في `DriverController`)
- ✅ الراكب يستمع إلى `/trips/{trip_id}` (في `RideController`)
- ✅ يتم تحديث الحالة تلقائياً عند كلا الطرفين

---

### 4. ✅ بدء الرحلة (Start Trip) - **تم إضافتها**
**Backend:**
- ✅ FCM: إشعار للراكب (`trip_started`) - اختياري
- ✅ RTDB: `/trips/{trip_id}` (status: `in_progress`) (في `TripService->startTrip()`)
- ✅ Endpoint: `POST /api/v1/trips/{trip}/start` (في `TripController->start()`)

**Frontend:**
- ✅ السائق يستمع إلى `/trips/{trip_id}` (في `DriverController`)
- ✅ الراكب يستمع إلى `/trips/{trip_id}` (في `RideController`)
- ✅ يتم تحديث الحالة تلقائياً عند كلا الطرفين

---

### 5. ✅ إكمال الرحلة (Complete Trip)
**Backend:**
- ✅ FCM: إشعار للراكب (`trip_completed`)
- ✅ RTDB: `/trips/{trip_id}` (status: `completed`) (في `TripService->completeTrip()`)

**Frontend:**
- ✅ السائق يستمع إلى `/trips/{trip_id}` (في `DriverController`)
- ✅ الراكب يستمع إلى `/trips/{trip_id}` (في `RideController`)
- ✅ يتم تحديث الحالة تلقائياً عند كلا الطرفين

---

## ملخص التحديثات

### Backend Changes:
1. ✅ `TripService->startTrip()`: إضافة method جديد لتغيير الحالة إلى `in_progress`
2. ✅ `TripController->start()`: إضافة endpoint جديد `POST /api/v1/trips/{trip}/start`
3. ✅ جميع الحالات تستخدم `syncTripToFirebase()` أو `syncBidToFirebase()` بعد كل تحديث

### Frontend Changes:
1. ✅ `RideController`: يستمع إلى `/trips/{trip_id}` و `/trips/{trip_id}/bids`
2. ✅ `DriverController`: يستمع إلى `/trips/available` و `/trips/{trip_id}`
3. ✅ جميع الـstreams تعمل بشكل صحيح وتحدث الـUI تلقائياً

---

## الحالات المدعومة الآن:
- ✅ `bidding`: الرحلة في حالة المزايدة
- ✅ `assigned`: تم قبول المزايدة وتعيين السائق
- ✅ `in_progress`: السائق بدأ الرحلة
- ✅ `completed`: اكتملت الرحلة
- ✅ `cancelled`: تم إلغاء الرحلة

---

## ملاحظات:
- جميع التحديثات تتم عبر Firebase RTDB للسرعة الفورية
- FCM يُستخدم فقط كإشعار "Wake-Up" لإيقاظ التطبيق
- MySQL يبقى المصدر الوحيد للحقيقة (Single Source of Truth)
- Firebase RTDB يُستخدم فقط للتحديثات الفورية في الوقت الفعلي

---

**تاريخ المراجعة:** 2026-02-04
**الحالة:** ✅ مكتمل - جميع الحالات مدعومة
