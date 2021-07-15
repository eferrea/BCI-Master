:: Written by Kian Torab, changed by Gus Siska
@echo off
title NPlay Startup
start /min nplayserver -L
:: Don't actually need a choice, this just gives a 1 second delay between starting nplay and central.
::choice /n /c "K" /m "Please wait for a second..." /t 1 /d "K"
ping -n 2 127.0.0.1
start central
exit
