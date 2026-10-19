*! version 8.12 CIEP 18oct2026
* bytes de un archivo sin leerlo (fseek al final): sirve para master/PEF.dta (1.7 GB)
program define _precache_bytes, rclass
	version 17
	args f
	mata: _precache_fsize(st_local("f"))
	return local bytes "`bytes'"
end

mata:
void _precache_fsize(string scalar f)
{
	real scalar fh, n
	fh = fopen(f, "r")
	fseek(fh, 0, 1)
	n = ftell(fh)
	fclose(fh)
	st_local("bytes", strtrim(sprintf("%21.0f", n)))
}
end
