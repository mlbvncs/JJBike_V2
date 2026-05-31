CREATE DATABASE Dimensional
GO

CREATE TABLE Dimensional..dim_seller(
  seller_key int IDENTITY PRIMARY KEY,
  id_seller int NOT NULL,
  seller_name Varchar(50) NOT NULL,
  validity_start_date DATETIME NOT NULL,
  validity_end_date DATETIME
);

CREATE TABLE Dimensional..dim_customer(
  customer_key int IDENTITY PRIMARY KEY,
  id_customer int NOT NULL,
  customer_name Varchar(50) NOT NULL,
  customer_state Varchar(2) NOT NULL,
  customer_gender Char(1) NOT NULL,
  customer_status Varchar(50) NOT NULL,
  validity_start_date DATETIME NOT NULL,
  validity_end_date DATETIME
);

CREATE TABLE Dimensional..dim_product(
  product_key int IDENTITY PRIMARY KEY,
  id_product int NOT NULL,
  product_name Varchar(100) NOT NULL,
  validity_start_date DATETIME NOT NULL,
  validity_end_date DATETIME
);

CREATE TABLE Dimensional..dim_time(
  time_key int IDENTITY PRIMARY KEY,
  time_date DATETIME NOT NULL,
  time_day int NOT NULL,
  time_month int NOT NULL,
  time_year int NOT NULL,
  time_weekday int NOT NULL,
  time_quarter int NOT NULL
);

CREATE TABLE Dimensional..fact_sales(
  sale_key int IDENTITY PRIMARY KEY,
  seller_key int NOT NULL,
  customer_key int NOT NULL,
  product_key int NOT NULL,
  time_key int NOT NULL,
  quantity int NOT NULL,
  unit_price Numeric(10,2) NOT NULL,
  total_price Numeric(10,2) NOT NULL,
  discount Numeric(10,2) NOT NULL
);
