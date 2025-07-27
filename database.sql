CREATE DATABASE GarageManagement;
USE GarageManagement;

-- Tables
CREATE TABLE Customer (
    CustomerID VARCHAR(10) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15),
    Password VARCHAR(255) NOT NULL,
    VehicleID VARCHAR(15) UNIQUE
);

CREATE TABLE Mechanic (
    MechanicID VARCHAR(10) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Level CHAR(1) CHECK (Level IN ('S', 'J')),
    Experience INT,
    Status ENUM('Active', 'Inactive') DEFAULT 'Active'
);

CREATE TABLE Supplier (
    SupplierID VARCHAR(10) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    ShopName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Phone VARCHAR(15)
);

CREATE TABLE Owner (
    OwnerID VARCHAR(10) PRIMARY KEY,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL
);

CREATE TABLE Vehicle (
    VehicleID VARCHAR(15) PRIMARY KEY,
    CustomerID VARCHAR(10),
    Manufacturer VARCHAR(50),
    Model VARCHAR(50),
    FuelType ENUM('Petrol', 'Diesel', 'Electric', 'Hybrid', 'CNG'),
    Year DATE,
    Mileage INT DEFAULT 0, -- Added Mileage field
    WarrantyUntil DATE, -- Added WarrantyUntil field
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

CREATE TABLE Service (
    ServiceID VARCHAR(10) PRIMARY KEY,
    ServiceType ENUM('Mechanical', 'Electrical', 'Others') NOT NULL,
    Description TEXT,
    Cost DECIMAL(10, 2) NOT NULL,
    Status ENUM('Pending', 'Completed') DEFAULT 'Pending',
    MechanicID VARCHAR(10),
    FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID)
);

CREATE TABLE Appointment (
    AppointmentID VARCHAR(10) PRIMARY KEY,
    CustomerID VARCHAR(10),
    ServiceID VARCHAR(10),
    Date DATETIME NOT NULL,
    Status ENUM('Not Yet Booked', 'Confirmed', 'Completed') DEFAULT 'Not Yet Booked',
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID)
);

CREATE TABLE Inventory (
    InventoryID VARCHAR(10) PRIMARY KEY,
    SupplierID VARCHAR(10),
    ItemName VARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

CREATE TABLE InventoryRequest (
    RequestID VARCHAR(10) PRIMARY KEY,
    MechanicID VARCHAR(10),
    ItemName VARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    Status ENUM('Pending', 'Approved', 'Denied') DEFAULT 'Pending',
    FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID)
);

CREATE TABLE Invoice (
    InvoiceID VARCHAR(10) PRIMARY KEY,
    CustomerID VARCHAR(10),
    ServiceID VARCHAR(10),
    Amount DECIMAL(10, 2) NOT NULL,
    PaymentMethod ENUM('Online', 'Cash'),
    PaymentStatus ENUM('Pending', 'Paid') DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID)
);

CREATE TABLE ServiceHistory (
    HistoryID VARCHAR(10) PRIMARY KEY,
    ServiceID VARCHAR(10),
    CustomerID VARCHAR(10),
    MechanicID VARCHAR(10),
    CompletionDate DATETIME,
    FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID)
);

CREATE TABLE Recommendation (
    RecommendationID VARCHAR(10) PRIMARY KEY,
    CustomerID VARCHAR(10),
    ServiceID VARCHAR(10),
    RecommendationText TEXT,
    Priority ENUM('Low', 'Medium', 'High') DEFAULT 'Medium', -- Added Priority field
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID)
);

-- New Table: Recall Notices
CREATE TABLE RecallNotice (
    RecallID VARCHAR(10) PRIMARY KEY,
    Manufacturer VARCHAR(50),
    Model VARCHAR(50),
    IssueDescription TEXT,
    IssueDate DATE
);

-- New Table: Service Frequency Tracking
CREATE TABLE ServiceFrequency (
    FrequencyID VARCHAR(10) PRIMARY KEY,
    CustomerID VARCHAR(10),
    ServiceDescription VARCHAR(255),
    FrequencyCount INT DEFAULT 0,
    LastServiced DATETIME,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- Triggers for Auto-Generated IDs
DELIMITER //
CREATE TRIGGER before_insert_customer
BEFORE INSERT ON Customer
FOR EACH ROW
BEGIN
    SET NEW.CustomerID = CONCAT('C', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(CustomerID, 2) AS UNSIGNED)), 0) + 1 FROM Customer), 3, '0'));
END;//

CREATE TRIGGER before_insert_mechanic
BEFORE INSERT ON Mechanic
FOR EACH ROW
BEGIN
    SET NEW.MechanicID = CONCAT('M', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(MechanicID, 2) AS UNSIGNED)), 0) + 1 FROM Mechanic), 3, '0'));
END;//

CREATE TRIGGER before_insert_supplier
BEFORE INSERT ON Supplier
FOR EACH ROW
BEGIN
    SET NEW.SupplierID = CONCAT('S', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(SupplierID, 2) AS UNSIGNED)), 0) + 1 FROM Supplier), 3, '0'));
END;//

CREATE TRIGGER before_insert_service
BEFORE INSERT ON Service
FOR EACH ROW
BEGIN
    SET NEW.ServiceID = CONCAT('SV', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(ServiceID, 3) AS UNSIGNED)), 0) + 1 FROM Service), 3, '0'));
END;//

CREATE TRIGGER before_insert_appointment
BEFORE INSERT ON Appointment
FOR EACH ROW
BEGIN
    SET NEW.AppointmentID = CONCAT('A', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(AppointmentID, 2) AS UNSIGNED)), 0) + 1 FROM Appointment), 3, '0'));
END;//

CREATE TRIGGER before_insert_inventory
BEFORE INSERT ON Inventory
FOR EACH ROW
BEGIN
    SET NEW.InventoryID = CONCAT('I', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(InventoryID, 2) AS UNSIGNED)), 0) + 1 FROM Inventory), 3, '0'));
END;//

CREATE TRIGGER before_insert_inventory_request
BEFORE INSERT ON InventoryRequest
FOR EACH ROW
BEGIN
    SET NEW.RequestID = CONCAT('IR', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(RequestID, 3) AS UNSIGNED)), 0) + 1 FROM InventoryRequest), 3, '0'));
END;//

CREATE TRIGGER before_insert_invoice
BEFORE INSERT ON Invoice
FOR EACH ROW
BEGIN
    SET NEW.InvoiceID = CONCAT('IN', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(InvoiceID, 3) AS UNSIGNED)), 0) + 1 FROM Invoice), 3, '0'));
END;//

CREATE TRIGGER before_insert_service_history
BEFORE INSERT ON ServiceHistory
FOR EACH ROW
BEGIN
    SET NEW.HistoryID = CONCAT('SH', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(HistoryID, 3) AS UNSIGNED)), 0) + 1 FROM ServiceHistory), 3, '0'));
END;//

CREATE TRIGGER before_insert_recommendation
BEFORE INSERT ON Recommendation
FOR EACH ROW
BEGIN
    SET NEW.RecommendationID = CONCAT('R', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(RecommendationID, 2) AS UNSIGNED)), 0) + 1 FROM Recommendation), 3, '0'));
END;//

CREATE TRIGGER before_insert_recall_notice
BEFORE INSERT ON RecallNotice
FOR EACH ROW
BEGIN
    SET NEW.RecallID = CONCAT('RC', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(RecallID, 3) AS UNSIGNED)), 0) + 1 FROM RecallNotice), 3, '0'));
END;//

CREATE TRIGGER before_insert_service_frequency
BEFORE INSERT ON ServiceFrequency
FOR EACH ROW
BEGIN
    SET NEW.FrequencyID = CONCAT('SF', LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(FrequencyID, 3) AS UNSIGNED)), 0) + 1 FROM ServiceFrequency), 3, '0'));
END;//

-- Trigger to Move Completed Services to History and Update Service Frequency
CREATE TRIGGER after_service_completion
AFTER UPDATE ON Service
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Completed' AND OLD.Status = 'Pending' THEN
        INSERT INTO ServiceHistory (ServiceID, CustomerID, MechanicID, CompletionDate)
        SELECT s.ServiceID, a.CustomerID, s.MechanicID, NOW()
        FROM Service s
        JOIN Appointment a ON s.ServiceID = a.ServiceID
        WHERE s.ServiceID = NEW.ServiceID;

        -- Update Service Frequency
        INSERT INTO ServiceFrequency (CustomerID, ServiceDescription, FrequencyCount, LastServiced)
        SELECT a.CustomerID, NEW.Description, 1, NOW()
        FROM Appointment a
        WHERE a.ServiceID = NEW.ServiceID
        ON DUPLICATE KEY UPDATE
            FrequencyCount = FrequencyCount + 1,
            LastServiced = NOW();

        CALL GenerateInvoice(NEW.ServiceID);
    END IF;
END;//

-- Procedures
CREATE PROCEDURE AddService(
    IN p_ServiceType ENUM('Mechanical', 'Electrical', 'Others'),
    IN p_Description TEXT,
    IN p_Cost DECIMAL(10, 2),
    IN p_MechanicID VARCHAR(10)
)
BEGIN
    INSERT INTO Service (ServiceType, Description, Cost, MechanicID)
    VALUES (p_ServiceType, p_Description, p_Cost, p_MechanicID);
END;//

CREATE PROCEDURE GenerateInvoice(IN p_ServiceID VARCHAR(10))
BEGIN
    DECLARE v_CustomerID VARCHAR(10);
    DECLARE v_Amount DECIMAL(10, 2);
    SELECT CustomerID INTO v_CustomerID FROM Appointment WHERE ServiceID = p_ServiceID LIMIT 1;
    SELECT Cost INTO v_Amount FROM Service WHERE ServiceID = p_ServiceID;
    INSERT INTO Invoice (CustomerID, ServiceID, Amount, PaymentMethod, PaymentStatus)
    VALUES (v_CustomerID, p_ServiceID, v_Amount, 'Cash', 'Pending');
END;//

CREATE PROCEDURE GenerateRecommendations(IN p_CustomerID VARCHAR(10))
BEGIN
    DECLARE v_Year DATE;
    DECLARE v_Model VARCHAR(50);
    DECLARE v_Manufacturer VARCHAR(50);
    DECLARE v_FuelType ENUM('Petrol', 'Diesel', 'Electric', 'Hybrid', 'CNG');
    DECLARE v_Mileage INT;
    DECLARE v_WarrantyUntil DATE;
    DECLARE v_Age INT;
    DECLARE v_CurrentMonth INT;

    -- Fetch vehicle details
    SELECT v.Year, v.Model, v.Manufacturer, v.FuelType, v.Mileage, v.WarrantyUntil
    INTO v_Year, v_Model, v_Manufacturer, v_FuelType, v_Mileage, v_WarrantyUntil
    FROM Vehicle v
    JOIN Customer c ON v.CustomerID = c.CustomerID
    WHERE c.CustomerID = p_CustomerID;

    SET v_Age = YEAR(CURDATE()) - YEAR(v_Year);
    SET v_CurrentMonth = MONTH(CURDATE());

    -- 1. Age-Based Recommendations
    IF v_Age > 10 THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for older vehicles: Engine Tune-up', 'High'
        FROM Service s
        WHERE s.Description = 'Engine Tune-up'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for older vehicles: Engine Tune-up'
        );

        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for older vehicles: Suspension Check', 'Medium'
        FROM Service s
        WHERE s.Description = 'Suspension Repair'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for older vehicles: Suspension Check'
        );
    END IF;

    IF v_Age > 5 THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for vehicles over 5 years: Brake Inspection', 'Medium'
        FROM Service s
        WHERE s.Description = 'Brake Repair'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for vehicles over 5 years: Brake Inspection'
        );
    END IF;

    -- 2. Fuel Type-Based Recommendations
    IF v_FuelType = 'Electric' THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for electric vehicles: Battery Health Check', 'High'
        FROM Service s
        WHERE s.Description = 'Battery Replacement'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for electric vehicles: Battery Health Check'
        );

        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for electric vehicles: ECM Diagnostics', 'Medium'
        FROM Service s
        WHERE s.Description = 'ECM Diagnostics'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for electric vehicles: ECM Diagnostics'
        );
    END IF;

    IF v_FuelType = 'Diesel' THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for diesel vehicles: Fuel Filter Replacement', 'Medium'
        FROM Service s
        WHERE s.Description = 'General Inspection'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for diesel vehicles: Fuel Filter Replacement'
        );
    END IF;

    IF v_FuelType = 'Petrol' THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for petrol vehicles: Spark Plug Check', 'Medium'
        FROM Service s
        WHERE s.Description = 'Engine Tune-up'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for petrol vehicles: Spark Plug Check'
        );
    END IF;

    IF v_FuelType = 'Hybrid' THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for hybrid vehicles: Hybrid Battery Check', 'High'
        FROM Service s
        WHERE s.Description = 'Battery Replacement'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for hybrid vehicles: Hybrid Battery Check'
        );
    END IF;

    IF v_FuelType = 'CNG' THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Recommended for CNG vehicles: CNG Tank Inspection', 'High'
        FROM Service s
        WHERE s.Description = 'General Inspection'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Recommended for CNG vehicles: CNG Tank Inspection'
        );
    END IF;

    -- 3. Mileage-Based Recommendations
    IF v_Mileage >= 50000 THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Mileage over 50,000 km: Transmission Check Recommended', 'High'
        FROM Service s
        WHERE s.Description = 'Transmission Repair'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Mileage over 50,000 km: Transmission Check Recommended'
        );
    END IF;

    IF v_Mileage >= 30000 THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Mileage over 30,000 km: Wheel Alignment Recommended', 'Medium'
        FROM Service s
        WHERE s.Description = 'Wheel Alignment'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Mileage over 30,000 km: Wheel Alignment Recommended'
        );
    END IF;

    IF v_Mileage >= 10000 THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Mileage over 10,000 km: Oil Change Recommended', 'Medium'
        FROM Service s
        WHERE s.Description = 'Oil Change'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Mileage over 10,000 km: Oil Change Recommended'
        );
    END IF;

    -- 4. Seasonal Recommendations
    IF v_CurrentMonth IN (4, 5, 6) THEN -- Summer months (April to June)
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Summer season: AC Servicing Recommended', 'Medium'
        FROM Service s
        WHERE s.Description = 'General Inspection'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Summer season: AC Servicing Recommended'
        );
    END IF;

    IF v_CurrentMonth IN (11, 12, 1) THEN -- Winter months (November to January)
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Winter season: Heater Check Recommended', 'Medium'
        FROM Service s
        WHERE s.Description = 'General Inspection'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Winter season: Heater Check Recommended'
        );
    END IF;

    -- 5. Manufacturer and Model-Specific Recommendations
    IF v_Manufacturer = 'Toyota' AND v_Model IN ('Innova Crysta', 'Innova Hycross') THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Toyota Innova: Recommended Brake Pad Replacement', 'Medium'
        FROM Service s
        WHERE s.Description = 'Brake Repair'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Toyota Innova: Recommended Brake Pad Replacement'
        );
    END IF;

    IF v_Manufacturer = 'Hyundai' AND v_Model = 'Creta' THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Hyundai Creta: Recommended Suspension Check', 'Medium'
        FROM Service s
        WHERE s.Description = 'Suspension Repair'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Hyundai Creta: Recommended Suspension Check'
        );
    END IF;

    IF v_Manufacturer = 'Tesla' AND v_Model IN ('Model 3', 'Model S', 'Model X', 'Model Y') THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Tesla: Recommended Software Update Check', 'High'
        FROM Service s
        WHERE s.Description = 'ECM Diagnostics'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Tesla: Recommended Software Update Check'
        );
    END IF;

    IF v_Manufacturer = 'Mahindra' AND v_Model IN ('Scorpio N', 'Thar') THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Mahindra Scorpio/Thar: Recommended Off-Road Suspension Check', 'Medium'
        FROM Service s
        WHERE s.Description = 'Suspension Repair'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Mahindra Scorpio/Thar: Recommended Off-Road Suspension Check'
        );
    END IF;

    IF v_Manufacturer = 'BMW' AND v_Model IN ('X5', 'X7') THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'BMW X5/X7: Recommended Luxury Vehicle Maintenance Check', 'High'
        FROM Service s
        WHERE s.Description = 'General Inspection'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'BMW X5/X7: Recommended Luxury Vehicle Maintenance Check'
        );
    END IF;

    -- 6. Recall Notices
    INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
    SELECT p_CustomerID, s.ServiceID, CONCAT('Recall Notice for ', v_Manufacturer, ' ', v_Model, ': ', r.IssueDescription), 'High'
    FROM RecallNotice r
    JOIN Service s ON s.Description = 'General Inspection'
    WHERE r.Manufacturer = v_Manufacturer AND r.Model = v_Model
    AND NOT EXISTS (
        SELECT 1 FROM Recommendation rec
        WHERE rec.CustomerID = p_CustomerID
        AND rec.RecommendationText LIKE CONCAT('Recall Notice for ', v_Manufacturer, ' ', v_Model, '%')
    );

    -- 7. Warranty-Based Recommendations
    IF v_WarrantyUntil IS NOT NULL AND v_WarrantyUntil >= CURDATE() THEN
        INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
        SELECT p_CustomerID, s.ServiceID, 'Vehicle under warranty: Schedule a Free General Inspection', 'Low'
        FROM Service s
        WHERE s.Description = 'General Inspection'
        AND NOT EXISTS (
            SELECT 1 FROM Recommendation r
            WHERE r.CustomerID = p_CustomerID AND r.RecommendationText = 'Vehicle under warranty: Schedule a Free General Inspection'
        );
    END IF;

    -- 8. Service Frequency-Based Recommendations
    INSERT INTO Recommendation (CustomerID, ServiceID, RecommendationText, Priority)
    SELECT sf.CustomerID, s.ServiceID,
           CONCAT('Frequent ', sf.ServiceDescription, ' (', sf.FrequencyCount, ' times): Consider Preventative Maintenance'), 'Medium'
    FROM ServiceFrequency sf
    JOIN Service s ON s.Description = sf.ServiceDescription
    WHERE sf.CustomerID = p_CustomerID
    AND sf.FrequencyCount >= 3
    AND NOT EXISTS (
        SELECT 1 FROM Recommendation r
        WHERE r.CustomerID = p_CustomerID
        AND r.RecommendationText LIKE CONCAT('Frequent ', sf.ServiceDescription, '%')
    );
END;//

DELIMITER ;

-- Sample Data
INSERT INTO Owner (OwnerID, Email, Password) VALUES ('O001', 'owner@garage.com', 'password');
INSERT INTO Mechanic (Name, Email, Password, Level, Experience) VALUES
('John Doe', 'john@example.com', 'password', 'S', 5),
('Jane Smith', 'jane@example.com', 'password', 'J', 2);

-- Default Service Catalog (Expanded)
CALL AddService('Mechanical', 'Oil Change', 50.00, NULL);
CALL AddService('Mechanical', 'Brake Repair', 120.00, NULL);
CALL AddService('Mechanical', 'Wheel Alignment', 80.00, NULL);
CALL AddService('Mechanical', 'Transmission Repair', 300.00, NULL);
CALL AddService('Mechanical', 'Suspension Repair', 200.00, NULL);
CALL AddService('Mechanical', 'Engine Tune-up', 100.00, NULL);
CALL AddService('Electrical', 'Battery Replacement', 80.00, NULL);
CALL AddService('Electrical', 'Alternator Repair', 150.00, NULL);
CALL AddService('Electrical', 'Starter Motor Repair', 120.00, NULL);
CALL AddService('Electrical', 'Wiring Repair', 100.00, NULL);
CALL AddService('Electrical', 'Lighting System Repair', 60.00, NULL);
CALL AddService('Electrical', 'ECM Diagnostics', 200.00, NULL);
CALL AddService('Others', 'General Inspection', 50.00, NULL);
CALL AddService('Others', 'AC Servicing', 70.00, NULL);
CALL AddService('Others', 'Heater Check', 60.00, NULL);
CALL AddService('Mechanical', 'Fuel Filter Replacement', 90.00, NULL);
CALL AddService('Mechanical', 'Spark Plug Replacement', 40.00, NULL);
CALL AddService('Others', 'CNG Tank Inspection', 100.00, NULL);
CALL AddService('Electrical', 'Hybrid Battery Check', 150.00, NULL);

-- Sample Recall Notices
INSERT INTO RecallNotice (Manufacturer, Model, IssueDescription, IssueDate) VALUES
('Toyota', 'Innova Crysta', 'Faulty Brake System Recall', '2024-01-15'),
('Hyundai', 'Creta', 'Fuel Pump Issue Recall', '2023-06-20'),
('Tesla', 'Model 3', 'Software Update Required for Battery Management', '2024-03-01'),
('Mahindra', 'Scorpio N', 'Suspension Bolt Recall', '2023-12-10');