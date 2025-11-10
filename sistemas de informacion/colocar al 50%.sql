--- Aplicar el 50%
--- El proceso es automatico , pero hay procesos que no pasa poque no esta cargado el pago de la rpvi , no tiene rpi , o no apto 
--- Se revisa primero en iceber , que tenga RPVI y que la Fama no Este Liquidad
--- el RPVI debe aparecer Liquidado , en tal caso de no estar se debe valida en Cartera de Iceber que tenga saldo a favor 


--- SE UTILIZA PARA BUSCAR LAS LIQUIDACIONES
SELECT * FROM ICEBERG.LIQUIDACION_ORDEN WHERE orden = (110496);
--- SE VEN TODOS LOS PROCESOS QUE A REALIZADO EL ESTUDIANTE
select tramite, orden, valor_financiacion, t.*, rowid from iceberg.cunt_tramite_externo t where identificacion = '1012444362'; ---1  
--- SE VE UN HISTORIAL DE TODO LO Q HA HECHO EL ESTUDIANTE    
select t.*, rowid from iceberg.cltiene_transaccion_his t where numidentificacion= '1012444362'; --- 2
--- SE VE EL ESTADO DE LA FINACIANCCION DEL ESTUDIANTE
--- EL ESTADO DE FINANCIACION ES 0 50% , 1% 100% Y 2 ES ANULADO
--- ESTA TABLA TAMBIEN SE UTILIZA PARA ANULAR UN 50% , EN ESE CASO SE QUITA EN ESTADO DE FINANCIACION COLOCANDO EL NUMERO EN 2 , ESO EN LAS DOS CULNAS , SE LLAMA IGUAL
select referencia_pago,orden_cun,valor_financiacion,ESTADO_FINANCIACION, t.*
from iceberg.cltiene_360_estudiantes t where numero_documento IN ('1012444362','');-----3    


---------------------COLOCAR_50%---------------------------------------------------------------------------------------------------------------------------------------------
--- PARA INSERTAR LE PAGO A LA TABLA Y QUE LE APAREZCA AL 50%
INSERT INTO ICEBERG.cltiene_360_estudiantes SELECT * FROM ICEBERG.v_inserta_estudiantes_360  WHERE numero_documento = '1012444362' AND referencia_pago = '118399658';

 
-------------------CONSECUTIVO_RPVI------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

UPDATE ICEBERG.ORDEN o SET o.CONSECUTIVO_ACTIVACION = (
    SELECT l.LIQUIDACION FROM ICEBERG.LIQUIDACION_ORDEN l WHERE o.ORDEN = l.ORDEN AND o.PERIODO = l.PERIODO AND o.ESTADO = l.ESTADO AND o.DOCUMENTO = l.DOCUMENTO AND o.CLIENTE_SOLICITADO = l.CLIENTE)
WHERE o.PERIODO LIKE '%25%' AND o.ESTADO = 'V' AND o.DOCUMENTO = 'RPVI' AND o.CONSECUTIVO_ACTIVACION IS NULL AND o.CLIENTE_SOLICITADO IN ('1016949319') AND EXISTS 
(SELECT 1 FROM ICEBERG.LIQUIDACION_ORDEN l WHERE o.ORDEN = l.ORDEN AND o.PERIODO = l.PERIODO AND o.ESTADO = l.ESTADO AND o.DOCUMENTO = l.DOCUMENTO AND o.CLIENTE_SOLICITADO = l.CLIENTE);

SELECT O.*, ROWID FROM ICEBERG.ORDEN O WHERE O.CLIENTE_SOLICITADO = '1016949319' AND O.DOCUMENTO = 'RPVI'
