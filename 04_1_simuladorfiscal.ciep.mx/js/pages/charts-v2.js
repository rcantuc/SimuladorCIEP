$(document).ready(function() {
    
    /*"use strict";* /
	
	
	
	
	var options2 = {
            chart: {
				width: '100%',
				toolbar: {
					show: false,
					offsetX: 0,
					offsetY: 0,
					export: {
					  csv: {
						filename: undefined,
						columnDelimiter: ',',
						headerCategory: 'category',
						headerValue: 'value',
						dateFormatter(timestamp) {
						  return new Date(timestamp).toDateString()
						}
					  }
					},
				},
                height: 235,
                type: 'area',
				zoom: {
                    enabled: false
                }
            },
			legend: {
				position: 'top',
				horizontalAlign: 'left'
			},
			annotations: {
			  xaxis: [
				{
				  x: 6,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
			},
			colors: ['#008ffb', '#feb019'],
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth'
            },
            series: [{
                name: 'PIB Reportado',
                data: [11, 11.5, 12, 13, 14, 15, null, null, null, null, null]
            }, {
                name: 'PIB Proyectado',
                data: [null, null, null, null, null, 15, 15, 15, 15, 15, 15]
            }],

            xaxis: {
                categories: [2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025],
                labels: {
			      rotate: -45,
                  rotateAlways: true,
                  style: {
                    colors: 'rgba(94, 96, 110, .9)'
                  }
                }           
            },
			yaxis: {
			  axisBorder: {
				show: false
			  },
			  axisTicks: {
				show: false,
			  },
			  labels: {
				show: false,
				formatter: function (val) {
				  return val + "%";
				}
			  }
			
			},
            grid: {
              borderColor: 'rgba(94, 96, 110, .5)',
              strokeDashArray: 4
            }
        }

        var chart2 = new ApexCharts(
            document.querySelector("#chart-0"),
            options2
        );

        chart2.render();
	
	
	/*

		
		var options2 = {
            chart: {
				width: '100%',
				toolbar: {
					show: false,
					offsetX: 0,
					offsetY: 0,
					export: {
					  csv: {
						filename: undefined,
						columnDelimiter: ',',
						headerCategory: 'category',
						headerValue: 'value',
						dateFormatter(timestamp) {
						  return new Date(timestamp).toDateString()
						}
					  }
					},
				},
                height: 260,
                type: 'area',
				zoom: {
                    enabled: false
                }
            },
			legend: {
				position: 'top',
				horizontalAlign: 'left'
			},
			annotations: {
			  xaxis: [
				{
				  x: 6,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
			},
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth'
            },
            series: [{
                name: 'Reportado',
                data: [15, 17, 19, 21, 23, 25, null, null, null, null, null]
            }, {
                name: 'Estimado',
                data: [null, null, null, null, null, 23, 25, null, null, null, null]
            }, {
                name: 'Proyectado',
                data: [null, null, null, null, null, null, 25, 26, 26, 27, 27]
            }],

            xaxis: {
                categories: [1995, 2000, 2005, 2010, 2015, 2020, 2025, 2030, 2035, 2040, 2045],
                labels: {
			      rotate: -45,
                  rotateAlways: true,
                  style: {
                    colors: 'rgba(94, 96, 110, .9)'
                  }
                }           
            },
			yaxis: {
			  axisBorder: {
				show: false
			  },
			  axisTicks: {
				show: false,
			  },
			  labels: {
				show: false,
				formatter: function (val) {
				  return val + "%";
				}
			  }
			
			},
            grid: {
              borderColor: 'rgba(94, 96, 110, .5)',
              strokeDashArray: 4
            }
        }

        var chart2 = new ApexCharts(
            document.querySelector("#pib-0"),
            options2
        );

        chart2.render();
		
		
		
		
		
		
		
     var options2 = {
            chart: {
				toolbar: {
					show: true,
					offsetX: 200,
					offsetY: 0,
					export: {
					  csv: {
						filename: undefined,
						columnDelimiter: ',',
						headerCategory: 'category',
						headerValue: 'value',
						dateFormatter(timestamp) {
						  return new Date(timestamp).toDateString()
						}
					  }
					},
				},
                height: 430,
                type: 'area',
				zoom: {
                    enabled: false
                }
            },
			legend: {
				position: 'top',
				horizontalAlign: 'left',
				fontSize: '15px',
				offsetX: -2,
				offsetY: -5,
				markers: {
				  width: 14,
				  height: 14,
				  offsetX: 20,
				  radius: 14
				},
				itemMargin: {
					horizontal: 15
				}
			},
			annotations: {
			  xaxis: [
				{
				  x: 11,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
			},
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth'
            },
            series: [{
                name: 'Reportado',
                data: [ 13.366, 14.666, 15.818, 16.277, 17.484, 18.572, 20.129, 21.934, 23.525, 24.238, 22.131, null, null, null, null, null, null, null, null, null, null]

            }, {
                name: 'Simulado',
                data: [ null, null, null, null, null, null, null, null, null, null, 23.094, 24.984, 26.511, 28.105, 29.794, 31.585, null, null, null, null, null]

            }, {
                name: 'Proyectado',
                data: [ null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 31.585, 33.298, 35.052, 36.854, 38.695, 40.613]

            }],

            xaxis: {
                categories: [2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030],
                labels: {
			      rotate: -15,
                  rotateAlways: true,
                  style: {
                    colors: 'rgba(94, 96, 110, .9)'
                  }
                }           
            },
            grid: {
              borderColor: 'rgba(94, 96, 110, .5)',
              strokeDashArray: 4
            }
        }

        var chart2 = new ApexCharts(
            document.querySelector("#pib-2"),
            options2
        );

        chart2.render();
		




		var options = {
            chart: {
                height: 380,
                type: 'line',
                zoom: {
                    enabled: false
                }
            },
            series: [{
                name: "billones MXN de 2021",
                data: [ 0.308, 0.381, 0.483, 0.666, 0.953, 1.278, 1.577, 1.803, 1.847, 1.751, 1.539]
            }],
			annotations: {
			  xaxis: [
				{
				  x: 8,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
			},
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth'
            },
            grid: {
                borderColor: 'rgba(94, 96, 110, .5)',
                strokeDashArray: 4
            },
            xaxis: {
                categories: [1950, 1960, 1970, 1980, 1990, 2000, 2010, 2020, 2030, 2040, 2050],
                labels: {
                  style: {
                    colors: 'rgba(94, 96, 110, 1.0)'
                  }
                }
            }
        }

        var chart = new ApexCharts(
            document.querySelector("#line-1"),
            options
        );

        chart.render();
		
		
		
		
	
	var options = {
          series: [{
          name: 'Impuestos al consumo',
          data: [ 0.832, 0.720, 0.679, 0.809, 1.084, 1.432, 1.539, 1.424, 1.465, 1.547, 1.391, 1.550, 1.559, 1.568, 1.576, 1.584, 1.591, 1.598, 1.604, 1.609, 1.614]
        }, {
          name: 'Impuestos laborales',
          data: [ 0.818, 0.834, 0.897, 0.938, 0.949, 1.082, 1.152, 1.195, 1.225, 1.241, 1.121, 1.315, 1.325, 1.333, 1.341, 1.348, 1.355, 1.361, 1.366, 1.370, 1.374]
        }, {
          name: 'Impuestos e ingresos de capital',
          data: [ 2.824, 3.128, 3.255, 3.384, 3.163, 2.932, 3.162, 2.980, 2.822, 2.825, 3.227, 2.642, 2.674, 2.705, 2.736, 2.766, 2.795, 2.823, 2.850, 2.876, 2.902]
        }],
          chart: {
	      stacked: true,
          height: 390,
          type: 'area'
        },
		legend: {
				position: 'top',
				horizontalAlign: 'left',
				fontSize: '15px',
				offsetX: -2,
				offsetY: -5,
				markers: {
				  width: 14,
				  height: 14,
				  offsetX: 20,
				  radius: 14
				},
				itemMargin: {
					horizontal: 15
				}
		},
		annotations: {
			  xaxis: [
				{
				  x: 11,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
		},
        dataLabels: {
          enabled: false
        },
        stroke: {
          curve: 'smooth'
        },
        xaxis: {
                categories: [2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030],
        },
        tooltip: {
          x: {
            format: 'dd/MM/yy HH:mm'
          },
        },
        };

        var chart = new ApexCharts(document.querySelector("#stacked1"), options);
        chart.render();
	
	



	var options = {
          series: [{
          name: 'Renta básica',
          data: [ 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000]
        }, {
          name: 'Pensión bienestar',
          data: [ 0.034, 0.048, 0.051, 0.047, 0.042, 0.039, 0.128, 0.145, 0.150, 0.154, 0.159, 0.165, 0.170, 0.176, 0.182, 0.188, 0.195, 0.202]

        }, {
          name: 'Otros gastos',
          data: [ 3.202, 3.301, 3.395, 3.631, 3.153, 3.131, 3.012, 2.834, 2.844, 2.852, 2.860, 2.866, 2.872, 2.877, 2.881, 2.884, 2.886, 2.887]
        }, {
          name: 'Amortización',
          data: [ 0.001, 0.000, 0.000, 0.000, 0.000, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001]
        }, {
          name: 'Costo de la deuda',
          data: [ 0.471, 0.504, 0.568, 0.617, 0.668, 0.762, 0.742, 0.749, 0.749, 0.731, 0.772, 0.815, 0.860, 0.907, 0.956, 1.007, 1.062, 1.119]
        }, {
          name: 'Salud',
          data: [ 0.641, 0.647, 0.665, 0.649, 0.642, 0.634, 0.630, 0.636, 0.641, 0.645, 0.650, 0.654, 0.659, 0.663, 0.667, 0.672, 0.676, 0.680]
        }, {
          name: 'Pensiones',
          data: [ 0.647, 0.696, 0.758, 0.791, 0.807, 0.863, 0.923, 1.030, 1.058, 1.086, 1.114, 1.143, 1.171, 1.200, 1.228, 1.256, 1.284, 1.311]
        }, {
          name: 'Educación',
          data: [ 0.881, 0.903, 0.938, 0.903, 0.835, 0.825, 0.833, 0.817, 0.811, 0.805, 0.798, 0.791, 0.784, 0.776, 0.769, 0.761, 0.752, 0.744]
        }],
          chart: {
	      stacked: true,
          height: 400,
          type: 'area'
        },
		legend: {
				position: 'top',
				horizontalAlign: 'left',
				fontSize: '15px',
				offsetX: -2,
				offsetY: -5,
				markers: {
				  width: 14,
				  height: 14,
				  radius: 14
				},
				itemMargin: {
					horizontal: 5
				}
		},
		annotations: {
			  xaxis: [
				{
				  x: 8,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
		},
        dataLabels: {
          enabled: false
        },
        stroke: {
          curve: 'smooth'
        },
        xaxis: {
                categories: [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030],
        },
        tooltip: {
          x: {
            format: 'dd/MM/yy HH:mm'
          },
        },
        };

        var chart = new ApexCharts(document.querySelector("#stacked2"), options);
        chart.render();
		
		
		
		
		
		var options = {
          series: [{
          name: 'Reportado',
          data: [ 36.010, 37.166, 37.242, 39.960, 42.587, 46.486, 48.673, 45.736, 44.854, 44.848, 54.339, null, null, null, null, null, null, null, null, null, null]


        }, {
          name: 'Proyectado',
          data: [ null, null, null, null, null, null, null, null, null, null, 54.339, 57.368, 60.269, 63.314, 66.519, 69.898, 73.470, 77.250, 81.254, 85.501, 90.009]

        }],
          chart: {
          height: 380,
          type: 'area'
        },
		annotations: {
			  xaxis: [
				{
				  x: 11,
				  strokeDashArray: 0,
				  borderColor: '#775DD0',
				  label: {
					  borderColor: '#775DD0',
					  style: {
						color: '#fff',
						background: '#775DD0',
					  },
					  text: 'HOY',
				  }
				}
			  ]
		},
        dataLabels: {
          enabled: false
        },
        stroke: {
          curve: 'smooth'
        },
        xaxis: {
                categories: [2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030],
        },
        tooltip: {
          x: {
            format: 'dd/MM/yy HH:mm'
          },
        },
        };

        var chart = new ApexCharts(document.querySelector("#area2"), options);
        chart.render();
	*/	
		
		
		
		
		
		/*
		
		var options = {
          series: [
	{
          name: 'I-V',
          data: [ 0.002, -0.000, 0.210, 0.259, 0.801, 1.744, 2.160, 3.036, 2.850, 2.387, -0.160, -0.651, -2.179, -2.976, -3.310, -3.363, -3.234, -1.464, 2.461, 7.357, 8.459, 2.625]

        },
	{
          name: 'VI-IX',
          data: [ 0.002, 0.012, 0.141, 0.229, 1.060, 1.586, 2.653, 4.293, 5.028, 2.637, -2.572, -5.265, -7.116, -7.568, -8.135, -8.008, -7.704, -4.216, 0.410, 3.307, 3.294, 1.154]

        },
        {
          name: 'X',
          data: [ -0.007, 0.013, -0.133, 0.125, -0.274, -0.219, -0.533, -2.463, -3.275, -5.168, -9.288, -8.154, -6.303, -8.059, -5.953, -5.947, -2.633, -1.042, 0.059, 0.112, -0.032]


        }
        ],
          chart: {
          type: 'bar',
          height: 440,
          stacked: true
        },
        plotOptions: {
          bar: {
            horizontal: true,
            barHeight: '80%',
        
          },
        },
        dataLabels: {
          enabled: false
        },
        stroke: {
          width: 1,
          colors: ["#fff"]
        },
        
        grid: {
          xaxis: {
            lines: {
              show: false
            }
          }
        },
        yaxis: {
          min: -20,
          max: 20,
          title: {
            // text: 'Age',
          },
        },
        tooltip: {
          shared: false,
          x: {
            formatter: function (val) {
              return val
            }
          },
          y: {
            formatter: function (val) {
              return Math.abs(val) + "%"
            }
          }
        },
        xaxis: {
          categories: ['.', '.', '.', '.', '.', '.', '.', '.',
            '.', '.', '.', '.', '.', '.', '.', '.', '.',
            '.'
          ],
		  labels: {
			      style: {
					  colors: '#f5f8fa'
				  },
          }, 
          title: {
            text: 'HOMBRES'
          },

        },
        };

        var chart = new ApexCharts(document.querySelector("#chart-duo-pt1"), options);
        chart.render();
		
		
		
		
		
		var options = {
          series: [{
          name: 'I-V',
          data: [ -0.004, -0.016, -0.106, -0.112, -0.708, -0.910, -1.688, -2.065, -1.888, -1.006, -0.329, 0.302, 0.577, 1.370, 1.577, 1.571, 1.574, 0.402, -2.738, -6.937, -8.053, -2.591]


        },
        {
          name: 'VI-IX',
          data: [ -0.000, -0.011, -0.040, -0.260, -0.982, -1.225, -1.671, -2.134, -2.907, -1.913, 0.365, 2.482, 4.502, 5.544, 5.415, 5.810, 5.372, 2.514, -1.011, -3.176, -3.458, -1.049]


        },
        {
          name: 'X',
          data: [ 0.009, -0.016, -0.262, 0.004, 0.277, 0.222, 0.513, 1.135, 2.812, 3.698, 4.792, 4.831, 4.803, 7.162, 4.779, 3.374, 3.639, 1.108, -0.019, -0.194, 0.009]


        }
        ],
          chart: {
          type: 'bar',
          height: 440,
          stacked: true
        },
        plotOptions: {
          bar: {
            horizontal: true,
            barHeight: '80%',
			dataLabels: {
              position: 'top', // top, center, bottom
            },
          },
        },
        dataLabels: {
          enabled: false
        },
        stroke: {
          width: 1,
          colors: ["#fff"]
        },
        
        grid: {
          xaxis: {
            lines: {
              show: false
            }
          }
        },
        yaxis: {
          min: -20,
          max: 20,
          title: {
            // text: 'Age',
          },
        },
        tooltip: {
          shared: false,
          x: {
            formatter: function (val) {
              return val
            }
          },
          y: {
            formatter: function (val) {
              return Math.abs(val) + "%"
            }
          }
        },
        xaxis: {
          categories: ['105-109','100-104','95-99','90-94','85-89', '80-84', '75-79', '70-74', '65-69', '60-64', '55-59', '50-54',
            '45-49', '40-44', '35-39', '30-34', '25-29', '20-24', '15-19', '10-14', '5-9', '0-4'
          ],
		  labels: {
			      style: {
					  colors: '#f5f8fa'
				  },
          }, 
          title: {
            text: 'MUJERES'
          }
        },
        };

        var chart = new ApexCharts(document.querySelector("#chart-duo-pt2"), options);
        chart.render();
		
	*/	


});








/*

const dataSource = {
  chart: {
    caption: "El sistema fiscal mexicano",
    subcaption:
      "De la recaudación al gasto público",
    theme: "fusion",
    orientation: "horizontal",
    linkalpha: 30,
    linkhoveralpha: 60,
    nodelabelposition: "start"
  },

nodes:[{label:"I"},{label:"Laboral"},{label:" Consumo"},{label:" FMP"},{label:"  De Capital"},{label:"II"},{label:"III"},{label:"IV"},{label:"V"},{label:"VI"},{label:"VII"},{label:"VIII"},{label:"IX"},{label:"X"},{label:"OyE estatales"},{label:"Otros ingresos"},{label:"Futuro"},{label:"Endeudamiento"},{label:"Sistema Fiscal"},{label:"Educacion"},{label:"Salud"},{label:" Salarios de gobiern"},{label:"  Pension Bienestar"},{label:"  Pensiones"},{label:"   Infraestructura"},{label:"Otros gastos"},{label:"Otras Part y Aport"},{label:"Costo de la deuda"},{label:" I"},{label:" II"},{label:" III"},{label:" IV"},{label:" V"},{label:" VI"},{label:" VII"},{label:" VIII"},{label:" IX"},{label:" X"},{label:"No distribuibles"},{label:"Estados y municipios"},{label:"Sistema financiero"}],
links:[{to:"Laboral",value:.0450708925339908,from:"I"},{to:" Consumo",value:.2067735091231806,from:"I"},{to:" FMP",value:.1373581524014372,from:"I"},{to:"  De Capital",value:.0058601675482431,from:"I"},{to:"Laboral",value:.1312360580810107,from:"II"},{to:" Consumo",value:.2754900129937589,from:"II"},{to:" FMP",value:.137246214404676,from:"II"},{to:"  De Capital",value:.0173446467038147,from:"II"},{to:"Laboral",value:.2113786529638114,from:"III"},{to:" Consumo",value:.334032059560496,from:"III"},{to:" FMP",value:.1373021142069581,from:"III"},{to:"  De Capital",value:.0338103748293244,from:"III"},{to:"Laboral",value:.2869952930175039,from:"IV"},{to:" Consumo",value:.3854121940192969,from:"IV"},{to:" FMP",value:.1373186999795641,from:"IV"},{to:"  De Capital",value:.0590372103354025,from:"IV"},{to:"Laboral",value:.3800871371265194,from:"V"},{to:" Consumo",value:.4510840110280894,from:"V"},{to:" FMP",value:.1373097151322723,from:"V"},{to:"  De Capital",value:.0902587632308525,from:"V"},{to:"Laboral",value:.5079587902491054,from:"VI"},{to:" Consumo",value:.5564071931013828,from:"VI"},{to:" FMP",value:.1372855497254581,from:"VI"},{to:"  De Capital",value:.1203737399848889,from:"VI"},{to:"Laboral",value:.6062798272942015,from:"VII"},{to:" Consumo",value:.6348695466983407,from:"VII"},{to:" FMP",value:.1372838996646398,from:"VII"},{to:"  De Capital",value:.1745218745570071,from:"VII"},{to:"Laboral",value:.7567586975781447,from:"VIII"},{to:" Consumo",value:.7649212159888874,from:"VIII"},{to:" FMP",value:.1373250873117613,from:"VIII"},{to:"  De Capital",value:.2699320996150402,from:"VIII"},{to:"Laboral",value:.9284838687116871,from:"IX"},{to:" Consumo",value:.9534194269841919,from:"IX"},{to:" FMP",value:.1372850387388838,from:"IX"},{to:"  De Capital",value:.4709798874817501,from:"IX"},{to:"Laboral",value:1.44075078244403,from:"X"},{to:" Consumo",value:1.676590830502387,from:"X"},{to:" FMP",value:.137285528434349,from:"X"},{to:"  De Capital",value:2.631881235713661,from:"X"},{to:"  De Capital",value:4.309999999955918,from:"OyE estatales"},{to:"  De Capital",value:1.078999999988964,from:"Otros ingresos"},{to:"Endeudamiento",value:2.801022433445626,from:"Futuro"},{to:"Sistema Fiscal",value:5.295000000000006,from:"Laboral"},{to:"Sistema Fiscal",value:6.239000000000011,from:" Consumo"},{to:"Sistema Fiscal",value:1.373,from:" FMP"},{to:"Sistema Fiscal",value:9.262999999944869,from:"  De Capital"},{to:"Sistema Fiscal",value:2.801022433445626,from:"Endeudamiento"},{to:"Educacion",value:3.238228451835507,from:"Sistema Fiscal"},{to:"Salud",value:2.558162290498633,from:"Sistema Fiscal"},{to:" Salarios de gobiern",value:1.731724848957366,from:"Sistema Fiscal"},{to:"  Pension Bienestar",value:.5974199676950477,from:"Sistema Fiscal"},{to:"  Pensiones",value:4.22329611898251,from:"Sistema Fiscal"},{to:"   Infraestructura",value:1.710225456803607,from:"Sistema Fiscal"},{to:"Otros gastos",value:3.310394501391452,from:"Sistema Fiscal"},{to:"Otras Part y Aport",value:4.600869920907124,from:"Sistema Fiscal"},{to:"Costo de la deuda",value:3.000700876319266,from:"Sistema Fiscal"},{to:" I",value:.3862273332084152,from:"Educacion"},{to:" II",value:.3710969524720789,from:"Educacion"},{to:" III",value:.3582234747008229,from:"Educacion"},{to:" IV",value:.3576194103484305,from:"Educacion"},{to:" V",value:.336536774797833,from:"Educacion"},{to:" VI",value:.3194961639943569,from:"Educacion"},{to:" VII",value:.3019458881912863,from:"Educacion"},{to:" VIII",value:.2976647038425972,from:"Educacion"},{to:" IX",value:.2798771969065429,from:"Educacion"},{to:" X",value:.2295405533731432,from:"Educacion"},{to:" I",value:.188967145084884,from:"Salud"},{to:" II",value:.219271526957392,from:"Salud"},{to:" III",value:.2398947049804087,from:"Salud"},{to:" IV",value:.2533062596571522,from:"Salud"},{to:" V",value:.2658536981569878,from:"Salud"},{to:" VI",value:.2780031371002462,from:"Salud"},{to:" VII",value:.2790786717710453,from:"Salud"},{to:" VIII",value:.2810539707934077,from:"Salud"},{to:" IX",value:.2805917078933915,from:"Salud"},{to:" X",value:.2721414681037179,from:"Salud"},{to:" I",value:.0067650697102797,from:" Salarios de gobiern"},{to:" II",value:.0207031369259144,from:" Salarios de gobiern"},{to:" III",value:.050854492367738,from:" Salarios de gobiern"},{to:" IV",value:.0622595879759627,from:" Salarios de gobiern"},{to:" V",value:.0966390393475498,from:" Salarios de gobiern"},{to:" VI",value:.1483819310657743,from:" Salarios de gobiern"},{to:" VII",value:.2112396339724666,from:" Salarios de gobiern"},{to:" VIII",value:.2201721560701043,from:" Salarios de gobiern"},{to:" IX",value:.3706493860279179,from:" Salarios de gobiern"},{to:" X",value:.5440604154936589,from:" Salarios de gobiern"},{to:" I",value:.0213634088283454,from:"  Pension Bienestar"},{to:" II",value:.034392813458987,from:"  Pension Bienestar"},{to:" III",value:.046285199219999,from:"  Pension Bienestar"},{to:" IV",value:.0586600652453621,from:"  Pension Bienestar"},{to:" V",value:.0613306257694841,from:"  Pension Bienestar"},{to:" VI",value:.0718785906690733,from:"  Pension Bienestar"},{to:" VII",value:.0751996751038523,from:"  Pension Bienestar"},{to:" VIII",value:.0742277605505377,from:"  Pension Bienestar"},{to:" IX",value:.0776317197528635,from:"  Pension Bienestar"},{to:" X",value:.0764501090965434,from:"  Pension Bienestar"},{to:" I",value:.096012827425342,from:"  Pensiones"},{to:" II",value:.2168703831074754,from:"  Pensiones"},{to:" III",value:.2511038261112665,from:"  Pensiones"},{to:" IV",value:.3058403096024896,from:"  Pensiones"},{to:" V",value:.3784873826786764,from:"  Pensiones"},{to:" VI",value:.4603374860057216,from:"  Pensiones"},{to:" VII",value:.5124916345590241,from:"  Pensiones"},{to:" VIII",value:.6473064084773166,from:"  Pensiones"},{to:" IX",value:.6734942327988545,from:"  Pensiones"},{to:" X",value:.6813516282163441,from:"  Pensiones"},{to:" I",value:.151219136151058,from:"   Infraestructura"},{to:" II",value:.1599751867365014,from:"   Infraestructura"},{to:" III",value:.1636170154395995,from:"   Infraestructura"},{to:" IV",value:.1618158767138534,from:"   Infraestructura"},{to:" V",value:.1643928970844252,from:"   Infraestructura"},{to:" VI",value:.1660453166814206,from:"   Infraestructura"},{to:" VII",value:.1885560823087728,from:"   Infraestructura"},{to:" VIII",value:.1818105736718492,from:"   Infraestructura"},{to:" IX",value:.1897678409588023,from:"   Infraestructura"},{to:" X",value:.1830255310573243,from:"   Infraestructura"},{to:"No distribuibles",value:8.310394501391452,from:"Otros gastos"},{to:"Estados y municipios",value:8.600869920907124,from:"Otras Part y Aport"},{to:"Sistema financiero",value:6.000700876319266,from:"Costo de la deuda"}]};

FusionCharts.ready(function() {
  var myChart = new FusionCharts({
    type: "sankey",
    renderAt: "sankey-1",
    width: "100%",
    height: "100%",
    dataFormat: "json",
    dataSource
  }).render();
});

*/
