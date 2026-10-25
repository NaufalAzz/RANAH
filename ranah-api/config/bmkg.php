<?php

return [
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
