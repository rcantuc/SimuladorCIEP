capture set processors 1
set linesize 200
sysdir set SITE "/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-contrato32/"
adopath ++SITE
cd "/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-contrato32"
di "STATA_VERSION=" c(stata_version) " PROCESSORS=" c(processors)
do "/Users/ricardo/CIEP_Simuladores/diag-v8.13a-contrato-32-2026-10-19/corrida2/SIM_run.do"
do "/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-contrato32/05_scripts/compuertas-entidad.do" "/Users/ricardo/CIEP_Simuladores/diag-v8.13a-contrato-32-2026-10-19/corrida2"
do "/Users/ricardo/CIEP_Simuladores/SimuladorCIEP-contrato32/05_scripts/contrato-32.do" "/Users/ricardo/CIEP_Simuladores/diag-v8.13a-contrato-32-2026-10-19/corrida2"
