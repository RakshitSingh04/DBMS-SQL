select p.party_id, p.first_name, p.last_name, cm.info_string AS email,py.created_date,tn.contact_number,
CONCAT(p.first_name," " ,p.last_name)

from person p
JOIN party_contact_mech pcm ON pcm.party_id = p.party_id 
JOIN contact_mech cm ON cm.contact_mech_id = pcm.contact_mech_id
JOIN party py ON py.party_id = p.party_id 
JOIN telecom_number tn ON tn.contact_mech_id = cm.contact_mech_id

WHERE py.created_date BETWEEN '2025-06-01' AND '2026-06-30'