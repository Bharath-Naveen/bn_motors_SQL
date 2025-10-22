# BN Motors SQL — Blueprint v1

## Project goal

Design a realistic, portfolio‑ready SQL database for a fictional multi‑store car dealership network ("BN Motors"). It should support sales, trade‑ins, service/parts, financing, warranties, and CRM. We’ll use MySQL 8 (InnoDB) and write production‑style queries that answer complex, real‑world questions.

---

## Core business rules (v1)

1. BN Motors operates **multiple stores** under one brand; inventory belongs to a store.
2. Vehicles are defined by **Make → Model → Trim/Year → VIN**.
3. A **vehicle** can be **new** or **used**; used vehicles may have a prior owner and may arrive via **trade‑in** or **auction**.
4. A **customer** can place **leads/appointments**, take **test drives**, and make **purchases** (cash) or **financed** purchases.
5. Each **sale** may include a **trade‑in** (optional), a **financing contract** (optional), and zero‑or‑more **add‑ons** (e.g., service plan, warranties).
6. The **service department** raises **service orders** that contain **line items** performed by **technicians** and may consume **parts** from **suppliers**. Vehicles can be serviced regardless of where they were purchased.
7. **Warranties** can be OEM or third‑party and cover certain repairs for a time/mileage period.
8. All money amounts are stored as DECIMAL(12,2) in USD for simplicity.

---

## Entities & key attributes (v1)

* **Store**(store_id PK, name, phone, email, address, city, state, zip)
* **Employee**(employee_id PK, store_id FK→Store, role, first_name, last_name, email, phone, hired_at, active)
* **Customer**(customer_id PK, first_name, last_name, email, phone, dl_number, dl_state, address, city, state, zip, created_at)
* **Make**(make_id PK, name)
* **Model**(model_id PK, make_id FK→Make, name)
* **Trim**(trim_id PK, model_id FK→Model, year, trim_name, body_style, drivetrain, transmission, engine)
* **Vehicle**(vin PK, trim_id FK→Trim, color_ext, color_int, mileage, condition ENUM('new','used'), acquired_via ENUM('factory','trade_in','auction','other'), acquisition_date, msrp DECIMAL, cost DECIMAL, listed_price DECIMAL, status ENUM('in_stock','reserved','sold','service_hold','transfer'))
* **Inventory**(inventory_id PK, store_id FK→Store, vin FK→Vehicle, arrived_at, floorplan_lien BOOLEAN)
* **Lead**(lead_id PK, customer_id FK→Customer, store_id FK→Store, source ENUM('web','walkin','phone','referral','event'), created_at, status ENUM('new','working','won','lost'), notes)
* **Appointment**(appt_id PK, lead_id FK→Lead NULL, customer_id FK→Customer, store_id FK→Store, appt_type ENUM('sales','service','finance','other'), scheduled_at, with_employee_id FK→Employee)
* **TestDrive**(testdrive_id PK, vin FK→Vehicle, customer_id FK→Customer, employee_id FK→Employee, store_id FK→Store, start_ts, end_ts, route_notes)
* **Sale**(sale_id PK, vin FK→Vehicle, store_id FK→Store, salesperson_id FK→Employee, customer_id FK→Customer, sale_date, sale_price DECIMAL, payment_type ENUM('cash','finance'), doc_fee DECIMAL, tax DECIMAL, total_out_the_door DECIMAL, cancelled BOOLEAN DEFAULT 0)
* **TradeIn**(tradein_id PK, sale_id FK→Sale, vin_in VARCHAR(17), make_in, model_in, year_in, mileage_in, appraised_value DECIMAL, offer_value DECIMAL)
* **FinanceContract**(contract_id PK, sale_id FK→Sale, lender_id FK→Lender, apr DECIMAL(5,3), term_months INT, amount_financed DECIMAL, monthly_payment DECIMAL, signed_at)
* **Lender**(lender_id PK, name, contact_name, phone, email)
* **Warranty**(warranty_id PK, provider, name, coverage_miles INT, coverage_months INT)
* **SaleWarranty**(sale_id FK→Sale, warranty_id FK→Warranty, price DECIMAL, PRIMARY KEY (sale_id, warranty_id))
* **ServiceOrder**(so_id PK, store_id FK→Store, vin FK→Vehicle, customer_id FK→Customer NULL, opened_at, closed_at NULL, odometer_in INT, odometer_out INT NULL, advisor_id FK→Employee, status ENUM('open','in_progress','closed','void'))
* **Technician**(tech_id PK, store_id FK→Store, first_name, last_name, ase_level, active)
* **ServiceLineItem**(line_id PK, so_id FK→ServiceOrder, tech_id FK→Technician NULL, labor_code, description, hours DECIMAL(5,2), labor_rate DECIMAL(6,2), warranty_id FK→Warranty NULL)
* **Part**(part_id PK, supplier_id FK→Supplier, sku, name, unit_cost DECIMAL, unit_price DECIMAL, taxable BOOLEAN)
* **Supplier**(supplier_id PK, name, phone, email)
* **ServicePartUsage**(line_id FK→ServiceLineItem, part_id FK→Part, qty DECIMAL(10,2), PRIMARY KEY (line_id, part_id))
* **Payment**(payment_id PK, sale_id FK→Sale NULL, so_id FK→ServiceOrder NULL, method ENUM('card','cash','ach','check','lender'), amount DECIMAL, paid_at)
* **VehicleTransfer**(transfer_id PK, vin FK→Vehicle, from_store_id FK→Store, to_store_id FK→Store, requested_at, completed_at NULL, status ENUM('requested','in_transit','completed','cancelled'))

---

## Relationship summary (cardinalities)

* Store 1—* Employee, 1—* Inventory, 1—* ServiceOrder, 1—* Technician.
* Make 1—* Model; Model 1—* Trim; Trim 1—* Vehicle.
* Vehicle 1—0..1 Inventory (per store presence), Vehicle 1—0..1 Sale, Vehicle 1—* TestDrive, Vehicle 1—* ServiceOrder, Vehicle 1—* VehicleTransfer.
* Customer 1—* Lead, 1—* Appointment, 1—* TestDrive, 1—* Sale, 1—* ServiceOrder.
* Sale 1—0..1 TradeIn, 1—0..1 FinanceContract, 1—* SaleWarranty, 1—* Payment.
* ServiceOrder 1—* ServiceLineItem, 1—* Payment; ServiceLineItem *—* Part via ServicePartUsage.

---

## ER Diagram (Mermaid syntax)

```mermaid
erDiagram
  STORE ||--o{ EMPLOYEE : employs
  STORE ||--o{ INVENTORY : holds
  STORE ||--o{ SERVICEORDER : opens
  STORE ||--o{ TECHNICIAN : staffs

  MAKE ||--o{ MODEL : has
  MODEL ||--o{ TRIM : has
  TRIM ||--o{ VEHICLE : defines

  VEHICLE ||--o| SALE : results_in
  VEHICLE ||--o{ TESTDRIVE : used_for
  VEHICLE ||--o{ SERVICEORDER : serviced_in
  VEHICLE ||--o{ VEHICLETRANSFER : moved_by

  CUSTOMER ||--o{ LEAD : creates
  CUSTOMER ||--o{ APPOINTMENT : schedules
  CUSTOMER ||--o{ TESTDRIVE : takes
  CUSTOMER ||--o{ SALE : buys
  CUSTOMER ||--o{ SERVICEORDER : requests

  SALE ||--o| TRADEIN : may_include
  SALE ||--o| FINANCECONTRACT : may_have
  SALE ||--o{ SALEWARRANTY : adds
  SALE ||--o{ PAYMENT : paid_by
  SERVICEORDER ||--o{ SERVICELINEITEM : contains
  SERVICELINEITEM }o--o{ PART : uses
  SERVICEORDER ||--o{ PAYMENT : paid_by
```

---

## DDL — Schema (MySQL 8)

> Engine=InnoDB, charset utf8mb4. Use `DECIMAL(12,2)` for money.

```sql
CREATE SCHEMA IF NOT EXISTS bn_motors;
USE bn_motors;

CREATE TABLE Store (
  store_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  phone VARCHAR(20), email VARCHAR(120),
  address VARCHAR(120), city VARCHAR(60), state CHAR(2), zip VARCHAR(10)
) ENGINE=InnoDB;

CREATE TABLE Employee (
  employee_id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  role ENUM('sales','advisor','manager','finance','parts','tech','admin') NOT NULL,
  first_name VARCHAR(40), last_name VARCHAR(40), email VARCHAR(120), phone VARCHAR(20),
  hired_at DATE, active BOOLEAN DEFAULT TRUE,
  CONSTRAINT fk_emp_store FOREIGN KEY (store_id) REFERENCES Store(store_id)
) ENGINE=InnoDB;

CREATE TABLE Customer (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(40), last_name VARCHAR(40), email VARCHAR(120), phone VARCHAR(20),
  dl_number VARCHAR(40), dl_state CHAR(2),
  address VARCHAR(120), city VARCHAR(60), state CHAR(2), zip VARCHAR(10),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Make (
  make_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(60) UNIQUE NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Model (
  model_id INT AUTO_INCREMENT PRIMARY KEY,
  make_id INT NOT NULL,
  name VARCHAR(60) NOT NULL,
  CONSTRAINT fk_model_make FOREIGN KEY (make_id) REFERENCES Make(make_id)
) ENGINE=InnoDB;

CREATE TABLE Trim (
  trim_id INT AUTO_INCREMENT PRIMARY KEY,
  model_id INT NOT NULL,
  year INT NOT NULL,
  trim_name VARCHAR(60), body_style VARCHAR(40), drivetrain VARCHAR(20),
  transmission VARCHAR(20), engine VARCHAR(60),
  CONSTRAINT fk_trim_model FOREIGN KEY (model_id) REFERENCES Model(model_id)
) ENGINE=InnoDB;

CREATE TABLE Vehicle (
  vin VARCHAR(17) PRIMARY KEY,
  trim_id INT NOT NULL,
  color_ext VARCHAR(40), color_int VARCHAR(40), mileage INT,
  `condition` ENUM('new','used') NOT NULL,
  acquired_via ENUM('factory','trade_in','auction','other'),
  acquisition_date DATE,
  msrp DECIMAL(12,2), cost DECIMAL(12,2), listed_price DECIMAL(12,2),
  status ENUM('in_stock','reserved','sold','service_hold','transfer') DEFAULT 'in_stock',
  CONSTRAINT fk_vehicle_trim FOREIGN KEY (trim_id) REFERENCES Trim(trim_id)
) ENGINE=InnoDB;

CREATE TABLE Inventory (
  inventory_id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  vin VARCHAR(17) NOT NULL UNIQUE,
  arrived_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  floorplan_lien BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_inv_store FOREIGN KEY (store_id) REFERENCES Store(store_id),
  CONSTRAINT fk_inv_vehicle FOREIGN KEY (vin) REFERENCES Vehicle(vin)
) ENGINE=InnoDB;

CREATE TABLE Lead (
  lead_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  store_id INT NOT NULL,
  source ENUM('web','walkin','phone','referral','event') NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  status ENUM('new','working','won','lost') DEFAULT 'new',
  notes TEXT,
  CONSTRAINT fk_lead_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  CONSTRAINT fk_lead_store FOREIGN KEY (store_id) REFERENCES Store(store_id)
) ENGINE=InnoDB;

CREATE TABLE Appointment (
  appt_id INT AUTO_INCREMENT PRIMARY KEY,
  lead_id INT NULL,
  customer_id INT NOT NULL,
  store_id INT NOT NULL,
  appt_type ENUM('sales','service','finance','other') NOT NULL,
  scheduled_at DATETIME NOT NULL,
  with_employee_id INT,
  CONSTRAINT fk_appt_lead FOREIGN KEY (lead_id) REFERENCES Lead(lead_id),
  CONSTRAINT fk_appt_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  CONSTRAINT fk_appt_store FOREIGN KEY (store_id) REFERENCES Store(store_id),
  CONSTRAINT fk_appt_employee FOREIGN KEY (with_employee_id) REFERENCES Employee(employee_id)
) ENGINE=InnoDB;

CREATE TABLE TestDrive (
  testdrive_id INT AUTO_INCREMENT PRIMARY KEY,
  vin VARCHAR(17) NOT NULL,
  customer_id INT NOT NULL,
  employee_id INT NOT NULL,
  store_id INT NOT NULL,
  start_ts DATETIME, end_ts DATETIME, route_notes TEXT,
  CONSTRAINT fk_td_vehicle FOREIGN KEY (vin) REFERENCES Vehicle(vin),
  CONSTRAINT fk_td_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  CONSTRAINT fk_td_employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id),
  CONSTRAINT fk_td_store FOREIGN KEY (store_id) REFERENCES Store(store_id)
) ENGINE=InnoDB;

CREATE TABLE Sale (
  sale_id INT AUTO_INCREMENT PRIMARY KEY,
  vin VARCHAR(17) NOT NULL UNIQUE,
  store_id INT NOT NULL,
  salesperson_id INT NOT NULL,
  customer_id INT NOT NULL,
  sale_date DATE NOT NULL,
  sale_price DECIMAL(12,2) NOT NULL,
  payment_type ENUM('cash','finance') NOT NULL,
  doc_fee DECIMAL(12,2) DEFAULT 0, tax DECIMAL(12,2) DEFAULT 0,
  total_out_the_door DECIMAL(12,2) GENERATED ALWAYS AS (sale_price + doc_fee + tax) STORED,
  cancelled BOOLEAN DEFAULT 0,
  CONSTRAINT fk_sale_vehicle FOREIGN KEY (vin) REFERENCES Vehicle(vin),
  CONSTRAINT fk_sale_store FOREIGN KEY (store_id) REFERENCES Store(store_id),
  CONSTRAINT fk_sale_salesperson FOREIGN KEY (salesperson_id) REFERENCES Employee(employee_id),
  CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
) ENGINE=InnoDB;

CREATE TABLE TradeIn (
  tradein_id INT AUTO_INCREMENT PRIMARY KEY,
  sale_id INT NOT NULL UNIQUE,
  vin_in VARCHAR(17), make_in VARCHAR(60), model_in VARCHAR(60), year_in INT, mileage_in INT,
  appraised_value DECIMAL(12,2), offer_value DECIMAL(12,2),
  CONSTRAINT fk_tradein_sale FOREIGN KEY (sale_id) REFERENCES Sale(sale_id)
) ENGINE=InnoDB;

CREATE TABLE Lender (
  lender_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL, contact_name VARCHAR(80), phone VARCHAR(20), email VARCHAR(120)
) ENGINE=InnoDB;

CREATE TABLE FinanceContract (
  contract_id INT AUTO_INCREMENT PRIMARY KEY,
  sale_id INT NOT NULL UNIQUE,
  lender_id INT NOT NULL,
  apr DECIMAL(5,3), term_months INT, amount_financed DECIMAL(12,2), monthly_payment DECIMAL(12,2), signed_at DATETIME,
  CONSTRAINT fk_fc_sale FOREIGN KEY (sale_id) REFERENCES Sale(sale_id),
  CONSTRAINT fk_fc_lender FOREIGN KEY (lender_id) REFERENCES Lender(lender_id)
) ENGINE=InnoDB;

CREATE TABLE Warranty (
  warranty_id INT AUTO_INCREMENT PRIMARY KEY,
  provider VARCHAR(80), name VARCHAR(80), coverage_miles INT, coverage_months INT
) ENGINE=InnoDB;

CREATE TABLE SaleWarranty (
  sale_id INT NOT NULL,
  warranty_id INT NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (sale_id, warranty_id),
  CONSTRAINT fk_sw_sale FOREIGN KEY (sale_id) REFERENCES Sale(sale_id),
  CONSTRAINT fk_sw_warranty FOREIGN KEY (warranty_id) REFERENCES Warranty(warranty_id)
) ENGINE=InnoDB;

CREATE TABLE Technician (
  tech_id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  first_name VARCHAR(40), last_name VARCHAR(40), ase_level VARCHAR(20), active BOOLEAN DEFAULT TRUE,
  CONSTRAINT fk_tech_store FOREIGN KEY (store_id) REFERENCES Store(store_id)
) ENGINE=InnoDB;

CREATE TABLE ServiceOrder (
  so_id INT AUTO_INCREMENT PRIMARY KEY,
  store_id INT NOT NULL,
  vin VARCHAR(17) NOT NULL,
  customer_id INT NULL,
  opened_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  closed_at DATETIME NULL,
  odometer_in INT, odometer_out INT NULL,
  advisor_id INT NOT NULL,
  status ENUM('open','in_progress','closed','void') DEFAULT 'open',
  CONSTRAINT fk_so_store FOREIGN KEY (store_id) REFERENCES Store(store_id),
  CONSTRAINT fk_so_vehicle FOREIGN KEY (vin) REFERENCES Vehicle(vin),
  CONSTRAINT fk_so_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
  CONSTRAINT fk_so_advisor FOREIGN KEY (advisor_id) REFERENCES Employee(employee_id)
) ENGINE=InnoDB;

CREATE TABLE Supplier (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL, phone VARCHAR(20), email VARCHAR(120)
) ENGINE=InnoDB;

CREATE TABLE Part (
  part_id INT AUTO_INCREMENT PRIMARY KEY,
  supplier_id INT NOT NULL,
  sku VARCHAR(60) UNIQUE, name VARCHAR(120),
  unit_cost DECIMAL(12,2), unit_price DECIMAL(12,2), taxable BOOLEAN DEFAULT TRUE,
  CONSTRAINT fk_part_supplier FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id)
) ENGINE=InnoDB;

CREATE TABLE ServiceLineItem (
  line_id INT AUTO_INCREMENT PRIMARY KEY,
  so_id INT NOT NULL,
  tech_id INT NULL,
  labor_code VARCHAR(20), description VARCHAR(200),
  hours DECIMAL(5,2) DEFAULT 0, labor_rate DECIMAL(6,2) DEFAULT 0,
  warranty_id INT NULL,
  CONSTRAINT fk_li_so FOREIGN KEY (so_id) REFERENCES ServiceOrder(so_id),
  CONSTRAINT fk_li_tech FOREIGN KEY (tech_id) REFERENCES Technician(tech_id),
  CONSTRAINT fk_li_warranty FOREIGN KEY (warranty_id) REFERENCES Warranty(warranty_id)
) ENGINE=InnoDB;

CREATE TABLE ServicePartUsage (
  line_id INT NOT NULL,
  part_id INT NOT NULL,
  qty DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (line_id, part_id),
  CONSTRAINT fk_spu_line FOREIGN KEY (line_id) REFERENCES ServiceLineItem(line_id),
  CONSTRAINT fk_spu_part FOREIGN KEY (part_id) REFERENCES Part(part_id)
) ENGINE=InnoDB;

CREATE TABLE Payment (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  sale_id INT NULL,
  so_id INT NULL,
  method ENUM('card','cash','ach','check','lender') NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pay_sale FOREIGN KEY (sale_id) REFERENCES Sale(sale_id),
  CONSTRAINT fk_pay_so FOREIGN KEY (so_id) REFERENCES ServiceOrder(so_id)
) ENGINE=InnoDB;

CREATE TABLE VehicleTransfer (
  transfer_id INT AUTO_INCREMENT PRIMARY KEY,
  vin VARCHAR(17) NOT NULL,
  from_store_id INT NOT NULL,
  to_store_id INT NOT NULL,
  requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  status ENUM('requested','in_transit','completed','cancelled') DEFAULT 'requested',
  CONSTRAINT fk_tr_vin FOREIGN KEY (vin) REFERENCES Vehicle(vin),
  CONSTRAINT fk_tr_from FOREIGN KEY (from_store_id) REFERENCES Store(store_id),
  CONSTRAINT fk_tr_to FOREIGN KEY (to_store_id) REFERENCES Store(store_id)
) ENGINE=InnoDB;
```

---

## Seed & synthetic data (coming next)

* Deterministic generators for Make/Model/Trim using real OEM lists.
* VIN generator (check‑digit valid) for realism (or use faker VINs).
* Personas for customers; realistic price, APR, term distributions.
* Service events distribution by age/mileage.

---

## Query ideas (to build later)

1. **Gross & front‑end profit** by store, model, salesperson; rolling 90‑day.
2. **Finance penetration** rate and average APR by lender and store.
3. **Turn rate / days‑in‑stock** per VIN and per model.
4. **Service RO efficiency**: hours billed vs clocked by technician; parts‑to‑labor ratio.
5. **Warranty leakage**: eligible repairs not claimed under warranty.
6. **Lead funnel**: time‑to‑first‑contact, show rate, close rate.
7. **Transfer optimization**: which models should be rebalanced between stores.

---

## Repo structure suggestion

```
/ddl/  -> .sql schema files
/seed/ -> CSVs + generators for synthetic data
/queries/ -> analysis SQL grouped by domain
/docs/ -> ERD PNG/PDF, business rules, README assets
```

> v1 complete. We can iterate and extend (e.g., insurance, test‑drive incidents, OEM incentives) as needed.
