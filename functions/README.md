# CareMatch Cloud Functions

This directory contains Firebase Cloud Functions for automated workflows in the CareMatch platform.

## Functions Overview

### 1. autoEscalateCriticalIncidents
**Trigger:** Firestore onCreate - `incidents/{incidentId}`
**Purpose:** Automatically escalates critical incidents and notifies admins

**Features:**
- Creates admin alerts for critical incidents
- Sends notifications to all administrators
- Updates incident with auto-escalation flag
- Logs escalation in incident timeline

**Usage:**
When a user creates an incident with `severity: 'critical'`, this function automatically:
1. Creates an entry in `admin_alerts` collection
2. Sends push notifications to all admins
3. Marks incident as auto-escalated

---

### 2. monitorLowRatings
**Trigger:** Firestore onCreate - `reviews/{reviewId}`
**Purpose:** Creates automatic incident reports for low ratings (≤ 2.0 stars)

**Features:**
- Monitors all new reviews
- Auto-generates incident for ratings ≤ 2.0
- Severity based on rating (≤ 1.5 = high, > 1.5 = medium)
- Notifies caregiver and admins

**Workflow:**
1. Review created with rating ≤ 2.0
2. System generates incident number (INC-YYYY-NNNNNN)
3. Creates incident report with review details
4. Sends notification to caregiver
5. Alerts admins about quality concern

---

### 3. scheduledMetricsCalculation
**Trigger:** Pub/Sub Schedule - Every Sunday at 00:00 UTC
**Purpose:** Weekly automated calculation of quality metrics for all caregivers

**Features:**
- Calculates metrics for all active caregivers
- Analyzes 90-day rolling window
- Updates quality scores and performance tiers
- Generates platform-wide analytics
- Identifies caregivers needing attention

**Metrics Calculated:**
- Response time & acceptance rate
- Completion rate & cancellations
- Average rating & star distribution
- Incident counts (total & critical)
- Total hours worked
- Client retention rate
- Quality score (0-100)
- Performance tier classification

**Platform Metrics:**
- Total active caregivers
- Average quality score
- Performance tier distribution
- High performers vs. needing attention

---

### 4. onBookingCompleted
**Trigger:** Firestore onUpdate - `bookings/{bookingId}`
**Purpose:** Real-time metrics update when booking status changes to completed

**Features:**
- Detects booking completion
- Recalculates caregiver metrics immediately
- Keeps quality scores current
- Ensures timely performance tracking

---

## Deployment

### Prerequisites
```bash
npm install -g firebase-tools
firebase login
```

### Install Dependencies
```bash
cd functions
npm install
```

### Deploy All Functions
```bash
firebase deploy --only functions
```

### Deploy Specific Function
```bash
firebase deploy --only functions:autoEscalateCriticalIncidents
firebase deploy --only functions:monitorLowRatings
firebase deploy --only functions:scheduledMetricsCalculation
firebase deploy --only functions:onBookingCompleted
```

---

## Testing Locally

### Start Emulators
```bash
firebase emulators:start
```

### Test Individual Functions
```bash
cd functions
npm run shell

# In the shell:
autoEscalateCriticalIncidents({incidentId: 'test123'})
monitorLowRatings({reviewId: 'review456'})
scheduledMetricsCalculation()
```

---

## Environment Variables

If you need to add environment variables:

```bash
firebase functions:config:set service.key="YOUR_VALUE"
firebase deploy --only functions
```

Access in code:
```javascript
const serviceKey = functions.config().service.key;
```

---

## Monitoring & Logs

### View Logs
```bash
firebase functions:log
```

### View Specific Function Logs
```bash
firebase functions:log --only autoEscalateCriticalIncidents
```

### Cloud Console
Visit: https://console.firebase.google.com/project/YOUR_PROJECT_ID/functions

---

## Cost Optimization

**Free Tier Limits:**
- 2M invocations/month
- 400,000 GB-seconds
- 200,000 CPU-seconds

**Optimization Tips:**
1. `scheduledMetricsCalculation` runs weekly (4 times/month)
2. `onBookingCompleted` only triggers on status changes
3. `autoEscalateCriticalIncidents` only for critical severity
4. `monitorLowRatings` only for ratings ≤ 2.0

---

## Error Handling

All functions include try-catch blocks and log errors to Cloud Functions logs.

**Common Issues:**
- **Permission Denied:** Ensure Firestore security rules allow Cloud Functions admin access
- **Timeout:** Increase function timeout in firebase.json if needed
- **Memory Issues:** Adjust memory allocation for metrics calculation

---

## Function Triggers Summary

| Function | Trigger Type | Frequency | Purpose |
|----------|-------------|-----------|---------|
| autoEscalateCriticalIncidents | onCreate | Event-driven | Critical incident alerts |
| monitorLowRatings | onCreate | Event-driven | Quality monitoring |
| scheduledMetricsCalculation | Scheduled | Weekly | Metrics calculation |
| onBookingCompleted | onUpdate | Event-driven | Real-time metrics update |

---

## Next Steps

1. Deploy functions: `firebase deploy --only functions`
2. Monitor logs for first week
3. Adjust schedule if needed
4. Add custom metrics as platform grows
5. Set up Cloud Function alerts in Firebase Console
