
-- ajustar porcentaje segun la promocion "las promociones solo aplican para nuevos , antes toca validar en sinu que la persona con sea antiguo"

-- se utiliza para ver si esta la linia creada en 360 
SELECT c.*, rowid FROM ICEBERG.CLTIENE_360_FUERZA_COMERCIAL c  
WHERE C.NUMERODOCUMENTO IN ('40612531');


-- se utiliza para ver que descuentos estan activos 
SELECT *  FROM ICEBERG.CUNT_DATOS_AVAL_X_FUERZA cdaxf ;

-- se utiliza para revisar si cuenta con con la clase actual para el periodo que corresponde , 
--(la linea debe aparce en la casilla como Nuevo y debe corresponder al que aparece en 360) 
--'1016944046' asi es para que aparezca en descuento que le corresponde 
SELECT c.NUEVO ,c.TIP_INSCR, c.CLASE_ACTUAL, c.* FROM ICEBERG.CUNT_ALUMNOS_ORDENES_X_PERIODO c
WHERE c.DOC_ALUM IN ('40612531','') AND c.DOCUMENTO = 'FAMA'; 


-- se utiliza para envior unos sp que actuliza las promociones que no sea an actulizado
CALL cup_reportes_matriculas.recupera_datos_matriculas('26ES1');
CALL cup_reportes_matriculas.recupera_datos_matriculas('25ET5');
CALL cup_reportes_matriculas.recupera_datos_matriculas('2026A');
CALL cup_reportes_matriculas.recupera_datos_matriculas('25ES4');
CALL cup_reportes_matriculas.recupera_datos_matriculas('25E05');
CALL cup_reportes_matriculas.recupera_datos_matriculas('26ES1');
