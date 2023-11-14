** Importar datos desde INEGI **
local series "`1'"
local series = subinstr("`series'"," ",",",.)

python
import requests
import pandas as pd
from bs4 import BeautifulSoup
from sfi import Macro

# Open the .iqy file and read the URL and parameters
url = 'http://www.inegi.org.mx/app/indicadores/exportacion.aspx'
params = 'cveser=&ag=00&bie=true&aamin=1993&aamax=9999&ordena=a&ordenaPeriodo=ap&orientacion=v&frecuencia=Todo&estadistico=false&esquema=&bdesplaza=False&FileFormat=iqy&subapp=Banco%20de%20Informaci%C3%B3n%20Econ%C3%B3mica%20(BIE)&tematica=0'

# Get the series from Stata
series = Macro.getLocal('series')

# Add the series to the parameters
params = params.replace('cveser=', 'cveser=' + series)

# Split the parameters into a dictionary
params_dict = dict(x.split('=') for x in params.split('&'))

# Split the 'cveser' parameter into a list of items
cveser_items = params_dict['cveser'].split(',')

# Make a request for each item in 'cveser'
for item in cveser_items:
	# Update the 'cveser' parameter with the current item
	params_dict['cveser'] = item

	# Combine the URL and updated parameters into a complete URL
	complete_url = url + '?' + '&'.join(f'{k}={v}' for k, v in params_dict.items())

	# Make a request to the URL
	response = requests.get(complete_url)

	# Parse the HTML content
	soup = BeautifulSoup(response.text, 'html.parser')

	# Find the table with the data
	table = soup.find('table', {'id': 'tableContainerSinScroll'})

	# Extract the headers and rows from the table
	headers = [th.text.split(' > ')[-1] for th in table.find_all('th')]  # Keep only the last part of the header
	rows = [[td.text for td in tr.find_all('td')] for tr in table.find_all('tr')]

	# Create a pandas DataFrame from the headers and rows
	df = pd.DataFrame(rows, columns=headers)

	# Remove the first row
	df = df.drop(df.index[0])

	# Save the DataFrame to a .csv file named after the current 'cveser' item
	df.to_csv(f'{item}.csv', index=False)
end


** Ordenar datos para Stata **
local series = subinstr("`series'",","," ",.)
foreach k of local series {
	import delimited "`=c(sysdir_personal)'/SIM/BIE/`k'.csv", clear
	replace periodo = subinstr(periodo,"/p1","",.)
	tempfile `k'
	save ``k''
}
local j = 0
foreach k of local series {
	if `j' == 0 {
		use ``k''
		local ++j
	}
	else {
		merge 1:1 (periodos) using ``k'', nogen
	}
}
