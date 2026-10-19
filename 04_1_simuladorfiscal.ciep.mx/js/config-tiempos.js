/*
 * config-tiempos.js — ÚNICA fuente de los segundos de la cuenta regresiva del «Calcular» (v8.12.2).
 *
 * La cuenta regresiva es COSMÉTICA: el fin lo dicta la respuesta de calculaStata.php (el POST es
 * síncrono: Stata corre dentro de la petición). Si el run termina antes, el reloj se corta y los
 * resultados aparecen de inmediato; si tarda más que la cuenta, el indicador pasa a «Finalizando…»
 * en lugar de llegar a 0 y quedarse. Los textos salen del markup (#cargando-notify), ES y EN.
 *
 * DÓNDE SE AJUSTA: aquí, en CIEP_TIEMPOS. Un valor por flujo (qué corre Stata en cada clic):
 *   principal  «Calcular» sin submódulos (moduloCambio = 0, moduloCambioIva = 0)
 *   isr        se cambió algo del submódulo ISR / cuotas IMSS (moduloCambio = 1): corre ISR_Mod.do
 *   iva        se cambió algo del submódulo IVA (moduloCambioIva = 1): corre IVA_Mod.do
 *   isr_iva    ambos
 * Valor = tiempo medido en el VPS + ~25 % de margen, redondeado hacia arriba a múltiplo de 5 s.
 * Medición y escalado local→VPS: 02_governance/perf/cronometro-calcular-2026-10-19.md.
 * Re-medir al cambiar el motor: el «Calcular» de humo de publicar-vps.sh (Fase 6) imprime el tiempo
 * real del flujo principal en el VPS.
 */
(function (w, $) {
	'use strict';

	var CIEP_TIEMPOS = {
		principal: 25,
		isr: 40,
		iva: 40,
		isr_iva: 50
	};
	w.CIEP_TIEMPOS = CIEP_TIEMPOS;

	var timer = null;

	w.CIEPCronometro = {
		// qué flujo lanzará este clic, según los flags que el formulario manda a calculaStata.php
		flujo: function () {
			var isr = String($('#moduloCambio').val()) === '1';
			var iva = String($('#moduloCambioIva').val()) === '1';
			return isr && iva ? 'isr_iva' : (isr ? 'isr' : (iva ? 'iva' : 'principal'));
		},
		iniciar: function (flujo) {
			var contador = CIEP_TIEMPOS[flujo] || CIEP_TIEMPOS.principal;
			if (timer) clearInterval(timer);
			$('#cargando-notify .cronometro-fin').hide();
			$('#cargando-notify .cronometro-cuenta').show();
			$('#count').text(contador);
			$('#cargando-notify').addClass('active');
			timer = setInterval(function () {
				contador--;
				if (contador > 0) {
					$('#count').text(contador);
				} else {
					// la cuenta se acabó pero el run no: sigue el spinner, sin número
					clearInterval(timer);
					timer = null;
					$('#cargando-notify .cronometro-cuenta').hide();
					$('#cargando-notify .cronometro-fin').show();
				}
			}, 1000);
		},
		// el run terminó (éxito o error): se corta el reloj y se oculta el aviso
		terminar: function () {
			if (timer) { clearInterval(timer); timer = null; }
			$('#cargando-notify').removeClass('active');
		}
	};
})(window, window.jQuery);
