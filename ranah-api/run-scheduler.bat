@echo off
cd /d "%~dp0"
php artisan schedule:work
