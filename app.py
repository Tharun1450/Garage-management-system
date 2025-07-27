from flask import Flask, render_template, request, redirect, url_for, session, flash
from utils.db_utils import execute_query, fetch_query
from datetime import datetime
import logging


logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = 'your_secret_key'


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/', methods=['POST'])
def login():
    email = request.form['email']
    password = request.form['password']

    owner = fetch_query("SELECT * FROM Owner WHERE Email = %s AND Password = %s", (email, password))
    if owner:
        session['user_type'] = 'owner'
        session['user_id'] = owner[0]['OwnerID']
        return redirect(url_for('owner_dashboard'))

    customer = fetch_query("SELECT * FROM Customer WHERE Email = %s AND Password = %s", (email, password))
    if customer:
        session['user_type'] = 'customer'
        session['user_id'] = customer[0]['CustomerID']
        return redirect(url_for('customer_dashboard'))

    mechanic = fetch_query("SELECT * FROM Mechanic WHERE Email = %s AND Password = %s", (email, password))
    if mechanic:
        session['user_type'] = 'mechanic'
        session['user_id'] = mechanic[0]['MechanicID']
        return redirect(url_for('mechanic_dashboard'))

    supplier = fetch_query("SELECT * FROM Supplier WHERE Email = %s AND Password = %s", (email, password))
    if supplier:
        session['user_type'] = 'supplier'
        session['user_id'] = supplier[0]['SupplierID']
        return redirect(url_for('supplier_dashboard'))

    return "Invalid credentials", 401


@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        logger.debug("Received signup POST request")
        name = request.form.get('name')
        email = request.form.get('email')
        phone = request.form.get('phone')
        password = request.form.get('password')
        user_type = request.form.get('user_type')

        logger.debug(
            f"Form Data - Name: {name}, Email: {email}, Phone: {phone}, Password: {password}, User Type: {user_type}")

        if not name or not password or not user_type or not email:
            flash("Name, Email, Password, and User Type are required.", "error")
            logger.warning("Missing required fields")
            return render_template('signup.html')

        try:
            if user_type == 'customer':
                logger.debug("Processing customer signup")
                # Check if email or vehicle_id already exists
                if fetch_query("SELECT * FROM Customer WHERE Email = %s", (email,)):
                    flash("Email already exists.", "error")
                    logger.warning(f"Email already exists: {email}")
                    return render_template('signup.html')

                vehicle_id = request.form.get('vehicle_id')
                manufacturer = request.form.get('manufacturer')
                model = request.form.get('model')
                fuel_type = request.form.get('fuel_type')
                year = request.form.get('year')


                logger.debug(
                    f"Customer Data - VehicleID: {vehicle_id}, Manufacturer: {manufacturer}, Model: {model}, Fuel Type: {fuel_type}, Year: {year}")


                if not all([vehicle_id, manufacturer, model, fuel_type, year]):
                    flash("All vehicle details are required for customers.", "error")
                    logger.warning("Missing vehicle details")
                    return render_template('signup.html')


                try:
                    datetime.strptime(year, '%Y-%m-%d')
                except ValueError:
                    flash("Invalid date format for Year of Purchase. Please use YYYY-MM-DD.", "error")
                    logger.warning(f"Invalid date format for year: {year}")
                    return render_template('signup.html')


                if fetch_query("SELECT * FROM Customer WHERE VehicleID = %s", (vehicle_id,)):
                    flash("Vehicle ID already exists.", "error")
                    logger.warning(f"Vehicle ID already exists: {vehicle_id}")
                    return render_template('signup.html')


                logger.debug("Inserting customer into database")
                execute_query(
                    "INSERT INTO Customer (Name, Email, Phone, Password, VehicleID) VALUES (%s, %s, %s, %s, %s)",
                    (name, email, phone, password, vehicle_id)
                )


                customer = fetch_query("SELECT CustomerID FROM Customer WHERE Email = %s", (email,))
                if not customer:
                    flash("Failed to create customer. Please try again.", "error")
                    logger.error("Failed to fetch newly created customer")
                    return render_template('signup.html')
                customer_id = customer[0]['CustomerID']


                logger.debug("Inserting vehicle details into database")
                execute_query(
                    "INSERT INTO Vehicle (VehicleID, CustomerID, Manufacturer, Model, FuelType, Year) VALUES (%s, %s, %s, %s, %s, %s)",
                    (vehicle_id, customer_id, manufacturer, model, fuel_type, year)
                )


                logger.debug("Generating recommendations for customer")
                execute_query("CALL GenerateRecommendations(%s)", (customer_id,))


                session['user_type'] = 'customer'
                session['user_id'] = customer_id
                flash("Signup successful! Welcome to your dashboard.", "success")
                logger.info(f"Customer signup successful: {customer_id}")
                return redirect(url_for('customer_dashboard'))

            elif user_type == 'supplier':
                logger.debug("Processing supplier signup")
                if fetch_query("SELECT * FROM Supplier WHERE Email = %s", (email,)):
                    flash("Email already exists.", "error")
                    logger.warning(f"Email already exists: {email}")
                    return render_template('signup.html')
                shop_name = request.form.get('shop_name')
                if not shop_name:
                    flash("Shop name is required for suppliers.", "error")
                    logger.warning("Missing shop name for supplier")
                    return render_template('signup.html')
                execute_query(
                    "INSERT INTO Supplier (Name, ShopName, Email, Password, Phone) VALUES (%s, %s, %s, %s, %s)",
                    (name, shop_name, email, password, phone)
                )

                supplier = fetch_query("SELECT SupplierID FROM Supplier WHERE Email = %s", (email,))
                if not supplier:
                    flash("Failed to create supplier. Please try again.", "error")
                    logger.error("Failed to fetch newly created supplier")
                    return render_template('signup.html')
                supplier_id = supplier[0]['SupplierID']
                session['user_type'] = 'supplier'
                session['user_id'] = supplier_id
                flash("Signup successful! Welcome to your dashboard.", "success")
                logger.info(f"Supplier signup successful: {supplier_id}")
                return redirect(url_for('supplier_dashboard'))

            flash("Invalid user type selected.", "error")
            logger.warning("Invalid user type selected")
            return render_template('signup.html')

        except Exception as e:
            flash(f"Error during signup: {str(e)}", "error")
            logger.error(f"Signup error: {str(e)}", exc_info=True)
            return render_template('signup.html')

    logger.debug("Rendering signup page (GET request)")
    return render_template('signup.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))


@app.route('/owner')
def owner_dashboard():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    customers = fetch_query("""
        SELECT c.*, IF(EXISTS(SELECT 1 FROM Appointment a WHERE a.CustomerID = c.CustomerID), 'Existing', 'New') AS CustomerStatus
        FROM Customer c
    """)
    mechanics = fetch_query("SELECT * FROM Mechanic")
    suppliers = fetch_query("SELECT * FROM Supplier")
    services = fetch_query("""
        SELECT s.*, m.Name AS MechanicName 
        FROM Service s 
        LEFT JOIN Mechanic m ON s.MechanicID = m.MechanicID 
        JOIN Appointment a ON s.ServiceID = a.ServiceID
    """)
    appointments = fetch_query("""
        SELECT a.*, c.Name AS CustomerName, s.Description AS ServiceDescription 
        FROM Appointment a 
        JOIN Customer c ON a.CustomerID = c.CustomerID 
        JOIN Service s ON a.ServiceID = s.ServiceID
    """)
    inventory = fetch_query("""
        SELECT i.*, s.ShopName 
        FROM Inventory i 
        LEFT JOIN Supplier s ON i.SupplierID = s.SupplierID
    """)
    # Fetch unassigned inventory items for the Suppliers tab
    unassigned_inventory = fetch_query("""
        SELECT * FROM Inventory WHERE SupplierID IS NULL
    """)
    inventory_requests = fetch_query("""
        SELECT ir.*, m.Name AS MechanicName 
        FROM InventoryRequest ir 
        JOIN Mechanic m ON ir.MechanicID = m.MechanicID
    """)
    invoices = fetch_query("""
        SELECT i.*, c.Name AS CustomerName, s.Description AS ServiceDescription 
        FROM Invoice i 
        JOIN Customer c ON i.CustomerID = c.CustomerID 
        JOIN Service s ON i.ServiceID = s.ServiceID
    """)
    return render_template('owner_dashboard.html', customers=customers, mechanics=mechanics, suppliers=suppliers,
                           services=services, appointments=appointments, inventory=inventory,
                           unassigned_inventory=unassigned_inventory, inventory_requests=inventory_requests,
                           invoices=invoices)


@app.route('/add_mechanic', methods=['POST'])
def add_mechanic():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    name = request.form['name']
    email = request.form['email']
    password = request.form['password']
    level = request.form['level']
    execute_query("INSERT INTO Mechanic (Name, Email, Password, Level, Experience) VALUES (%s, %s, %s, %s, 0)",
                  (name, email, password, level))
    return redirect(url_for('owner_dashboard'))


@app.route('/delete_mechanic', methods=['POST'])
def delete_mechanic():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    mechanic_id = request.form['mechanic_id']
    execute_query("DELETE FROM Mechanic WHERE MechanicID = %s", (mechanic_id,))
    return redirect(url_for('owner_dashboard'))


@app.route('/add_service', methods=['POST'])
def add_service():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    service_type = request.form['service_type']
    description = request.form['description']
    cost = request.form['cost']
    mechanic_id = request.form['mechanic_id']
    execute_query("INSERT INTO Service (ServiceType, Description, Cost, MechanicID) VALUES (%s, %s, %s, %s)",
                  (service_type, description, cost, mechanic_id))
    return redirect(url_for('owner_dashboard'))


@app.route('/assign_mechanic', methods=['POST'])
def assign_mechanic():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    service_id = request.form['service_id']
    mechanic_id = request.form['mechanic_id']
    execute_query("UPDATE Service SET MechanicID = %s WHERE ServiceID = %s", (mechanic_id, service_id))
    return redirect(url_for('owner_dashboard'))


@app.route('/update_service_status', methods=['POST'])
def update_service_status():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    service_id = request.form['service_id']
    status = request.form['status']
    execute_query("UPDATE Service SET Status = %s WHERE ServiceID = %s", (status, service_id))
    return redirect(url_for('owner_dashboard'))


@app.route('/update_appointment_status', methods=['POST'])
def update_appointment_status():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    appointment_id = request.form['appointment_id']
    status = request.form['status']
    execute_query("UPDATE Appointment SET Status = %s WHERE AppointmentID = %s", (status, appointment_id))
    return redirect(url_for('owner_dashboard'))


@app.route('/manage_inventory_request', methods=['POST'])
def manage_inventory_request():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    request_id = request.form['request_id']
    action = request.form['action']
    status = 'Approved' if action == 'approve' else 'Denied'
    execute_query("UPDATE InventoryRequest SET Status = %s WHERE RequestID = %s", (status, request_id))
    if action == 'approve':
        item_name = fetch_query("SELECT ItemName FROM InventoryRequest WHERE RequestID = %s", (request_id,))[0][
            'ItemName']
        requested_quantity = \
        fetch_query("SELECT Quantity FROM InventoryRequest WHERE RequestID = %s", (request_id,))[0]['Quantity']

        # Check if the item exists in the Inventory table
        inventory_item = fetch_query("SELECT InventoryID, Quantity FROM Inventory WHERE ItemName = %s LIMIT 1",
                                     (item_name,))

        if inventory_item:
            inventory_id = inventory_item[0]['InventoryID']
            available_quantity = inventory_item[0]['Quantity']

            if available_quantity >= requested_quantity:
                new_quantity = available_quantity - requested_quantity
                if new_quantity == 0:
                    execute_query("DELETE FROM Inventory WHERE InventoryID = %s", (inventory_id,))
                    flash(f"Item '{item_name}' request fulfilled and removed from inventory (quantity depleted).",
                          "success")
                else:
                    execute_query("UPDATE Inventory SET Quantity = %s WHERE InventoryID = %s",
                                  (new_quantity, inventory_id))
                    flash(f"Item '{item_name}' request fulfilled. Inventory updated (new quantity: {new_quantity}).",
                          "success")
            else:
                flash(
                    f"Insufficient quantity for '{item_name}' in inventory (available: {available_quantity}, requested: {requested_quantity}).",
                    "warning")
        else:
            flash(f"Item '{item_name}' not found in inventory. Please add it to inventory first.", "warning")
    return redirect(url_for('owner_dashboard'))


@app.route('/assign_inventory_to_supplier', methods=['POST'])
def assign_inventory_to_supplier():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    inventory_id = request.form['inventory_id']
    supplier_id = request.form['supplier_id']
    execute_query("UPDATE Inventory SET SupplierID = %s WHERE InventoryID = %s", (supplier_id, inventory_id))
    return redirect(url_for('owner_dashboard'))


@app.route('/update_payment_status', methods=['POST'])
def update_payment_status():
    if session.get('user_type') != 'owner':
        return redirect(url_for('index'))
    invoice_id = request.form['invoice_id']
    status = request.form['status']
    execute_query("UPDATE Invoice SET PaymentStatus = %s WHERE InvoiceID = %s", (status, invoice_id))
    return redirect(url_for('owner_dashboard'))


@app.route('/mechanic')
def mechanic_dashboard():
    if session.get('user_type') != 'mechanic':
        return redirect(url_for('index'))
    mechanic_id = session['user_id']
    services = fetch_query("SELECT * FROM Service WHERE MechanicID = %s", (mechanic_id,))
    inventory_requests = fetch_query("SELECT * FROM InventoryRequest WHERE MechanicID = %s", (mechanic_id,))
    return render_template('mechanic_dashboard.html', services=services, inventory_requests=inventory_requests)


@app.route('/update_service_status_mechanic', methods=['POST'])
def update_service_status_mechanic():
    if session.get('user_type') != 'mechanic':
        return redirect(url_for('index'))
    service_id = request.form['service_id']
    status = request.form['status']
    execute_query("UPDATE Service SET Status = %s WHERE ServiceID = %s", (status, service_id))
    return redirect(url_for('mechanic_dashboard'))


@app.route('/request_inventory', methods=['POST'])
def request_inventory():
    if session.get('user_type') != 'mechanic':
        return redirect(url_for('index'))
    mechanic_id = session['user_id']
    item_name = request.form['item_name']
    quantity = request.form['quantity']
    execute_query("INSERT INTO InventoryRequest (MechanicID, ItemName, Quantity) VALUES (%s, %s, %s)",
                  (mechanic_id, item_name, quantity))
    return redirect(url_for('mechanic_dashboard'))


@app.route('/customer')
def customer_dashboard():
    if session.get('user_type') != 'customer':
        return redirect(url_for('index'))
    customer_id = session['user_id']
    services = fetch_query("SELECT * FROM Service WHERE Status = 'Pending'")
    appointments = fetch_query(
        "SELECT a.*, s.Description FROM Appointment a JOIN Service s ON a.ServiceID = s.ServiceID WHERE a.CustomerID = %s",
        (customer_id,))
    invoices = fetch_query(
        "SELECT i.*, s.Description FROM Invoice i JOIN Service s ON i.ServiceID = s.ServiceID WHERE i.CustomerID = %s",
        (customer_id,))
    recommendations = fetch_query(
        "SELECT r.*, s.Description FROM Recommendation r JOIN Service s ON r.ServiceID = s.ServiceID WHERE r.CustomerID = %s",
        (customer_id,))
    return render_template('customer_dashboard.html', services=services, appointments=appointments, invoices=invoices,
                           recommendations=recommendations)


@app.route('/book_appointment', methods=['POST'])
def book_appointment():
    if session.get('user_type') != 'customer':
        return redirect(url_for('index'))
    customer_id = session['user_id']
    service_id = request.form['service_id']
    date = request.form['date']
    execute_query("INSERT INTO Appointment (CustomerID, ServiceID, Date) VALUES (%s, %s, %s)",
                  (customer_id, service_id, date))
    return redirect(url_for('customer_dashboard'))


@app.route('/pay_invoice', methods=['POST'])
def pay_invoice():
    if session.get('user_type') != 'customer':
        return redirect(url_for('index'))
    invoice_id = request.form['invoice_id']
    payment_method = request.form['payment_method']
    if payment_method == 'Online':
        execute_query("UPDATE Invoice SET PaymentStatus = 'Pending', PaymentMethod = %s WHERE InvoiceID = %s",
                      (payment_method, invoice_id))
    else:
        execute_query("UPDATE Invoice SET PaymentStatus = 'Paid', PaymentMethod = %s WHERE InvoiceID = %s",
                      (payment_method, invoice_id))
    return redirect(url_for('customer_dashboard'))


@app.route('/supplier')
def supplier_dashboard():
    if session.get('user_type') != 'supplier':
        return redirect(url_for('index'))
    supplier_id = session['user_id']
    inventory = fetch_query("SELECT * FROM Inventory WHERE SupplierID = %s", (supplier_id,))
    return render_template('supplier_dashboard.html', inventory=inventory)


@app.route('/add_inventory', methods=['POST'])
def add_inventory():
    if session.get('user_type') != 'supplier':
        return redirect(url_for('index'))
    supplier_id = session['user_id']
    item_name = request.form['item_name']
    quantity = request.form['quantity']
    price = request.form['price']
    execute_query("INSERT INTO Inventory (SupplierID, ItemName, Quantity, Price) VALUES (%s, %s, %s, %s)",
                  (supplier_id, item_name, quantity, price))
    return redirect(url_for('supplier_dashboard'))


if __name__ == '__main__':
    app.run(debug=True)