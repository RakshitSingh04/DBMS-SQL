-- ==============================================================================
-- SQL Assignment 3
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Completed Sales Orders (Physical Items)
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Merchants need to track only physical items (requiring shipping and fulfillment) 
-- for logistics and shipping-cost analysis.
--
-- Fields to Retrieve:
-- - ORDER_ID
-- - ORDER_ITEM_SEQ_ID
-- - PRODUCT_ID
-- - PRODUCT_TYPE_ID
-- - SALES_CHANNEL_ENUM_ID
-- - ORDER_DATE
-- - ENTRY_DATE
-- - STATUS_ID
-- - STATUS_DATETIME
-- - ORDER_TYPE_ID
-- - PRODUCT_STORE_ID
-- ------------------------------------------------------------------------------

SELECT  oh.ORDER_ID,
        oi.ORDER_ITEM_SEQ_ID,
        oi.PRODUCT_ID,
        p.PRODUCT_TYPE_ID,
        oh.SALES_CHANNEL_ENUM_ID,
        oh.ORDER_DATE,
        oh.ENTRY_DATE,
        oh.STATUS_ID,
        os.STATUS_DATETIME,
        oh.ORDER_TYPE_ID,
        oh.PRODUCT_STORE_ID
FROM order_header oh
JOIN order_item oi ON oi.order_id = oh.order_id
JOIN order_status os ON os.order_id = oh.order_id
JOIN product p ON p.product_id = oi.product_id
JOIN product_type pt ON pt.product_type_id = p.PRODUCT_TYPE_ID
WHERE pt.IS_PHYSICAL = 'y';


-- ------------------------------------------------------------------------------
-- 2. Completed Return Items
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Customer service and finance often need insights into returned items to manage 
-- refunds, replacements, and inventory restocking.
--
-- Fields to Retrieve:
-- - RETURN_ID
-- - ORDER_ID
-- - PRODUCT_STORE_ID
-- - STATUS_DATETIME
-- - ORDER_NAME
-- - FROM_PARTY_ID
-- - RETURN_DATE
-- - ENTRY_DATE
-- - RETURN_CHANNEL_ENUM_ID
-- ------------------------------------------------------------------------------

SELECT  rh.RETURN_ID,
        ri.ORDER_ID,
        oh.PRODUCT_STORE_ID,
        oh.ORDER_NAME,
        rh.FROM_PARTY_ID,
        rh.RETURN_DATE,
        rh.ENTRY_DATE,
        rh.RETURN_CHANNEL_ENUM_ID
FROM return_header rh
JOIN return_item ri ON ri.return_id = rh.return_id
JOIN order_header oh ON oh.order_id = ri.order_id;


-- ------------------------------------------------------------------------------
-- 3. Single-Return Orders (Last Month)
-- ------------------------------------------------------------------------------
-- Business Problem:
-- The mechandising team needs a list of orders that only have one return.
--
-- Fields to Retrieve:
-- - PARTY_ID
-- - FIRST_NAME
-- ------------------------------------------------------------------------------

SELECT  p.PARTY_ID,
        p.FIRST_NAME,
        ri.order_id,
        COUNT(DISTINCT rh.return_id) AS total_returns
FROM return_header rh 
JOIN return_item ri ON ri.return_id = rh.return_id
JOIN person p ON p.party_id = rh.from_party_id
GROUP BY
        p.party_id,
        p.first_name,
        ri.order_id
HAVING COUNT(DISTINCT rh.return_id) = 1;


-- ------------------------------------------------------------------------------
-- 4. Returns and Appeasements 
-- ------------------------------------------------------------------------------
-- Business Problem:
-- The retailer needs the total amount of items, were returned as well as how many 
-- appeasements were issued.
--
-- Fields to Retrieve:
-- - TOTAL RETURNS
-- - RETURN $ TOTAL
-- - TOTAL APPEASEMENTS
-- - APPEASEMENTS $ TOTAL
-- ------------------------------------------------------------------------------

SELECT
    (SELECT SUM(return_quantity)
     FROM return_item) AS TOTAL_RETURNS,

    (SELECT SUM(return_quantity * return_price)
     FROM return_item) AS RETURN_DOLLAR_TOTAL,

    (SELECT COUNT(*)
     FROM return_adjustment
     WHERE return_adjustment_type_id = 'APPEASEMENT') AS TOTAL_APPEASEMENTS,

    (SELECT SUM(amount)
     FROM return_adjustment
     WHERE return_adjustment_type_id = 'APPEASEMENT') AS APPEASEMENTS_DOLLAR_TOTAL;


-- ------------------------------------------------------------------------------
-- 5. Detailed Return Information
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Certain teams need granular return data (reason, date, refund amount) for analyzing 
-- return rates, identifying recurring issues, or updating policies.
--
-- Fields to Retrieve:
-- - RETURN_ID
-- - ENTRY_DATE
-- - RETURN_ADJUSTMENT_TYPE_ID (refund type, store credit, etc.)
-- - AMOUNT
-- - COMMENTS
-- - ORDER_ID
-- - ORDER_DATE
-- - RETURN_DATE
-- - PRODUCT_STORE_ID
-- ------------------------------------------------------------------------------

SELECT  rh.RETURN_ID,
        rh.ENTRY_DATE,
        ra.RETURN_ADJUSTMENT_TYPE_ID,
        ra.AMOUNT,
        ra.COMMENTS,
        ri.ORDER_ID,
        oh.ORDER_DATE,
        oh.PRODUCT_STORE_ID
FROM return_header rh
JOIN return_adjustment ra ON ra.return_id = rh.return_id
JOIN return_item ri ON ri.return_id = ra.return_id
JOIN order_header oh ON oh.order_id = ri.order_id;


-- ------------------------------------------------------------------------------
-- 6. Orders with Multiple Returns
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Analyzing orders with multiple returns can identify potential fraud, chronic 
-- issues with certain items, or inconsistent shipping processes.
--
-- Fields to Retrieve:
-- - ORDER_ID
-- - RETURN_ID
-- - RETURN_DATE
-- - RETURN_REASON
-- - RETURN_QUANTITY
-- ------------------------------------------------------------------------------

SELECT  ri.ORDER_ID, 
        sum(ri.RETURN_QUANTITY)
FROM return_header rh 
JOIN return_item ri on rh.RETURN_ID = ri.RETURN_ID and ri.STATUS_ID = 'RETURN_COMPLETED'
GROUP BY ri.ORDER_ID
HAVING sum(ri.RETURN_QUANTITY) > 1;


-- ------------------------------------------------------------------------------
-- 7. Store with Most One-Day Shipped Orders (Last Month)
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Identify which facility (store) handled the highest volume of “one-day shipping” 
-- orders in the previous month, useful for operational benchmarking.
--
-- Fields to Retrieve:
-- - FACILITY_ID
-- - FACILITY_NAME
-- - TOTAL_ONE_DAY_SHIP_ORDERS
-- - REPORTING_PERIOD
-- ------------------------------------------------------------------------------

SELECT
    f.facility_id,
    f.facility_name,
    COUNT(DISTINCT oh.order_id) AS total_one_day_ship_orders,
    DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m') AS reporting_period
FROM order_header oh
JOIN order_item_ship_group oisg
    ON oh.order_id = oisg.order_id
JOIN facility f
    ON oisg.facility_id = f.facility_id
JOIN order_status os
    ON oh.order_id = os.order_id
WHERE os.status_id = 'ORDER_SHIPPED'
    AND oh.order_date >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01')
    AND oh.order_date < DATE_FORMAT(CURDATE(), '%Y-%m-01')
    AND TIMESTAMPDIFF(HOUR, oh.order_date, os.status_datetime) <= 24
GROUP BY
    f.facility_id,
    f.facility_name
ORDER BY total_one_day_ship_orders DESC
LIMIT 1;


-- ------------------------------------------------------------------------------
-- 8. List of Warehouse Pickers
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Warehouse managers need a list of employees responsible for picking and packing 
-- orders to manage shifts, productivity, and training needs.
--
-- Fields to Retrieve:
-- - PARTY_ID (or Employee ID)
-- - NAME (First/Last)
-- - ROLE_TYPE_ID (e.g., “WAREHOUSE_PICKER”)
-- - FACILITY_ID (assigned warehouse)
-- - STATUS (active or inactive employee)
-- ------------------------------------------------------------------------------

SELECT  p.PARTY_ID,
        p.FIRST_NAME,
        ROLE_TYPE_ID,
        pl.FACILITY_ID,
        CASE
        WHEN pr.THRU_DATE IS NULL
             OR pr.THRU_DATE > CURRENT_DATE
        THEN 'ACTIVE'
        ELSE 'INACTIVE'
    END AS STATUS
from person p
JOIN picklist_role pr ON pr.party_id = p.party_id
JOIN picklist pl ON pl.picklist_id = pr.picklist_id
WHERE pr.THRU_DATE IS NULL OR pr.THRU_DATE > CURRENT_DATE;


-- ------------------------------------------------------------------------------
-- 9. Total Facilities That Sell the Product
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Retailers want to see how many (and which) facilities (stores, warehouses, virtual 
-- sites) currently offer a product for sale.
--
-- Fields to Retrieve:
-- - PRODUCT_ID
-- - PRODUCT_NAME (or INTERNAL_NAME)
-- - FACILITY_COUNT (number of facilities selling the product)
-- - (Optionally) a list of FACILITY_IDs if more detail is needed
-- ------------------------------------------------------------------------------

SELECT  p.product_id,
        p.product_name,
        COUNT(DISTINCT pf.facility_id) AS facility_count
FROM product p
JOIN product_facility pf
    ON pf.product_id = p.product_id
JOIN facility f
    ON f.facility_id = pf.facility_id
WHERE f.facility_type_id = 'RETAIL_STORE'
GROUP BY
        p.product_id,
        p.product_name;


-- ------------------------------------------------------------------------------
-- 10. Total Items in Various Virtual Facilities
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Retailers need to study the relation of inventory levels of products to the type 
-- of facility it's stored at. Retrieve all inventory levels for products at locations 
-- and include the facility type Id. Do not retrieve facilities that are of type Virtual.
--
-- Fields to Retrieve:
-- - PRODUCT_ID
-- - FACILITY_ID
-- - FACILITY_TYPE_ID
-- - QOH (Quantity on Hand)
-- - ATP (Available to Promise)
-- ------------------------------------------------------------------------------

SELECT  ii.PRODUCT_ID,
        f.FACILITY_ID,
        f.FACILITY_TYPE_ID,
        ii.QUANTITY_ON_HAND_TOTAL AS QOH,
        ii.AVAILABLE_TO_PROMISE AS ATP  
from inventory_item ii 
JOIN facility f ON f.facility_id = ii.facility_id
WHERE f.facility_type_id <> 'VIRTUAL_FACILITY';


-- ------------------------------------------------------------------------------
-- 11. Transfer Orders Without Inventory Reservation
-- ------------------------------------------------------------------------------
-- Business Problem:
-- When transferring stock between facilities, the system should reserve inventory. 
-- If it isn’t reserved, the transfer may fail or oversell.
--
-- Fields to Retrieve:
-- - TRANSFER_ORDER_ID
-- - FROM_FACILITY_ID
-- - TO_FACILITY_ID
-- - PRODUCT_ID
-- - REQUESTED_QUANTITY
-- - RESERVED_QUANTITY
-- - TRANSFER_DATE
-- - STATUS
-- ------------------------------------------------------------------------------

SELECT  oh.order_id AS TRANSFER_ORDER_ID,
        s.origin_facility_id AS FROM_FACILITY_ID,
        s.destination_facility_id AS TO_FACILITY_ID,
        oi.product_id,
        oi.quantity AS REQUESTED_QUANTITY,
        COALESCE(oisgir.quantity, 0) AS RESERVED_QUANTITY,
        oh.order_date AS TRANSFER_DATE,
        oh.status_id AS STATUS
FROM order_header oh
JOIN shipment s
    ON s.primary_order_id = oh.order_id
JOIN order_item oi
    ON oi.order_id = oh.order_id
LEFT JOIN order_item_ship_grp_inv_res oisgir
    ON oisgir.order_id = oi.order_id
   AND oisgir.order_item_seq_id = oi.order_item_seq_id
WHERE oh.order_type_id = 'TRANSFER_ORDER'
  AND (
        oisgir.quantity IS NULL
        OR oisgir.quantity < oi.quantity
      );


-- ------------------------------------------------------------------------------
-- 12. Orders Without Picklist
-- ------------------------------------------------------------------------------
-- Business Problem:
-- A picklist is necessary for warehouse staff to gather items. Orders missing a 
-- picklist might be delayed and need attention.
--
-- Fields to Retrieve:
-- - ORDER_ID
-- - ORDER_DATE
-- - ORDER_STATUS
-- - FACILITY_ID
-- - DURATION (How long has the order been assigned at the facility)
-- ------------------------------------------------------------------------------

SELECT  oh.order_id,
        oh.order_date,
        oh.status_id AS order_status,
        oisg.facility_id,
        TIMESTAMPDIFF(DAY, oh.order_date, CURRENT_TIMESTAMP) AS duration_days
FROM order_header oh
JOIN order_item_ship_group oisg ON oisg.order_id = oh.order_id
LEFT JOIN picklist_item pli ON pli.order_id = oh.order_id
WHERE pli.picklist_Bin_id IS NULL AND oh.status_id NOT IN ('ORDER_COMPLETED', 'ORDER_CANCELLED');
