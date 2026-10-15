# AppointmentPro — Booking & Business Manager

AppointmentPro is an end-to-end appointment scheduling, team management, and business intelligence platform designed for service-based businesses (Salons, Healthcare, Spas, Gyms, Clinics, and Consultancies).

## Project Structure

```text
Appointment_Pro/
├── appointment_pro/    # Flutter mobile & web application (Riverpod, GoRouter, Toastification)
├── Server/             # Node.js backend & MySQL database architecture
│   ├── README.md       # Full MySQL Schema, ERD, Table Specs & API Contract Documentation
│   ├── schema.sql      # Production-ready MySQL DDL script with seed data
│   └── package.json    # Backend server configuration
└── README.md           # Workspace overview
```

---

## Backend & Database Architecture

The backend database specification is comprehensively documented in [`Server/README.md`](file:///d:/Rishvi/Projects/Appointment_Pro/Server/README.md).

### Core Database Highlights
- **Engine & Character Set:** MySQL 8.0+ `InnoDB`, `utf8mb4` with `utf8mb4_unicode_ci`.
- **Multi-Tenancy:** Business-scoped models with support for multiple businesses per owner/user.
- **Client Public Booking Portal:** Unique URL slugs (`/book/:businessSlug`), real-time slot calculator, and `booking_reference` verification.
- **Relational Integrity:** Foreign keys enforce strict referential integrity (`CASCADE`, `RESTRICT`, `SET NULL`) with zero orphan records.
- **High-Performance Slot Availability Indexing:** Composite index on `(business_id, staff_id, status, start_at, end_at)` prevents double bookings.
- **Audit Logging:** Reschedule history tracking (`booking_reschedules`), financial ledger (`payments`), and notifications.

### Quick Database Setup

To import the database schema and sample seed records into your MySQL server:

```bash
mysql -u root -p < Server/schema.sql
```

For complete table column breakdowns, entity relationship diagrams, and REST API mapping, refer to:
👉 [**Server/README.md**](file:///d:/Rishvi/Projects/Appointment_Pro/Server/README.md)