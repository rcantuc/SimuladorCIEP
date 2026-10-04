$(document).ready(function() {


	var pt1height = $('#menu-left-base').height();

	$('#content').css('display', 'none');
	$('#content').fadeIn(300);




	$('.link-out').click(function() {
		event.preventDefault();
		newLocation = this.href;
		//$('#content').fadeOut(700, newpage);
		$('#content').fadeTo( 800, 0.20, newpage)
		$('#wrapper').hide( "scale", {percent: 20}, 800, newpage );
	});


	

	$('.link-in').click(function() {
		event.preventDefault();
		newLocation = this.href;
		$('#content').delay(800).fadeTo( 500, 0.0, newpage)
		$(".tabla").animate({opacity:0}, 0 )
		$(".crumbs").animate({opacity:0}, 0 )
		$(this).closest('.tabla').animate({zIndex: "200", opacity:1,}, 0 )
								 .animate({left: "1.5%", top: "0%", width: "98.5%", height: pt1height -112,}, 800)
								 //$("#wrapper").delay(1000).hide( "scale", {percent: 200,}, 800 );
								 ;
	});



	function newpage() {
		
		window.location = newLocation;
		
	}


});


<!-- Auto selección de inputs-->
$(document).ready( function() {
	$("input[type=text]").click( function() {
		$(this).select();
	});
});

<!-- Elimina title-->
$(document).ready( function() {
	$("#menu-left-otros-parametros").attr('title', '');
});



<!-- Info collapsible -->
$(document).ready( function() {
    $( "#accordion" ).accordion({
      collapsible: true,
	  active: false
    });
	
<!-- Tooltips -->
  $( document ).tooltip({
	track: true
  });	

<!-- TABS -->
  $( "#tabs" ).tabs();
});




<!-- Efectos opacidad -->
$(document).ready(function() {
	
	
	$('#logo').css('opacity', 1);
	
	$("#logo").hover(
	   function(){ 
		  $(this).animate({opacity: 0.6}, 150);
	   },  
	   function(){  
		  $(this).animate({opacity: 1}, 150);  
	   });

	$(".pulse").mouseover(function(){ 
		  //$(this).animate({opacity: 0}, 100).delay( 100 ).animate({opacity: 1}, 100);
		  //$(this).animate({'background-color': "#78cfb8"}, 100).delay( 100 ).animate({'background-color': "#43484c"}, 100);
	   });  
}); 


<!-- CARGANDO -->
        $(document).ready(function() {
        
        $( "#btn-toggle" ).click(function() {
            $( this ).toggleClass( "btn-activo" );
          $( "#iframeMenu" ).toggleClass( "blur" );
		  $( "#content" ).toggleClass( "blur" );
		  $( "#top" ).toggleClass( "hide-elements" );
		  $( "#cargador" ).toggleClass( "visible" );
		  $( "#trama-negra" ).toggleClass( "visible" );
        });
        });

<!-- ERROR -->
        $(document).ready(function() {
        
        $( "#error-btn" ).click(function() {
            $( this ).toggleClass( "btn-activo" );
          $( "#iframeMenu" ).toggleClass( "blur" );
		  $( "#content" ).toggleClass( "blur" );
		  $( "#top" ).toggleClass( "hide-elements" );
		  $( "#error" ).toggleClass( "visible" );
		  $( "#trama-negra" ).toggleClass( "visible" );
		  setTimeout(function() {
			  $( this ).toggleClass( "btn-activo" );
			  $( "#iframeMenu" ).toggleClass( "blur" );
			  $( "#content" ).toggleClass( "blur" );
			  $( "#top" ).toggleClass( "hide-elements" );
			  $( "#error" ).toggleClass( "visible" );
			  $( "#trama-negra" ).toggleClass( "visible" );
          },3000);
        });
        });

