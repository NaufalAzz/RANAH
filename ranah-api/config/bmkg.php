<?php

return [
    'schedules' => [
        'earthquakes' => env('BMKG_EARTHQUAKE_CRON', '*/5 * * * *'),
        'weather_alerts' => env('BMKG_WEATHER_ALERT_CRON', '*/5 * * * *'),
        'forecasts' => env('BMKG_FORECAST_CRON', '15 0,12 * * *'),
        'forecast_timezone' => env('BMKG_FORECAST_TIMEZONE', 'Asia/Jakarta'),
    ],
    // Populate only with ADM4/name pairs verified through an official BMKG
    // area page or an applicable Kemendagri code decision. No location is guessed.
    'weather_areas' => (static function (): array {
        $decoded = json_decode((string) env('BMKG_WEATHER_ADM4_AREAS', '[]'), true);

        return is_array($decoded) ? $decoded : [];
    })(),
    'forecast_cache_hours' => (int) env('BMKG_FORECAST_CACHE_HOURS', 48),
    'forecast_stale_hours' => (int) env('BMKG_FORECAST_STALE_HOURS', 18),
    'sumatera_barat' => [
        // A recent earthquake window is a notification policy, not an official
        // BMKG expiry period. Override through BMKG_NOTIFICATION_EARTHQUAKE_DAYS.
        'earthquake_notification_days' => (int) env('BMKG_NOTIFICATION_EARTHQUAKE_DAYS', 7),
        'localities' => [
            'Kepulauan Mentawai', 'Kep. Mentawai', 'Mentawai',
            'Pesisir Selatan', 'PesisirSelatan', 'Pessel',
            'Padang Pariaman', 'PadangPariaman',
            'Lima Puluh Kota', 'LimaPuluhKota', '50 Kota',
            'Pasaman Barat', 'PasamanBarat', 'Pasaman',
            'Solok Selatan', 'SolokSelatan', 'Solok',
            'Tanah Datar', 'TanahDatar', 'Dharmasraya', 'Sijunjung', 'Agam',
            'Kota Padang Panjang', 'Padang Panjang', 'PadangPanjang',
            'Kota Sawahlunto', 'Sawahlunto', 'Kota Bukittinggi', 'Bukittinggi',
            'Kota Payakumbuh', 'Payakumbuh', 'Kota Pariaman', 'Pariaman',
        ],
    ],
];
