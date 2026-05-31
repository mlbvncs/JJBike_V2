CREATE DATABASE Relational
GO

CREATE TABLE Relational..sellers(
  id_seller int IDENTITY PRIMARY KEY,
  seller_name Varchar(50) NOT NULL
);

CREATE TABLE Relational..products(
  id_product int IDENTITY PRIMARY KEY,
  product_name Varchar(100) NOT NULL,
  product_price Numeric(10,2) NOT NULL
);

CREATE TABLE Relational..customers(
  id_customer int IDENTITY PRIMARY KEY,
  customer_name Varchar(50) NOT NULL,
  customer_state Varchar(2) NOT NULL,
  customer_gender Char(1) NOT NULL,
  customer_status Varchar(50) NOT NULL
);

CREATE TABLE Relational..sales(
  id_sale int IDENTITY PRIMARY KEY,
  id_seller int NOT NULL,
  id_customer int NOT NULL,
  sale_date DATETIME NOT NULL,
  total Numeric(10,2) NOT NULL
);
ALTER TABLE Relational..sales ADD CONSTRAINT FK_SALES_SELLER   FOREIGN KEY (id_seller)   REFERENCES Relational..sellers  (id_seller);
ALTER TABLE Relational..sales ADD CONSTRAINT FK_SALES_CUSTOMER FOREIGN KEY (id_customer) REFERENCES Relational..customers (id_customer);

CREATE TABLE Relational..sale_items (
    id_product int NOT NULL,
    id_sale int NOT NULL,
    quantity int NOT NULL,
    unit_price decimal(10,2) NOT NULL,
    total_price decimal(10,2) NOT NULL,
    discount decimal(10,2) NOT NULL,
    PRIMARY KEY (id_product, id_sale)
);
ALTER TABLE Relational..sale_items ADD CONSTRAINT FK_SALEITEMS_PRODUCT FOREIGN KEY (id_product) REFERENCES Relational..products (id_product);
ALTER TABLE Relational..sale_items ADD CONSTRAINT FK_SALEITEMS_SALE    FOREIGN KEY (id_sale)    REFERENCES Relational..sales    (id_sale);
