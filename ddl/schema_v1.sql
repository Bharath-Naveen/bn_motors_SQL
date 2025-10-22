CREATE SCHEMA IF NOT EXISTS bn_motors;
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
