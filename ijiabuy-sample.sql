###### MMS ######

DROP SCHEMA IF EXISTS MMS;
CREATE SCHEMA MMS;
USE MMS;

CREATE TABLE mms_customers (
	customer_id BINARY(16) 		PRIMARY KEY, 
	first_name VARCHAR(50) 		NOT NULL,
	last_name VARCHAR(50) 		NOT NULL,
	dob DATE 					NOT NULL, 
	pri_phone INT, 				#fk
	pri_email INT, 				#fk
	pri_shipaddress INT, 		#fk
	pri_payment TINYINT 		#0 pp, 1 card, 2 apple, 3 google
	#assumes payment AA is stored clientside, otherwise make pay_method table and ref to that
);

CREATE TABLE email (
	email_id INT PRIMARY KEY,	#ai
	customer_id BINARY(16),		#fk
	email_address VARCHAR(50), 	#must have @ and .
	is_primary BOOLEAN 			NOT NULL DEFAULT FALSE,
	FOREIGN KEY(customer_id) REFERENCES mms_customers(customer_id) ON DELETE CASCADE
);
ALTER TABLE mms_customers
ADD FOREIGN KEY(pri_email)
REFERENCES email(email_id)
ON DELETE CASCADE;

CREATE TABLE phone (
	phone_id INT PRIMARY KEY, 	#ai
	customer_id BINARY(16), 	#fk
	area_code TINYINT,
	phone_num INT,
	is_primary BOOLEAN 			NOT NULL DEFAULT FALSE,
	FOREIGN KEY(customer_id) REFERENCES mms_customers(customer_id) ON DELETE CASCADE
);
ALTER TABLE mms_customers
ADD FOREIGN KEY(pri_phone)
REFERENCES phone(phone_id)
ON DELETE CASCADE;

CREATE TABLE shipping_address (
	shipaddress_id INT 			PRIMARY KEY, #ai
	customer_id BINARY(16), 	#fk
	address1 VARCHAR(50),
	address2 VARCHAR(50),
	city VARCHAR(50),
	state VARCHAR(2),
	postal_code SMALLINT,
	is_primary BOOLEAN 			NOT NULL DEFAULT FALSE,
	FOREIGN KEY(customer_id) REFERENCES mms_customers(customer_id) ON DELETE CASCADE
);
ALTER TABLE mms_customers
ADD FOREIGN KEY(pri_shipaddress)
REFERENCES shipping_address(shipaddress_id)
ON DELETE CASCADE;

CREATE TABLE social (
	social_type TINYINT, 		#0 ig, 1 fb, 2 wc
	customer_id BINARY(16), 	#fk
	verified BOOLEAN 			NOT NULL DEFAULT FALSE,
	FOREIGN KEY(customer_id) REFERENCES mms_customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE wishlists (
	wishlist_id INT, 			#ai #pk
	wishlist_name VARCHAR(20),
	customer_id BINARY(16), 	#fk
	item_added VARCHAR(30), 	#fk to PMS
    date_added 	DATETIME,		#at time added to wishlist
	FOREIGN KEY(customer_id) REFERENCES mms_customers(customer_id) ON DELETE CASCADE
);

###### PMS ######

DROP SCHEMA IF EXISTS PMS;
CREATE SCHEMA PMS;
USE PMS;

CREATE TABLE pms_items (
-- table shows products being shown on platform, called items, both US and CH
	item_id VARCHAR(30),		#concatenate region + product_id
    region TINYINT,				#0 US, 1 CH
    product_id INT,				#fk
    item_price DECIMAL(8,2) 	DEFAULT 0,
    item_qty INT				# result of product stock_qty + DMS warehouse_qty
);

ALTER TABLE MMS.wishlists
ADD FOREIGN KEY(item_added)
REFERENCES pms_items(item_id)
ON DELETE CASCADE;

CREATE TABLE pms_units (
-- table shows the order info needed to place the order for an item, not dispayed on platform
	unit_id INT,
    item_id	INT,				# fk 
    unit_price	DECIMAL(8,2),	# cost per unit
    unit_size INT,				# item qty per unit
    unit_weight FLOAT,			# weight per unit in kg
    shipping_method TINYINT(1)	# decides cost per weight
);

CREATE TABLE ch_products (
-- table shows products from China suppliers/vendors, receives batch update from China
    product_id int,
    vendor_id BINARY(16), 
	product_name varchar(45),
	product_info json, 
	product_desc tinytext, 
	product_img blob, 
	stock_qty smallint,
    FOREIGN KEY(vendor_id) REFERENCES ch_vendors(vendor_id)
);
ALTER TABLE pms_items
ADD FOREIGN KEY(product_id)
REFERENCES ch_products(product_id)
ON DELETE CASCADE;

CREATE TABLE us_products (
-- table shows products from US suppliers/vendors. we will batch update China
    product_id int,
    vendor_id BINARY(16), 		# UUID()
	product_name varchar(45),
	product_info json, 
	product_desc tinytext, 
	product_img blob, 
	stock_qty smallint,
    FOREIGN KEY(vendor_id) REFERENCES us_vendors(vendor_id)
);
ALTER TABLE pms_items
ADD FOREIGN KEY(product_id)
REFERENCES us_products(product_id)
ON DELETE CASCADE;

CREATE TABLE ch_vendors (
	vendor_id BINARY(16), 		# UUID()
    vendor_name VARCHAR(50),
    vendor_type TINYINT,  		# 0 supplier, 1 pay flat, 2 pay percent
    address_1 VARCHAR(50),		
    address_2 VARCHAR(50),		
    province VARCHAR(30),		
    city VARCHAR(30),			
    postal_code INT(6)			
);
CREATE TABLE us_vendors (
	vendor_id BINARY(16), 		# UUID()
    vendor_name VARCHAR(50),
    vendor_type TINYINT,  		# 0 supplier, 1 pay flat, 2 pay percent
    address_1 VARCHAR(50),
    address_2 VARCHAR(50),
    city VARCHAR(30),
    state VARCHAR(30),
    postal_code INT(6)
);