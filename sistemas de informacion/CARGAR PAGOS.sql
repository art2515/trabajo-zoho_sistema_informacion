/***********************************************************************************************
PROCESO: Validación, Gestión de Pagos,Cargar pagos, Rechazar pagos , empujar pagos
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

/*-----------------------------------------------------------
SECCIÓN 1: VALIDACIÓN DE PAGOS EN EL PORTAL (PLACETOPAY)/ RECHAZAR PAGOS Y EMPUJAR PAGOS
-----------------------------------------------------------*/

/*------------------------------------------------------------------------------------------------
VALIDACIONES PRINCIPALES:
1. Verificar primero en **PLACETOPAY** que la transacción tenga estado **APPROVED**.
2. Confirmar que el pago aparezca en las tablas del esquema **PORTAL_PAGOS_CUN**.
3. Validar si el registro fue replicado correctamente en **ICEBERG**.
4. En caso contrario, ejecutar los procedimientos o actualizaciones necesarias 
   según el tipo de pago (Crédito, Orden o Pecuniario).

------------------------------------------------------------------------------------------------*/ 

--Validacion pagos -------------------------------REJECTED----------------------------APPROVED-----------------------

/* Validar si la transacción aparece con estado APPROVED
   Muestra el historial de pagos por documento
   Si aparece Pendig en placetopay no se puede rechazar hasta que pase a rechazado
*/
-- busqueda por cc
SELECT t.ESTADO, t.ESTADO_ICEBERG, t.* 
FROM PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago t 
WHERE documento IN ('1072527983')
ORDER BY FECHA DESC;
-- busqueda por referencia
SELECT t.ESTADO, t.ESTADO_ICEBERG, t.* 
FROM PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago t 
WHERE t.REFERENCIA  IN ('118903436')
ORDER BY FECHA DESC;

/* Consultar historial de pago por referencia
   - En la columna DESCRIPCION aparece el tipo de pago (crédito, orden, pecuniario, etc.)
*/
SELECT * 
FROM PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago 
WHERE referencia IN ('118903436', ''); -- Tabla 1


/* Consultar detalles de la transacción asociada a una referencia específica */
-- Si no esta registrado , lo registro manualmente tomando los datos de desde placetopay para empujar los datos a la tabla 3
SELECT * 
FROM PORTAL_PAGOS_CUN.ppt_cun_respuesta_pago  
WHERE referencia IN ('118903436', ''); -- Tabla 2 --99999945


/* Consultar los pagos que fueron cargados al sistema ICEBERG
   - Si el pago no aparece aquí, significa que aún no se reflejó en ICEBERG
*/
SELECT * 
FROM PORTAL_PAGOS_CUN.ppt_cun_detalle_respuesta_pago  
WHERE referencia IN ('118903436', '', '');  -- Tabla 3


--Nomenclatura banco se utilizas se utiliza como referencias para crear la nueva linea de pago a cargar en iceberd
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
WHERE p.PAYMENTMETHODNAME  = 'Cuentas débito ahorro y corriente (PSE)'AND p.ISSUERNAME = 'NEQUI' ORDER by p.REFERENCIA desc; --99999945

SELECT * FROM PORTAL_PAGOS_CUN.PPT_CUN_RESPUESTA_PAGO p
WHERE p.PAYMENTMETHODNAME  = 'Corresponsales bancarios Grupo Aval';--83218880


-- es para consulta Datos personales de las persona

SELECT  * FROM bas_tercero 
 WHERE NUM_IDENTIFICACION = '52433704';

/*-----------------------------------------------------------
SECCIÓN 2: SE UTILIZA PARA CARGAR LOS PAGO REPRESADOS , SE PUEDEN EMPUJAR O CREAR LOS PAGOS  
-----------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------
VALIDACIONES PRINCIPALES:
EMPUJAR
1. Verificar primero en **PLACETOPAY** que la transacción tenga estado **APPROVED**.
2. Confirmar que el pago aparezca en las tablas del tabla 1 y 2 y aparte que apareca en una de las tablas de credito, pagos ordenes o pecuniarios.
CREAR
1. Verificar primero en **PLACETOPAY** que la transacción tenga estado **APPROVED**.
2. Confirmar que el pago aparezca en las tablas del tabla 1 y 2 y que no este en una de las tablas de credito, pagos ordenes o pecuniarios.

------------------------------------------------------------------------------------------------*/ 

/* PAGOS DE CRÉDITO */
SELECT * 
FROM PORTAL_PAGOS_CUN.Ppt_Cun_Base_CREDITO T 
WHERE T.recibo_agrupado IN ('118376914');


/* PAGOS DE ORDENES */
SELECT T.*, ROWID 
FROM PORTAL_PAGOS_CUN.Ppt_Cun_Base_ORDENES T 
WHERE recibo_agrupado IN ('1023702422');


/* PAGOS PECUNIARIOS */
SELECT T.*, ROWID 
FROM Ppt_Cun_Base_PECUNIARIOS T 
WHERE recibo_agrupado IN ('117101426');


/*-----------------------------------------------------------
SECCIÓN 4: PROCESAR PAGOS REPRESADOS MANUALMENTE
-----------------------------------------------------------*/

/* Se utiliza cuando el pago quedó registrado en el portal 
   pero no se cargó automáticamente en ICEBERG.
   pero solo se hace cuando esta en la tabla 1, 2 y de las tablas de credito, pagos ordenes o pecuniarios y no aparece en la tabla 3 , 

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
SECCIÓN 3: OPERACIONES DE MANTENIMIENTO Y AJUSTES , ESTO SE UTILIZA PARA CREAR LA LINIA Y CREAR EL PAGO CON LA NUEVA REFENCIA 
-----------------------------------------------------------*/

/* Actualizar la referencia antigua con la nueva referencia generada en el portal de pagos
   - Se usa cuando se crea una nueva referencia y debe reemplazar la anterior.
   - Ejemplo: (Antigua → Nueva)
*/

UPDATE PORTAL_PAGOS_CUN.PPT_CUN_BASE_CREDITO 
SET RECIBO_AGRUPADO = '117973906' -- ANTIGUA	
WHERE recibo_agrupado IN ('118248441');-- NUEVA
COMMIT;


/* Actualizar referencia en pagos pecuniarios 
   (Antigua → Nueva) */
UPDATE PORTAL_PAGOS_CUN.PPT_CUN_BASE_PECUNIARIOS pcbp 
SET RECIBO_AGRUPADO = '114433690' -- ANTIGUA	
WHERE recibo_agrupado IN ('116529123');-- NUEVA
COMMIT;


/* Eliminar la nueva referencia creada en el portal de pagos
   (Ejemplo: borrar registro erróneo)
*/
DELETE FROM PORTAL_PAGOS_CUN.ppt_cun_transaccion_pago 
WHERE referencia IN ('118248441'); -- NUEVA
COMMIT;






