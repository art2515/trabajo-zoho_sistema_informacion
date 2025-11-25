/***********************************************************************************************
PROCESO: Aplicación del 50% de financiación (Proceso manual/automático) / error de secuencias
------------------------------------------------------------------------------------------------
DESCRIPCIÓN GENERAL:
Que es el 50% : el 50% porciento es el descuento que se aplica al estudiante cuando realiza el primer pago del credito en ctayuda , que ese pago inicial es la RPVI
Este proceso permite aplicar manualmente el 50% de financiación a un estudiante cuando el 
proceso automático no se ejecuta correctamente. 
Sucede normalmente cuando:
- El estudiante no tiene cargado el pago de la RPVI.
- No existe la RPI correspondiente.
- El estudiante no está “Apto”.

------------------------------------------------------------------------------------------------
VALIDACIONES PREVIAS:
1. Verificar en ICEBERG si el estudiante tiene RPVI del periodo requerido.
2. Confirmar que la FAMA (Factura de Matrícula) no esté liquidada.
3. Validar que la RPVI aparezca con estado “Liquidado”.
   - Si no está liquidada, se debe revisar en Cartera de ICEBERG si existe saldo a favor.
   - En caso de existir saldo, solicitar que se crucen los valores.

------------------------------------------------------------------------------------------------
PROCEDIMIENTO GENERAL:
1. Revisar en la tabla **LIQUIDACION_ORDEN** si la RPVI está liquidada eso se busca con el dato de ORDEN_INICIAL DE LA TABLA 1.
2. Si está liquidada, verificar en la tabla **cltiene_360_estudiantes** (tabla 3)
   que el proceso no esté registrado.
3. Obtener la referencia de pago desde la tabla (tramite)**cunt_tramite_externo** (tabla 1).
4. Usar la vista **v_inserta_estudiantes_360** para realizar el INSERT en 
   **cltiene_360_estudiantes**, aplicando así el 50%.

------------------------------------------------------------------------------------------------


/*-----------------------------------------------------------
SECCIÓN 1: CONSULTAS DE VALIDACIÓN
-----------------------------------------------------------*/

/* Buscar la liquidación de una orden específica */
SELECT * 
FROM ICEBERG.LIQUIDACION_ORDEN 
WHERE orden = 112713; -- Orden_inicial


/* Ver todos los trámites realizados por el estudiante */
SELECT tramite, orden,t.ORDEN_INICIAL, valor_financiacion, t.*, rowid 
FROM iceberg.cunt_tramite_externo t 
WHERE identificacion = '1022352352';  --- Tabla 1


/* Ver historial de transacciones del estudiante */
/*Si aparece en la primera tabla y no en la segunda toca clear el registro*/
SELECT t.*, rowid 
FROM iceberg.cltiene_transaccion_his t 
WHERE numidentificacion in ('1022352352');  --- Tabla 2 -- cc para crear registros 1030637576 -- los datos se consigue de la tabla 1
 --la referencia es = a tramite ,--MENSAJE = OK-REFERENCIA --ORDEN = ORDEN-- ORDENPAGO = ORDENINICIAL --ID,FECHA_CREACION,USU_CREACION = NULL -- PORCENTAJE_AVAL = 0, FUERZA_COMERCIAL = AGENTE COMERCIAL


/* Ver estado de financiación del estudiante
   ESTADO_FINANCIACION:
   - 0 → 50%
   - 1 → 100%
   - 2 → Anulado

   Esta tabla también se usa para anular un 50%, 
   cambiando el estado de financiación a 2 (en ambas columnas).
*/
SELECT referencia_pago, orden_cun, valor_financiacion, ESTADO_FINANCIACION, t.*
FROM iceberg.cltiene_360_estudiantes t 
WHERE numero_documento IN ('1022352352', '');  --- Tabla 3 

SELECT referencia_pago, orden_cun, valor_financiacion, ESTADO_FINANCIACION, t.*
FROM iceberg.cltiene_360_estudiantes t 
WHERE t.REFERENCIA_PAGO  IN ('119101230', '');


/*-----------------------------------------------------------
SECCIÓN 2: APLICAR EL 50%
-----------------------------------------------------------*/

/* Insertar el pago en la tabla 360 para aplicar el 50% , la tabla 3
   - La referencia de pago se obtiene desde la Tabla 1 (campo “tramite”)
   - Se toma de la vista v_inserta_estudiantes_360
*/
-- PARA CREAR EL 50% SIEMPRE TIENE QUE ESTAR EN TABLA 1 Y 2
INSERT INTO ICEBERG.cltiene_360_estudiantes
SELECT * 
FROM ICEBERG.v_inserta_estudiantes_360  
WHERE numero_documento = '1022352352'
  AND referencia_pago = '119101230';-- tramite


/* Validar que el registro se haya insertado correctamente */
SELECT referencia_pago, orden_cun, valor_financiacion, ESTADO_FINANCIACION, t.* 
FROM ICEBERG.cltiene_360_estudiantes t 
WHERE numero_documento = '53124512' 
  AND referencia_pago = '118264359';

/* Consultar nuevamente en la vista para validar origen de datos */
SELECT * 
FROM ICEBERG.v_inserta_estudiantes_360  
WHERE numero_documento = '53124512' 
  AND referencia_pago = '118264359';



/*-----------------------------------------------------------
SECCIÓN 3: ACTUALIZAR CONSECUTIVO RPVI
-----------------------------------------------------------*/

/* Actualiza el campo CONSECUTIVO_ACTIVACION en la tabla ORDEN
   tomando el valor de LIQUIDACION correspondiente a la orden y periodo.
   Solo actualiza cuando el consecutivo es NULL.
*/
UPDATE ICEBERG.ORDEN o 
SET o.CONSECUTIVO_ACTIVACION = (
    SELECT l.LIQUIDACION 
    FROM ICEBERG.LIQUIDACION_ORDEN l 
    WHERE o.ORDEN = l.ORDEN 
      AND o.PERIODO = l.PERIODO 
      AND o.ESTADO = l.ESTADO 
      AND o.DOCUMENTO = l.DOCUMENTO 
      AND o.CLIENTE_SOLICITADO = l.CLIENTE
)
WHERE o.PERIODO LIKE '%25%' 
  AND o.ESTADO = 'V' 
  AND o.DOCUMENTO = 'RPVI' 
  AND o.CONSECUTIVO_ACTIVACION IS NULL 
  AND o.CLIENTE_SOLICITADO IN ('1016949319')
  AND EXISTS (
    SELECT 1 
    FROM ICEBERG.LIQUIDACION_ORDEN l 
    WHERE o.ORDEN = l.ORDEN 
      AND o.PERIODO = l.PERIODO 
      AND o.ESTADO = l.ESTADO 
      AND o.DOCUMENTO = l.DOCUMENTO 
      AND o.CLIENTE_SOLICITADO = l.CLIENTE
  );


/* Validar que se haya actualizado correctamente el consecutivo */
SELECT O.CONSECUTIVO_ACTIVACION ,O.*, ROWID 
FROM ICEBERG.ORDEN O 
WHERE O.CLIENTE_SOLICITADO = '1043657168' 
  AND O.DOCUMENTO = 'RPVI';	

/*-----------------------------------------------------------
SECCIÓN 4: ERROR DE SECUENCIA
-----------------------------------------------------------*/
-- este error sucede cuando en 360 cltiene aparece el letrero rojo y en la informacion secuecia

SELECT * 
FROM ZOHO_CUN.CUNT_ZOHO_REGISTRO_VIRTUAL czrv 
WHERE czrv.NUMERO_DOCUMENTO  = '1000469503'
;
