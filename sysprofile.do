if "`c(os)'" == "MacOSX" {
	sysdir set SITE "/Users/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
	sysdir set PERSONAL "/Users/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
}
if "`c(os)'" == "Unix" {
	sysdir set SITE "/home/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
	sysdir set PERSONAL "/home/`c(username)'/CIEP Dropbox/SimuladorCIEP/"
}
if "`c(os)'" == "Windows" {
	sysdir set SITE "C:\Users\\`c(username)'\CIEP Dropbox\SimuladorCIEP\"
	sysdir set PERSONAL "C:\Users\\`c(username)'\CIEP Dropbox\SimuladorCIEP\"
}
adopath ++PERSONAL
