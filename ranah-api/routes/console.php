<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Schedule::command('ranah:sync-bmkg --feed=earthquakes')
    ->cron(config('bmkg.schedules.earthquakes', '*/5 * * * *'))
    ->withoutOverlapping()
    ->onOneServer();

Schedule::command('ranah:sync-bmkg --feed=weather-alerts')
    ->cron(config('bmkg.schedules.weather_alerts', '*/5 * * * *'))
    ->withoutOverlapping()
    ->onOneServer();

Schedule::command('ranah:sync-bmkg --feed=forecasts')
    ->cron(config('bmkg.schedules.forecasts', '15 0,12 * * *'))
    ->timezone(config('bmkg.schedules.forecast_timezone', 'Asia/Jakarta'))
    ->withoutOverlapping()
    ->onOneServer();

Schedule::command('ranah:sync-magma')
    ->everySixHours()
    ->withoutOverlapping();

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');
