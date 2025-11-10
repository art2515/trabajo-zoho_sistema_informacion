--- VALIDAR PAGO

--- PARA VALIDAR PAGO SE DEBE REVISAR PRIMERO EN PLACETOPLAY QUE SI ESTE LA TRASACCION APROVADA 

-------Validacion pagos -------------------------------REJECTED----------------------------APPROVED-----------------------

--- ES PARA MIRAR EL HISTORIA DE PAGO POR DOCUMENTO

select t.ESTADO,t.ESTADO_ICEBERG,t.* from PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago t where documento IN ('1016942271') ORDER BY FECHA DESC; 

--- ES PARA MIRAR EL HISTORIA DE PAGO POR REFERENCIA Y EN DECRICION EL TIPO DE PAGO
select * from PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago where referencia IN ('118376914','');

--- PARA REVISERA TRANSACCION
select * from PORTAL_PAGOS_CUN.ppt_cun_respuesta_pago  where referencia IN ('','118376914');

--- ES PARA LO PAGO QUE ESTAN CARGADO EN EL SISTEMA DE ICEBER , SI NO ESTA ES PORQUE NO ESTA EN ICEBER
select * from PORTAL_PAGOS_CUN.ppt_cun_detalle_respuesta_pago  where referencia IN ('118376914','','');

---- DEPENDIENDO DEL TIPO DE POCO LE ELIGE LA CONSULA 
---CREDITO:
SELECT * FROM PORTAL_PAGOS_CUN.Ppt_Cun_Base_CREDITO T WHERE T.recibo_agrupado IN ('118376914');

---ORDENES:
SELECT T.*, ROWID FROM PORTAL_PAGOS_CUN.Ppt_Cun_Base_ORDENES T WHERE recibo_agrupado IN ('118250139');


---PECUNIARIO:
SELECT T.*, ROWID FROM Ppt_Cun_Base_PECUNIARIOS T WHERE recibo_agrupado IN ('117101426');



--PARA REFERENCIAR O CARGAR PAGOS credito

--- POR EL MOMENTO NO UTILIZAR
DELETE FROM PORTAL_PAGOS_CUN.PPT_CUN_BASE_CREDITO WHERE recibo_agrupado IN (112923913);
commit;


--SE UTILIZA PARA ACTUALIZAR LA ANTIGUA REFERENCIA CON EL RECIBO DE LA NUEVA REFERENCIA QUE SE CREA EN EL PORTAL DE PAGOS 
                                                                    --Antigua                             --Nueva
UPDATE PORTAL_PAGOS_CUN.PPT_CUN_BASE_CREDITO SET RECIBO_AGRUPADO = '117973906' WHERE recibo_agrupado IN ('118248441');
COMMIT;


--SE UTILIZA PARA ACTUALIZAR LA ANTIGUA REFERENCIA CON EL RECIBO DE LA NUEVA REFERENCIA QUE SE CREA EN EL PORTAL DE PAGOS 
--Pecuniarios 
UPDATE PORTAL_PAGOS_CUN.PPT_CUN_BASE_PECUNIARIOS pcbp SET RECIBO_AGRUPADO = '114433690' WHERE recibo_agrupado IN ('116529123');
commit;


--SE UTILIZA PARA ELIMINAR LA NUEVA REFERENCIA QUE SE CREO EN EL PORTAL DE PAGOS 
                                                                           --Nueva
DELETE FROM PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago WHERE referencia IN ('118248441');
commit;

-- SE UTILIZA CUANDO QUEDA REPREZADO EN LA BASE Y NO SUBIO A ICEBERD
                                                                --referencia--secuencia-pago-franchyse-fecha del pago--
BEGIN  PORTAL_PAGOS_CUN.PPP_CUN_BASE_ORDENES.procesa_pagos_aprobados(118250139,1,99784,'PSE',TO_DATE('07/11/2025','DD/MM/YYYY'),'','00','NORMAL');  
COMMIT;
end;
