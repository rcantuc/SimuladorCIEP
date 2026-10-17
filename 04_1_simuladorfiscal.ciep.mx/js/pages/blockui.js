$(document).ready(function() {
    
    "use strict";
    $('#guardar-ingresos').click(function() { 
        $('#box-ingresos').block({ 
            message: '<div class="spinner-grow text-primary" role="status"><span class="sr-only">Loading...</span></div>',
            timeout: 2000 
        }); 

    });
		
	$('#guardar-gastos').click(function() { 
        $('#box-gastos').block({ 
            message: '<div class="spinner-grow text-primary" role="status"><span class="sr-only">Loading...</span></div>',
            timeout: 2000 
        }); 

    });
	
	$('#guardar-pib').click(function() { 
        $('#box-pib').block({ 
            message: '<div class="spinner-grow text-primary" role="status"><span class="sr-only">Loading...</span></div>',
            timeout: 2000 
        }); 

    });	

    $('#blockui-2').click(function() { 
        $.blockUI({ 
            message: '<div class="spinner-grow text-primary" role="status"><span class="sr-only">Loading...</span></div>',
            timeout: 2000 
        }); 
    }); 

});