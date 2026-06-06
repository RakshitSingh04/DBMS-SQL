-- ==============================================================================
-- SQL Assignment 1
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. New Customers Acquired in June 2023
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- The marketing team ran a campaign in June 2023 and wants to see how many new 
-- customers signed up during that period.
--
-- Fields to Retrieve:  
-- - PARTY_ID  
-- - FIRST_NAME  
-- - LAST_NAME  
-- - EMAIL  
-- - PHONE  
-- - ENTRY_DATE
-- ------------------------------------------------------------------------------
SELECT 
    p.party_id, 
    p.first_name, 
    p.last_name, 
    cm.info_string AS email,
    py.created_date,
    tn.contact_number,
    CONCAT(p.first_name, ' ', p.last_name) AS full_name
FROM person p
JOIN party_contact_mech pcm ON pcm.party_id = p.party_id 
JOIN contact_mech cm ON cm.contact_mech_id = pcm.contact_mech_id
JOIN party py ON py.party_id = p.party_id 
JOIN telecom_number tn ON tn.contact_mech_id = cm.contact_mech_id
WHERE py.created_date BETWEEN '2025-06-01' AND '2026-06-30';


-- ------------------------------------------------------------------------------
-- 2. List All Active Physical Products
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- Merchandising teams often need a list of all physical products to manage 
-- logistics, warehousing, and shipping.
--
-- Fields to Retrieve:  
-- - PRODUCT_ID  
-- - PRODUCT_TYPE_ID  
-- - INTERNAL_NAME
-- ------------------------------------------------------------------------------
SELECT 
    product_id, 
    product_type_id, 
    internal_name
FROM product
JOIN product_type USING(product_type_id) 
WHERE is_physical = 'Y';


-- ------------------------------------------------------------------------------
-- 3. Products Missing NetSuite ID
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- A product cannot sync to NetSuite unless it has a valid NetSuite ID. The OMS 
-- needs a list of all products that still need to be created or updated in NetSuite.
--
-- Fields to Retrieve:  
-- - PRODUCT_ID  
-- - INTERNAL_NAME  
-- - PRODUCT_TYPE_ID  
-- - NETSUITE_ID (or similar field indicating the NetSuite ID; may be NULL or empty)
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id, 
    p.product_type_id, 
    p.internal_name, 
    gi.id_value AS NetSuite_ID
FROM product p
LEFT JOIN good_identification gi ON gi.product_id = p.product_id
    AND gi.good_identification_type_id = 'ERP_ID'
WHERE gi.id_value IS NULL OR gi.id_value = '';


-- ------------------------------------------------------------------------------
-- 4. Product IDs Across Systems
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- To sync an order or product across multiple systems (e.g., Shopify, HotWax, 
-- ERP/NetSuite), the OMS needs to know each system’s unique identifier for that 
-- product. This query retrieves the Shopify ID, HotWax ID, and ERP ID (NetSuite ID) 
-- for all products.
--
-- Fields to Retrieve:  
-- - PRODUCT_ID (internal OMS ID)  
-- - SHOPIFY_ID  
-- - HOTWAX_ID  
-- - ERP_ID or NETSUITE_ID (depending on naming)
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id AS Hotwax_ID, 
    gi_erp.id_value AS NetSuite_ID, 
    gi_shopify.id_value AS Shopify_ID
FROM product p
LEFT JOIN good_identification gi_erp ON gi_erp.product_id = p.product_id
    AND gi_erp.good_identification_type_id = 'ERP_ID'
LEFT JOIN good_identification gi_shopify ON gi_shopify.product_id = p.product_id
    AND gi_shopify.good_identification_type_id = 'SHOPIFY_PROD_ID';


-- ------------------------------------------------------------------------------
-- 5. Completed Orders in August 2023
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- After running similar reports for a previous month, you now need all completed 
-- orders in August 2023 for analysis.
--
-- Fields to Retrieve:  
-- - PRODUCT_ID  
-- - PRODUCT_TYPE_ID  
-- - PRODUCT_STORE_ID  
-- - TOTAL_QUANTITY  
-- - INTERNAL_NAME  
-- - FACILITY_ID  
-- - EXTERNAL_ID  
-- - FACILITY_TYPE_ID  
-- - ORDER_HISTORY_ID  
-- - ORDER_ID  
-- - ORDER_ITEM_SEQ_ID  
-- - SHIP_GROUP_SEQ_ID
-- ------------------------------------------------------------------------------
SELECT 
    oh.order_id, 
    oi.order_item_seq_id, 
    oisp.ship_group_seq_id, 
    oisp.facility_id, 
    oh.product_store_id, 
    oh.external_id, 
    oi.product_id, 
    p.product_type_id, 
    p.internal_name 
FROM order_header oh
JOIN order_item oi ON oi.order_id = oh.order_id
JOIN product p ON p.product_id = oi.product_id
JOIN order_item_ship_group oisp ON oisp.order_id = oi.order_id
JOIN facility f ON f.facility_id = oisp.facility_id
WHERE oh.ORDER_DATE BETWEEN '2026-01-01' AND '2026-05-31'
  AND oh.STATUS_ID = 'ORDER_COMPLETED';


-- ------------------------------------------------------------------------------
-- 7. Newly Created Sales Orders and Payment Methods
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- Finance teams need to see new orders and their payment methods for 
-- reconciliation and fraud checks.
--
-- Fields to Retrieve:  
-- - ORDER_ID
-- - TOTAL_AMOUNT
-- - PAYMENT_METHOD  
-- - Shopify Order ID (if applicable)
-- ------------------------------------------------------------------------------
SELECT 
    oh.order_id, 
    oh.grand_total AS total_amount, 
    opp.payment_method_type_id AS payment_method, 
    oh.external_id AS Shopify_order_id
FROM order_header oh
JOIN order_payment_preference opp ON opp.order_id = oh.order_id;


-- ------------------------------------------------------------------------------
-- 8. Payment Captured but Not Shipped
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- Finance teams want to ensure revenue is recognized properly. If payment is 
-- captured but no shipment has occurred, it warrants further review.
--
-- Fields to Retrieve:  
-- - ORDER_ID  
-- - ORDER_STATUS  
-- - PAYMENT_STATUS  
-- - SHIPMENT_STATUS
-- ------------------------------------------------------------------------------
SELECT 
    oh.order_id, 
    oh.status_id AS order_status, 
    opp.status_id AS payment_status, 
    s.status_id AS shipment_status
FROM order_header oh 
JOIN order_payment_preference opp ON opp.order_id = oh.order_id 
    AND opp.status_id = 'payment_recieved'
JOIN shipment s ON s.primary_order_id = oh.order_id 
    AND s.status_id != 'shipment_shipped';


-- ------------------------------------------------------------------------------
-- 9. Orders Completed Hourly
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- Operations teams may want to see how orders complete across the day to 
-- schedule staffing.
--
-- Fields to Retrieve:  
-- - TOTAL ORDERS  
-- - HOUR
-- ------------------------------------------------------------------------------
SELECT 
    HOUR(status_datetime) AS HOUR,
    COUNT(*) AS Total_Orders
FROM order_status
WHERE status_id = 'order_completed'
  AND DATE(status_datetime) = '2026-05-19'
GROUP BY HOUR;


-- ------------------------------------------------------------------------------
-- 10. BOPIS Orders Revenue (Last Year)
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- BOPIS (Buy Online, Pickup In Store) is a key retail strategy. Finance wants to 
-- know the revenue from BOPIS orders for the previous year.
--
-- Fields to Retrieve:  
-- - TOTAL ORDERS  
-- - TOTAL REVENUE
-- ------------------------------------------------------------------------------
SELECT
    COUNT(DISTINCT oh.order_id) AS total_orders,
    SUM(oh.grand_total) AS total_revenue
FROM order_header oh
JOIN order_item_ship_group oisg ON oisg.order_id = oh.order_id
WHERE oisg.shipment_method_type_id = 'STORE_PICKUP'
  AND oh.status_id = 'ORDER_COMPLETED'
  AND oh.order_date >= '2025-01-01'
  AND oh.order_date < '2026-01-01';


-- ------------------------------------------------------------------------------
-- 11. Canceled Orders (Last Month)
-- ------------------------------------------------------------------------------
-- Business Problem:  
-- The merchandising team needs to know how many orders were canceled in the 
-- previous month and their reasons.
--
-- Fields to Retrieve:  
-- - TOTAL ORDERS  
-- - CANCELATION REASON
-- ------------------------------------------------------------------------------
SELECT
    COUNT(DISTINCT oh.order_id) AS total_orders,
    os.change_reason AS cancellation_reason
FROM order_header oh
JOIN order_status os ON os.order_id = oh.order_id
WHERE oh.status_id = 'ORDER_CANCELLED'
  AND oh.order_date >= DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m-01')
  AND oh.order_date < DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
GROUP BY os.change_reason;


-- ------------------------------------------------------------------------------
-- 12. Product Threshold Value
-- ------------------------------------------------------------------------------
-- Business Problem:
-- The retailer has set a threshild value for products that are sold online, in 
-- order to avoid over selling. 
--
-- Fields to Retrieve:
-- - PRODUCT ID
-- - THRESHOLD
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id, 
    pf.minimum_stock AS Threshold
FROM product p
JOIN product_facility pf ON pf.product_id = p.product_id;
