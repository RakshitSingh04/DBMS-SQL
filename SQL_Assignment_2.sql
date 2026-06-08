-- ==============================================================================
-- SQL Assignment 2
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. 5.1 Shipping Addresses for October 2023 Orders
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Customer Service might need to verify addresses for orders placed or completed 
-- in October 2023. This helps ensure shipments are delivered correctly and 
-- prevents address-related issues.
--
-- Fields to Retrieve:
-- - ORDER_ID
-- - PARTY_ID (Customer ID)
-- - CUSTOMER_NAME (or FIRST_NAME / LAST_NAME)
-- - STREET_ADDRESS
-- - CITY
-- - STATE_PROVINCE
-- - POSTAL_CODE
-- - COUNTRY_CODE
-- - ORDER_STATUS
-- - ORDER_DATE
-- ------------------------------------------------------------------------------

SELECT oh.order_id, orl.party_id, p.first_name, p.last_name, pa.address1, pa.city, pa.state_province_geo_id, pa.postal_code, oh.order_date, oh.status_id
FROM order_header oh
JOIN order_role orl ON orl.order_id = oh.order_id
JOIN person p ON p.party_id = orl.party_id AND orl.role_type_id = 'PLACING_CUSTOMER'
JOIN order_contact_mech ocm ON ocm.order_id = oh.order_id
JOIN postal_address pa ON pa.contact_mech_id = ocm.contact_mech_id
WHERE oh.order_date BETWEEN '2026-04-01' AND '2026-04-30';


-- ------------------------------------------------------------------------------
-- 2. 5.2 Orders from New York
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Companies often want region-specific analysis to plan local marketing, staffing, 
-- or promotions in certain areas—here, specifically, New York.
--
-- Fields to Retrieve:
-- - ORDER_ID
-- - CUSTOMER_NAME
-- - STREET_ADDRESS (or shipping address detail)
-- - CITY
-- - STATE_PROVINCE
-- - POSTAL_CODE
-- - TOTAL_AMOUNT
-- - ORDER_DATE
-- - ORDER_STATUS
-- ------------------------------------------------------------------------------

SELECT oh.order_id, orl.party_id, p.first_name, p.last_name, pa.address1, pa.city, pa.state_province_geo_id, pa.postal_code, oh.order_date, oh.status_id
FROM order_header oh
JOIN order_role orl ON orl.order_id = oh.order_id
JOIN person p ON p.party_id = orl.party_id AND orl.role_type_id = 'PLACING_CUSTOMER'
JOIN order_contact_mech ocm ON ocm.order_id = oh.order_id
JOIN postal_address pa ON pa.contact_mech_id = ocm.contact_mech_id
WHERE oh.order_date BETWEEN '2026-04-01' AND '2026-04-30';


-- ------------------------------------------------------------------------------
-- 3. 5.3 Top-Selling Product in New York
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Merchandising teams need to identify the best-selling product(s) in a specific 
-- region (New York) for targeted restocking or promotions.
--
-- Fields to Retrieve:
-- - PRODUCT_ID
-- - INTERNAL_NAME
-- - TOTAL_QUANTITY_SOLD
-- - CITY / STATE (within New York region)
-- - REVENUE (optionally, total sales amount)
-- ------------------------------------------------------------------------------

SELECT count(oi.quantity) AS Total_Quantity_Sold, oi.product_id, p.internal_name, pa.city, SUM(oi.quantity*oi.unit_price) AS total_revenue
FROM order_item oi 
JOIN product p ON p.product_id = oi.product_id
JOIN order_contact_mech ocm ON ocm.order_id = oi.order_id
JOIN postal_address pa ON pa.contact_mech_id = ocm.contact_mech_id AND pa.state_province_geo_id = 'NY'
GROUP BY oi.product_id;


-- ------------------------------------------------------------------------------
-- 4. 7.3 Store-Specific (Facility-Wise) Revenue
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Different physical or online stores (facilities) may have varying levels of 
-- performance. The business wants to compare revenue across facilities for sales 
-- planning and budgeting.
--
-- Fields to Retrieve:
-- - FACILITY_ID
-- - FACILITY_NAME
-- - TOTAL_ORDERS
-- - TOTAL_REVENUE
-- - DATE_RANGE
-- ------------------------------------------------------------------------------

SELECT f.facility_id, f.facility_name,
    COUNT(DISTINCT oh.order_id) AS total_orders,
    SUM(oh.grand_total) AS total_revenue
FROM order_header oh
JOIN order_item_ship_group oisg ON oisg.order_id = oh.order_id
JOIN facility f ON f.facility_id = oisg.facility_id
WHERE oh.status_id = 'order_completed'
GROUP BY f.facility_id;


-- ------------------------------------------------------------------------------
-- 5. 8.1 Lost and Damaged Inventory
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Warehouse managers need to track "shrinkage" such as lost or damaged inventory 
-- to reconcile physical vs. system counts.
--
-- Fields to Retrieve:
-- - INVENTORY_ITEM_ID
-- - PRODUCT_ID
-- - FACILITY_ID
-- - QUANTITY_LOST_OR_DAMAGED
-- - REASON_CODE (Lost, Damaged, Expired, etc.)
-- - TRANSACTION_DATE
-- ------------------------------------------------------------------------------

SELECT  ii.inventory_item_id,
        ii.product_id, 
        ii.facility_id,
        iiv.Reason_Enum_Id  AS reason_code,
        iiv.created_stamp AS transaction_date,
        SUM(iiv.quantity_on_hand_var) AS quantity_lost_orr_damaged
FROM inventory_item ii
JOIN inventory_item_variance iiv ON iiv.inventory_item_id = ii.inventory_item_id
WHERE iiv.Reason_enum_id IN ('VAR_LOST','VAR_DAMAGED')
GROUP BY ii.inventory_item_id;


-- ------------------------------------------------------------------------------
-- 6. 8.2 Low Stock or Out of Stock Items Report
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Avoiding out-of-stock situations is critical. This report flags items that have 
-- fallen below a certain reorder threshold or have zero available stock.
--
-- Fields to Retrieve:
-- - PRODUCT_ID
-- - PRODUCT_NAME
-- - FACILITY_ID
-- - QOH (Quantity on Hand)
-- - ATP (Available to Promise)
-- - REORDER_THRESHOLD
-- - DATE_CHECKED
-- ------------------------------------------------------------------------------

SELECT  p.PRODUCT_ID, 
        p.PRODUCT_NAME, 
        ii.FACILITY_ID, 
        ii.quantity_on_hand_total, 
        ii.available_to_promise_total,
        pf.minimum_stock AS reorder_threshold,
        ii.Last_Updated_Stamp AS date_checked
FROM product p
JOIN product_facility pf ON pf.product_id = p.product_id 
JOIN inventory_item ii ON ii.product_id = p.product_id
WHERE quantity_on_hand_total < pf.minimum_stock OR available_to_promise_total < pf.minimum_stock;


-- ------------------------------------------------------------------------------
-- 7. 8.3 Retrieve the Current Facility (Physical or Virtual) of Open Orders
-- ------------------------------------------------------------------------------
-- Business Problem:
-- The business wants to know where open orders are currently assigned, whether 
-- in a physical store or a virtual facility (e.g., a distribution center or 
-- online fulfillment location).
--
-- Fields to Retrieve:
-- - ORDER_ID
-- - ORDER_STATUS
-- - FACILITY_ID
-- - FACILITY_NAME
-- - FACILITY_TYPE_ID
-- ------------------------------------------------------------------------------

SELECT DISTINCT
       oh.ORDER_ID,
       oh.STATUS_ID AS ORDER_STATUS,
       f.FACILITY_ID,
       f.FACILITY_NAME,
       f.FACILITY_TYPE_ID
FROM ORDER_HEADER oh
JOIN ORDER_ITEM_SHIP_GROUP oisg
     ON oisg.ORDER_ID = oh.ORDER_ID
JOIN FACILITY f
     ON f.FACILITY_ID = oisg.FACILITY_ID
WHERE oh.STATUS_ID NOT IN ('ORDER_COMPLETED','ORDER_CANCELLED');


-- ------------------------------------------------------------------------------
-- 8. 8.4 Items Where QOH and ATP Differ
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Sometimes the Quantity on Hand (QOH) doesn't match the Available to Promise 
-- (ATP) due to pending orders, reservations, or data discrepancies. This needs 
-- review for accurate fulfillment planning.
--
-- Fields to Retrieve:
-- - PRODUCT_ID
-- - FACILITY_ID
-- - QOH (Quantity on Hand)
-- - ATP (Available to Promise)
-- - DIFFERENCE (QOH - ATP)
-- ------------------------------------------------------------------------------

SELECT  product_id, 
        facility_id, 
        quantity_on_hand_total, 
        available_to_promise_total, 
        (quantity_on_hand_total - available_to_promise_total) AS Difference
FROM inventory_item;


-- ------------------------------------------------------------------------------
-- 9. 8.5 Order Item Current Status Changed Date-Time
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Operations teams need to audit when an order item's status (e.g., from 
-- "Pending" to "Shipped") was last changed, for shipment tracking or dispute 
-- resolution.
--
-- Fields to Retrieve:
-- - ORDER_ID
-- - ORDER_ITEM_SEQ_ID
-- - CURRENT_STATUS_ID
-- - STATUS_CHANGE_DATETIME
-- - CHANGED_BY
-- ------------------------------------------------------------------------------

SELECT oi.order_id, 
        oi.order_item_seq_id, 
        oi.status_id, 
        os.status_datetime,
        os.status_user_login
FROM order_item oi
JOIN order_status os ON os.status_id = oi.status_id 
    AND os.ORDER_ITEM_SEQ_ID = oi.ORDER_ITEM_SEQ_ID
    AND os.STATUS_ID = oi.STATUS_ID
GROUP BY
    oi.order_id,
    oi.order_item_seq_id,
    oi.status_id;


-- ------------------------------------------------------------------------------
-- 10. 8.6 Total Orders by Sales Channel
-- ------------------------------------------------------------------------------
-- Business Problem:
-- Marketing and sales teams want to see how many orders come from each channel 
-- (e.g., web, mobile app, in-store POS, marketplace) to allocate resources 
-- effectively.
--
-- Fields to Retrieve:
-- - SALES_CHANNEL
-- - TOTAL_ORDERS
-- - TOTAL_REVENUE
-- ------------------------------------------------------------------------------

SELECT oh.sales_channel_enum_id AS SALES_CHANNEL, COUNT(DISTINCT oh.order_id) AS Total_Orders, SUM(oh.grand_total) AS Total_Revenue
FROM order_header oh
GROUP BY oh.sales_channel_enum_id;
