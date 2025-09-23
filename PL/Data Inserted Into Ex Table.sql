--Header Data Insert

insert into XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX(SUPPLIER_CODE,SUPPLIER_SITE_CODE,ITEM_CODE,BATCH_ID,ORG_ID,REQUEST_ID,ATTRIBUTE5,ATTRIBUTE4)
SELECT PV.segment1 AS supplier_code,
       stg.NEW_SUPPLIER_SITE AS supplier_site_code,
       MSI.segment1 AS item_code,
       org.ORGANIZATION_ID BATCH_ID,
       org.ORGANIZATION_ID ORG_ID,
       org.ORGANIZATION_ID || 5111001,
       qssrcv.CRITERIA_ID,
       PVS.VENDOR_SITE_CODE
  FROM apps.QA_SL_SP_RCV_CRITERIA qssrcv,
       apps.MTL_SYSTEM_ITEMS MSI,
       apps.ap_suppliers PV,
       apps.ap_supplier_sites_all PVS,
       apps.org_organization_definitions org,
       XXMSSLBKP.XXMSSLBKP_QA_SKIPLOT_SMPL_STG stg
 WHERE     1 = 1
       -- and PV.vendor_name='MOTHERSON SUMI ELECTRIC WIRES'
       -- and MSI.segment1='01210514'
       -- and PVS.VENDOR_SITE_CODE='BANGALOR_DTA_RM'
       AND qssrcv.vendor_id = PV.vendor_id
       AND qssrcv.VENDOR_SITE_ID = PVS.VENDOR_SITE_ID
       AND PVS.ORG_ID = org.OPERATING_UNIT
       AND qssrcv.ITEM_ID = MSI.INVENTORY_ITEM_ID
       AND qssrcv.ORGANIZATION_ID = MSI.ORGANIZATION_ID
       AND PV.end_date_active IS NULL
       -- AND qssrcv.ORGANIZATION_ID=104
       AND qssrcv.ORGANIZATION_ID = org.organization_id
       --AND mtlp.organization_code='P40'
       AND org.organization_code = 'C03'
       AND TRIM (stg.SUPPLIER) = PV.vendor_name
       AND TRIM (stg.CODE) = MSI.segment1
       AND TRIM (stg.EXISTING_SUPPLIER_SITE) = PVS.VENDOR_SITE_CODE
       AND NOT EXISTS
                  (SELECT 1
                     FROM apps.qa_sl_sp_rcv_criteria a,
                          apps.ap_suppliers aps,
                          apps.ap_supplier_sites_all apssa,
                          apps.mtl_system_items_b msib
                    WHERE     a.organization_id = org.organization_id
                          AND a.vendor_id = aps.vendor_id
                          AND a.vendor_site_id = apssa.vendor_site_id
                          AND a.item_id = msib.inventory_item_id
                          AND a.organization_id = msib.organization_id
                          AND aps.segment1 = PV.segment1
                          AND apssa.VENDOR_SITE_CODE = STG.NEW_SUPPLIER_SITE --PVS.VENDOR_SITE_CODE
                          AND apssa.ORG_ID = org.OPERATING_UNIT
                          AND msib.segment1 = MSI.segment1)
--       AND NOT EXISTS
--                  (SELECT 1
--                     FROM apps.qa_sl_sp_rcv_criteria a,
--                          apps.ap_suppliers aps,
--                          apps.ap_supplier_sites_all apssa,
--                          apps.mtl_system_items_b msib
--                    WHERE     aps.vendor_id = apssa.vendor_id
--                          AND a.vendor_id = aps.vendor_id
--                          AND a.vendor_site_id = apssa.vendor_site_id
--                          AND msib.inventory_item_id = a.item_id
--                          AND msib.organization_id = a.organization_id
--                          AND aps.segment1 = PV.segment1
--                          and apssa.VENDOR_SITE_CODE=PVS.VENDOR_SITE_CODE
--                          and apssa.ORG_ID=mtlp.OPERATING_UNIT
--                          AND msib.segment1 = MSI.segment1
--                          AND msib.organization_id = mtlp.organization_id)
--       and  exists (SELECT 1
--                  FROM apps.ap_suppliers asa
--                 WHERE 1 = 1
--                   AND asa.segment1 =
--                                  PV.segment1
--                                             --UPPER (lr_spec.supplier_number)
--                   AND EXISTS (
--                          SELECT 1
--                            FROM apps.ap_supplier_sites_all apsa
--                           WHERE apsa.org_id = mtlp.operating_unit
--                            and apsa.VENDOR_SITE_CODE=PVS.VENDOR_SITE_CODE
--                             AND apsa.vendor_id = asa.vendor_id)
----                   AND (   asa.end_date_active IS NULL
----                        OR TRUNC (asa.end_date_active) >= TRUNC (SYSDATE)
----                       ) 
--                       ) 
--          AND EXISTS (
--          SELECT 1
--            FROM apps.mtl_system_items_b mtl
--           WHERE mtl.inventory_item_id = MSI.INVENTORY_ITEM_ID
--             AND mtl.organization_id = mtlp.ORGANIZATION_ID
--             AND mtl.inventory_item_status_code = 'Active')                                 
--       AND NOT EXISTS
--                  (SELECT 1
--                     FROM XXMSSL.XXMSSL_QA_SKIPLOT_SMPL_I_STG_T STG
--                    WHERE     STG.SUPPLIER_CODE = PV.VENDOR_NAME
--                          AND STG.SUPPLIER_SITE_CODE=PVS.VENDOR_SITE_CODE
--                          AND STG.ITEM_CODE = MSI.segment1) 
                          
                          
-------------------
DECLARE
   lv_item_cnt        NUMBER:=0;
   lv_sup_cnt         NUMBER:=0;
   lv_RECORD_STATUS   NUMBER;
   lv_ERR_MSG         VARCHAR2 (4000);

   CURSOR c1
   IS
      SELECT *
        FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX STG 
        where RECORD_STATUS is null
        ;
BEGIN
   FOR r1 IN c1
   LOOP
      lv_RECORD_STATUS := 0;
      lv_ERR_MSG := NULL;

      BEGIN
         SELECT count(1)
           INTO lv_item_cnt
           FROM apps.mtl_system_items_b mtl
          WHERE     mtl.SEGMENT1 = r1.ITEM_CODE
                AND mtl.organization_id = r1.ORG_ID
                AND mtl.inventory_item_status_code = 'Active';

         IF lv_item_cnt = 0
         THEN
            lv_RECORD_STATUS := 2;
            lv_ERR_MSG := 'Item is not available';
         END IF;
      END;

      IF r1.SUPPLIER_CODE IS NOT NULL
      THEN
         BEGIN
            SELECT count(1) into lv_sup_cnt
              FROM apps.ap_suppliers asa,
                   Apps.ap_supplier_sites_all apsa,
                   apps.org_organization_definitions ORG
             WHERE     1 = 1
                   AND asa.segment1 = r1.SUPPLIER_CODE
                   AND apsa.vendor_id = asa.vendor_id
                   AND apsa.VENDOR_SITE_CODE = r1.SUPPLIER_SITE_CODE
                   AND apsa.org_id = ORG.operating_unit
                   AND ORG.ORGANIZATION_ID = r1.ORG_ID
                   AND (asa.end_date_active IS NULL
                        OR TRUNC (asa.end_date_active) >= TRUNC (SYSDATE));

            IF lv_sup_cnt = 0
            THEN
               lv_RECORD_STATUS := 2;
               lv_ERR_MSG := lv_ERR_MSG || ',' || 'Supplier is not available';
            END IF;
         END;
      END IF;

      IF lv_RECORD_STATUS = 2 AND lv_ERR_MSG IS NOT NULL
      THEN
         UPDATE XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX ex
            SET ex.RECORD_STATUS = 'ERR', ex.ERROR_MESSAGE = lv_ERR_MSG
          WHERE     ex.SUPPLIER_CODE = r1.SUPPLIER_CODE
                AND ex.SUPPLIER_SITE_CODE = r1.SUPPLIER_SITE_CODE
                AND ex.ITEM_CODE = r1.ITEM_CODE
                AND ex.ORG_ID = r1.ORG_ID;

         COMMIT;
      END IF;
   END LOOP;
END;
-------------------

--insert into XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX(SUPPLIER_CODE,ITEM_CODE,SKIP_LOT_PROCESS,EFFECTIVE_DATE,EFFECTIVE_TO,BATCH_ID,ORG_ID,REQUEST_ID) 
insert into XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX(SUPPLIER_CODE,ITEM_CODE,SKIP_LOT_PROCESS,EFFECTIVE_DATE,EFFECTIVE_TO,BATCH_ID,ORG_ID,REQUEST_ID) 
 SELECT t1.*
  FROM (SELECT DISTINCT
               PV.segment1 || '_SITE_' || stg.SUPPLIER_SITE_CODE
                  AS supplier_code,
               msi.segment1 AS item_code,
               qslp.process_code,
               qsla.effective_from,
               qsla.effective_to,
               mtlp.organization_id batch_id,
               mtlp.organization_id org_id,
               mtlp.ORGANIZATION_ID || 5111001
          FROM apps.qa_sl_sp_rcv_criteria qssrcv,
               apps.mtl_system_items msi,
               apps.ap_suppliers pv,
               apps.ap_supplier_sites_all pvs,
               apps.qa_skiplot_association qsla,
               apps.qa_skiplot_processes qslp,
               (select * from XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX st where st.RECORD_STATUS IS NULL) stg,
               apps.mtl_parameters mtlp
         WHERE     qssrcv.item_id = msi.inventory_item_id
               AND qssrcv.organization_id = msi.organization_id
               AND qssrcv.vendor_id = pv.vendor_id
               AND qssrcv.vendor_site_id = pvs.vendor_site_id
               AND qssrcv.organization_id = 185
               AND qssrcv.criteria_id = qsla.criteria_id
               AND qsla.process_id = qslp.process_id
               --and msi.segment1='1003001603'
               AND qssrcv.criteria_id=to_number(stg.ATTRIBUTE5)
               AND PV.segment1 = stg.supplier_code
               AND pvs.vendor_site_code =stg.ATTRIBUTE4
               AND msi.segment1 = stg.item_code
               AND mtlp.organization_id = stg.org_id) t1
 WHERE EXISTS
          (SELECT 1
             FROM apps.qa_skiplot_processes qpl
            WHERE     qpl.process_code = t1.process_code
                  AND qpl.organization_id = t1.org_id) 
             
             
            

--------------------

INSERT INTO XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX (SUPPLIER_CODE,
                                            ITEM_CODE,
                                            SAMPLING_PLAN,
                                            COLLECTION_PLAN,
                                            EFFECTIVE_FROM,
                                            EFFECTIVE_TO,
                                            BATCH_ID,
                                            ORG_ID,REQUEST_ID)
SELECT T1.* FROM(
SELECT DISTINCT PV.segment1||'_SITE_'||stg.SUPPLIER_SITE_CODE AS supplier_code,
                     MSI.segment1 AS item_code,
                     QSPP.SAMPLING_PLAN_CODE SAMPLING_PLAN_CODE,
                     QP.NAME COLLECTION_PLAN_NAME,
                     QSPA.EFFECTIVE_FROM SP_EFFECTIVE_FROM,
                     QSPA.EFFECTIVE_TO SP_EFFECTIVE_TO,
                    mtlp.ORGANIZATION_ID BATCH_ID,
                    mtlp.ORGANIZATION_ID ORG_ID,mtlp.ORGANIZATION_ID || 5111001
       FROM apps.QA_SL_SP_RCV_CRITERIA qssrcv,
            apps.MTL_SYSTEM_ITEMS MSI,
            apps.ap_suppliers PV,
            apps.ap_supplier_sites_all PVS,
            apps.QA_SAMPLING_ASSOCIATION QSPA,
            apps.QA_SAMPLING_PLANS QSPP,
            apps.QA_PLANS QP,
           -- apps.org_organization_definitions org,
            apps.MTL_PARAMETERS mtlp,
            (select * from XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX st where st.RECORD_STATUS IS NULL) stg
      WHERE     1 = 1
            AND qssrcv.vendor_id = PV.vendor_id
            AND qssrcv.VENDOR_SITE_ID = PVS.VENDOR_SITE_ID
            -- and PVS.ORG_ID=org.OPERATING_UNIT
            AND qssrcv.ITEM_ID = MSI.INVENTORY_ITEM_ID
            AND qssrcv.ORGANIZATION_ID = MSI.ORGANIZATION_ID
            AND qssrcv.CRITERIA_ID = QSPA.CRITERIA_ID
            --  and QSLA.PROCESS_ID = QSLP.PROCESS_ID
            AND QSPA.COLLECTION_PLAN_ID = QP.PLAN_ID(+)
            AND QSPA.SAMPLING_PLAN_ID = QSPP.SAMPLING_PLAN_ID
            AND qssrcv.ORGANIZATION_ID =185 --org.organization_id
            AND qssrcv.criteria_id=to_number(stg.ATTRIBUTE5)
            --and msi.segment1='1003001603'
               AND PV.segment1 = stg.supplier_code
               AND pvs.vendor_site_code = stg.ATTRIBUTE4
               AND msi.segment1 = stg.item_code
               AND mtlp.organization_id = stg.org_id
       ) T1
       WHERE EXISTS (SELECT 1
                     FROM apps.qa_plans qp
                    WHERE qp.NAME = t1.COLLECTION_PLAN_NAME
                    AND qp.organization_id=t1.ORG_ID )
---------------------


SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX where RECORD_STATUS IS NULL --30443

SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX -- 30444

SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX






DELETE FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX CH1
  WHERE NOT EXISTS (SELECT 1 FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX CH2
WHERE CH2.SUPPLIER_CODE=CH1.SUPPLIER_CODE
AND CH2.ITEM_CODE=CH1.ITEM_CODE
AND CH2.ORG_ID=CH1.ORG_ID)
and CH1.REQUEST_ID LIKE '%5111001'


DELETE  FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX CH1
  WHERE CH1.RECORD_STATUS IS NULL
  and NOT EXISTS (SELECT 1 FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX CH2
WHERE CH2.SUPPLIER_CODE=CH1.SUPPLIER_CODE||'_SITE_'||CH1.SUPPLIER_SITE_CODE
AND CH2.ITEM_CODE=CH1.ITEM_CODE
AND CH2.ORG_ID=CH1.ORG_ID)
and CH1.REQUEST_ID LIKE '%5111001'

--Check Duplicate and delete
SELECT SUPPLIER_CODE,SUPPLIER_SITE_CODE,ITEM_CODE,count(ITEM_CODE) FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX
group by SUPPLIER_CODE,SUPPLIER_SITE_CODE,ITEM_CODE
having count(ITEM_CODE)>1


SELECT SUPPLIER_CODE,ITEM_CODE,count(ITEM_CODE) FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX
group by SUPPLIER_CODE,ITEM_CODE
having count(ITEM_CODE)>1




DELETE   FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX CH3
  WHERE 1=1
 AND NOT EXISTS (SELECT 1 FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX CH2
WHERE CH2.SUPPLIER_CODE=CH3.SUPPLIER_CODE
AND CH2.ITEM_CODE=CH3.ITEM_CODE
AND CH2.ORG_ID=CH3.ORG_ID)
AND NOT EXISTS (SELECT 1 FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX CH1
WHERE CH1.RECORD_STATUS IS NULL
and CH1.SUPPLIER_CODE||'_SITE_'||CH1.SUPPLIER_SITE_CODE=CH3.SUPPLIER_CODE
AND CH1.ITEM_CODE=CH3.ITEM_CODE
AND CH1.ORG_ID=CH3.ORG_ID)
and CH3.REQUEST_ID LIKE '%5111001'











                                               
---------------------


update XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX 
set EFFECTIVE_DATE=TO_CHAR(TRUNC(:P_DATE),'DD-MON-YYYY') 


update XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX CH1
set 
CH1.EFFECTIVE_FROM=
case when CH1.SAMPLING_PLAN LIKE '%\_T\_%'  ESCAPE '\' then
TO_CHAR(TRUNC(:P_DATE),'DD-MON-YYYY') 
when CH1.SAMPLING_PLAN LIKE '%\_N\_%'  ESCAPE '\' then
TO_CHAR(TRUNC(:P_DATE+1801),'DD-MON-YYYY')
when CH1.SAMPLING_PLAN LIKE '%\_R\_%'  ESCAPE '\' then
TO_CHAR(TRUNC(:P_DATE+3602),'DD-MON-YYYY') END ,
CH1.EFFECTIVE_TO=
case when CH1.SAMPLING_PLAN LIKE '%\_T\_%'  ESCAPE '\' then
TO_CHAR(TRUNC(:P_DATE+1800),'DD-MON-YYYY')
when CH1.SAMPLING_PLAN LIKE '%\_N\_%'  ESCAPE '\' then
TO_CHAR(TRUNC(:P_DATE+3601),'DD-MON-YYYY')
when CH1.SAMPLING_PLAN LIKE '%\_R\_%'  ESCAPE '\' then
'' END 
where CH1.REQUEST_ID LIKE '%5111001'


                                     
----------------------------------
============================================
--DBA Script

insert into XXMSSL.XXMSSL_QA_SKIPLOT_SMPL_I_STG 
SELECT * FROM  XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX WHERE RECORD_STATUS IS NULL


insert into XXMSSL.XXMSSL_QA_SKIPLOT_SMPL_II_STG 
SELECT * FROM  XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX

insert into XXMSSL.XXMSSL_QA_SKIPLOT_SMPL_III_STG 
SELECT * FROM  XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX

===========================================


Run Below Program org wise and request id wise

XXMSSL Skiplot Sampling Criteria Import 12.2.11


SELECT COUNT(*),RECORD_STATUS,ORG_ID FROM XXMSSL.XXMSSL_QA_SKIPLOT_SMPL_I_STG WHERE REQUEST_ID LIKE '%5111001'
GROUP BY RECORD_STATUS,ORG_ID 


--------------

--------------------------------


insert into XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX_B 
SELECT * FROM  XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX WHERE RECORD_STATUS IS NULL


insert into XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX_B 
SELECT * FROM  XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX

insert into XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX_B 
SELECT * FROM  XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX



select * from  apps.org_organization_definitions org  where org.organization_code = 'U04' 

C03, P02, P03, P10, P19, P28, P29, P31, P33, P36, P40, P41, P42, P52,
 U04






UPDATE XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX_B
SET SAMPLING_PLAN=REPLACE(SAMPLING_PLAN,'_P52','_U04'),
COLLECTION_PLAN=REPLACE(COLLECTION_PLAN,'_P52','_U04'),
BATCH_ID=244,
ORG_ID=244,
RECORD_STATUS =NULL,
error_message=NULL,
ATTRIBUTE1=NULL


UPDATE XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX_B
SET SKIP_LOT_PROCESS=REPLACE(SKIP_LOT_PROCESS,'_P52','_U04'),
BATCH_ID=244,
ORG_ID=244,
RECORD_STATUS =NULL,
error_message=NULL,
ATTRIBUTE1=NULL

UPDATE XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX_B
SET 
BATCH_ID=244,
ORG_ID=244,
RECORD_STATUS =NULL,
error_message=NULL,
ATTRIBUTE1=NULL


SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX_B

SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX_B

SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX_B



INSERT INTO XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX
SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX_B

INSERT INTO XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX
SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX_B


INSERT INTO XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX
SELECT * FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX_B



---
SELECT COUNT(*),ORG_ID FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_I_STG_EX
GROUP BY ORG_ID

SELECT COUNT(*),ORG_ID FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_II_STG_EX
GROUP BY ORG_ID


SELECT COUNT(*),ORG_ID FROM XXMSSLBKP.XXMSSL_QA_SKIPLOT_SMPL_III_STG_EX
GROUP BY ORG_ID
