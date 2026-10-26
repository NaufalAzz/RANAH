<?php

return [
    'paths' => [
        'api/notifikasi',
        'api/berita',
        'api/berita/*',
        'api/gunung',
        'api/gunung/*',
        'api/pengaduan',
    ],
    'allowed_methods' => ['GET', 'POST', 'OPTIONS'],
    'allowed_origins' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env(
            'RANAH_CORS_ALLOWED_ORIGINS',
            'http://localhost:5000,http://127.0.0.1:5000',
        )),
    ))),
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['Accept', 'Content-Type', 'Origin'],
    'exposed_headers' => [],
    'max_age' => 600,
    'supports_credentials' => false,
];
