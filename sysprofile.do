if "`c(os)'" == "MacOSX" {
	sysdir set SITE "/Users/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
}
if "`c(os)'" == "Unix" {
	sysdir set SITE "/home/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
}


