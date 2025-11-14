/***********************************************************************************************
PROCESO: Validación y Gestión de Pagos
------------------------------------------------------------------------------------------------
DESCRIPCIÓN GENERAL:
Este proceso permite validar el estado de los pagos realizados por los estudiantes en el 
portal de pagos (PLACETOPAY) y verificar si estos se encuentran correctamente reflejados 
en las bases de datos del sistema ICEBERG.

Además, incluye consultas para:
- Revisar transacciones aprobadas o rechazadas.
- Confirmar si el pago fue cargado en el sistema interno.
- Actualizar o corregir referencias de pago (en casos de errores).
- Procesar manualmente pagos represados que no se subieron automáticamente a ICEBERG.

------------------------------------------------------------------------------------------------
VALIDACIONES PRINCIPALES:
1. Verificar primero en **PLACETOPAY** que la transacción tenga estado **APPROVED**.
2. Confirmar que el pago aparezca en las tablas del esquema **PORTAL_PAGOS_CUN**.
3. Validar si el registro fue replicado correctamente en **ICEBERG**.
4. En caso contrario, ejecutar los procedimientos o actualizaciones necesarias 
   según el tipo de pago (Crédito, Orden o Pecuniario).

------------------------------------------------------------------------------------------------
TABLAS Y OBJETOS INVOLUCRADOS:
- PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago → Transacciones registradas en el portal.
- PORTAL_PAGOS_CUN.ppt_cun_respuesta_pago → Respuestas del gateway (PLACETOPAY).
- PORTAL_PAGOS_CUN.ppt_cun_detalle_respuesta_pago → Detalles técnicos de pagos cargados.
- PORTAL_PAGOS_CUN.Ppt_Cun_Base_CREDITO → Pagos tipo crédito.
- PORTAL_PAGOS_CUN.Ppt_Cun_Base_ORDENES → Pagos por órdenes.
- PORTAL_PAGOS_CUN.Ppt_Cun_Base_PECUNIARIOS → Pagos pecuniarios.
- Procedimiento: PORTAL_PAGOS_CUN.PPP_CUN_BASE_ORDENES.procesa_pagos_aprobados → 
  Ejecuta el proceso manual de carga del pago en ICEBERG.

idacion pagos -------------------------------REJECTED----------------------------APPROVED-----------------------


/*-----------------------------------------------------------
SECCIÓN 1: VALIDACIÓN DE PAGOS EN EL PORTAL (PLACETOPAY)
-----------------------------------------------------------*/

/* Validar si la transacción aparece con estado APPROVED
   Muestra el historial de pagos por documento
*/
SELECT t.ESTADO, t.ESTADO_ICEBERG, t.* 
FROM PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago t 
WHERE documento IN ('1108932127') 
ORDER BY FECHA DESC;


/* Consultar historial de pago por referencia
   - En la columna DESCRIPCION aparece el tipo de pago (crédito, orden, pecuniario, etc.)
*/
SELECT * 
FROM PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago 
WHERE referencia IN ('3210435', ''); -- Tabla 1


/* Consultar detalles de la transacción asociada a una referencia específica */
SELECT * 
FROM PORTAL_PAGOS_CUN.ppt_cun_respuesta_pago  
WHERE referencia IN ('3210435', ''); -- Tabla 2


/* Consultar los pagos que fueron cargados al sistema ICEBERG
   - Si el pago no aparece aquí, significa que aún no se reflejó en ICEBERG
*/
SELECT * 
FROM PORTAL_PAGOS_CUN.ppt_cun_detalle_respuesta_pago  
WHERE referencia IN ('118621847', '', '');  -- Tabla 3


--Nomenclatura banco se utilizas crear la nueva linea de pago a cargar en iceberd
SELECT * FROM PORTAL_PAGOS_CUN.PPT_CUN_RESPUESTA_PAGO p
WHERE p.PAYMENTMETHODNAME  = 'Credibanco Visa';--110770968

SELECT * FROM PORTAL_PAGOS_CUN.PPT_CUN_RESPUESTA_PAGO p
WHERE p.PAYMENTMETHODNAME  = 'Bancolombia';--83213107

SELECT * FROM PORTAL_PAGOS_CUN.PPT_CUN_RESPUESTA_PAGO p
WHERE p.PAYMENTMETHODNAME  = 'American Express';

SELECT * FROM PORTAL_PAGOS_CUN.PPT_CUN_RESPUESTA_PAGO p
WHERE p.PAYMENTMETHODNAME  = 'Visa';

SELECT * FROM PORTAL_PAGOS_CUN.PPT_CUN_RESPUESTA_PAGO p
WHERE p.PAYMENTMETHODNAME  = 'MasterCard';--2525440

SELECT * FROM PORTAL_PAGOS_CUN.PPT_CUN_RESPUESTA_PAGO p
WHERE p.PAYMENTMETHODNAME  = 'Cuentas débito ahorro y corriente (PSE)'; --83221878

SELECT * FROM PORTAL_PAGOS_CUN.PPT_CUN_RESPUESTA_PAGO p
WHERE p.PAYMENTMETHODNAME  = 'Corresponsales bancarios Grupo Aval';--83218880


-- es para consulta Datos personales de las persona

SELECT  * FROM bas_tercero 
 WHERE NUM_IDENTIFICACION = '52433704';

/*-----------------------------------------------------------
SECCIÓN 4: PROCESAR PAGOS REPRESADOS MANUALMENTE
-----------------------------------------------------------*/

/* Se utiliza cuando el pago quedó registrado en el portal 
   pero no se cargó automáticamente en ICEBERG.
   pero solo se hace cuando esta en la tabla 1 y 2 , en tal caso que no esta se crea la linea en la tabla 2  

   Parámetros:
   - referencia (número de pago)
   - secuencia
   - pago
   - franquicia (tipo de pago: PSE, tarjeta, etc.)
   - fecha del pago
   - campos adicionales vacíos o normales según el caso
*/
BEGIN  
  PORTAL_PAGOS_CUN.PPP_CUN_BASE_ORDENES.procesa_pagos_aprobados(
    118621847,         -- referencia
    1,                 -- secuencia -- siempre es 1 pero hay casos que son pagos represados 
    997300,             -- número de pago
    'PSE',             -- franquicia
    TO_DATE('14/11/2025','DD/MM/YYYY'),  -- fecha del pago
    '', 
    '00', 
    'NORMAL'
  );  
COMMIT;
END;



/*-----------------------------------------------------------
SECCIÓN 2: CONSULTAS SEGÚN TIPO DE PAGO
-----------------------------------------------------------*/

/* PAGOS DE CRÉDITO */
SELECT * 
FROM PORTAL_PAGOS_CUN.Ppt_Cun_Base_CREDITO T 
WHERE T.recibo_agrupado IN ('118376914');


/* PAGOS DE ORDENES */
SELECT T.*, ROWID 
FROM PORTAL_PAGOS_CUN.Ppt_Cun_Base_ORDENES T 
WHERE recibo_agrupado IN ('118621847');


/* PAGOS PECUNIARIOS */
SELECT T.*, ROWID 
FROM Ppt_Cun_Base_PECUNIARIOS T 
WHERE recibo_agrupado IN ('117101426');



/*-----------------------------------------------------------
SECCIÓN 3: OPERACIONES DE MANTENIMIENTO Y AJUSTES
-----------------------------------------------------------*/

/* ⚠️ NO UTILIZAR POR EL MOMENTO
   (Eliminar un registro de pago crédito del sistema)
*/
DELETE FROM PORTAL_PAGOS_CUN.PPT_CUN_BASE_CREDITO 
WHERE recibo_agrupado IN (112923913);
COMMIT;


/* Actualizar la referencia antigua con la nueva referencia generada en el portal de pagos
   - Se usa cuando se crea una nueva referencia y debe reemplazar la anterior.
   - Ejemplo: (Antigua → Nueva)
*/
UPDATE PORTAL_PAGOS_CUN.PPT_CUN_BASE_CREDITO 
SET RECIBO_AGRUPADO = '117973906' 
WHERE recibo_agrupado IN ('118248441');
COMMIT;


/* Actualizar referencia en pagos pecuniarios 
   (Antigua → Nueva) */
UPDATE PORTAL_PAGOS_CUN.PPT_CUN_BASE_PECUNIARIOS pcbp 
SET RECIBO_AGRUPADO = '114433690' 
WHERE recibo_agrupado IN ('116529123');
COMMIT;


/* Eliminar la nueva referencia creada en el portal de pagos
   (Ejemplo: borrar registro erróneo)
*/
DELETE FROM PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago 
WHERE referencia IN ('118248441');
COMMIT;





