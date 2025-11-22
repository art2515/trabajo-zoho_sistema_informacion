https://github.com/Cristianjva05/trabajo-zoho_sistema_informacion/tree/mainUPDATE --Modifica los registros existentes en una tabla
--select * from 
  src_enc_liquidacion L 
SET 
  L.est_liquidacion = 2
WHERE -- Clausula que determina cuentos registros se actualizaran
  L.id_alum_programa IN (
                          SELECT  
                            P.id_alum_programa
                               --Descomentarear para validar datos
                        /*    , b.num_identificacion       
                              , b.nom_largo
                              , u.cod_unidad
                              , u.nom_unidad
                              , p.cod_periodo                                                          
                     */   FROM 
                            bas_tercero B
                            , src_alum_programa P
                            , src_uni_academica U
                          WHERE 
                            B.id_tercero = P.id_tercero
                            AND B.num_identificacion IN ('1192718504') --Numero de identificacion
                            AND U.cod_unidad = P.cod_unidad
                          --AND P.cod_pensum = '1110' 
                          --AND P.cod_unidad = 'VTE01'
                        )
  AND L.cod_periodo = '25V06';
