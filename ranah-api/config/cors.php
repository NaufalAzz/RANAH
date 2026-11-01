<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['GET', 'POST', 'OPTIONS'],

    // Production frontend origins must be listed explicitly in the deployment
    // environment. Loopback origins are allowed on any local development port.
    'allowed_origins' => array_values(array_filter(
        array_map('trim', explode(',', (string) env(
            'RANAH_CORS_ALLOWED_ORIGINS',
            'http://localhost:5000,http://127.0.0.1:5000',
        ))),
        static fn (string $origin): bool => $origin !== '*'
            && preg_match('#^https?://[^/]+$#i', $origin) === 1,
    )),

    'allowed_origins_patterns' => [
        '#^https?://(?:localhost|127\\.0\\.0\\.1|\\[::1\\])(?::\\d+)?$#i',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 600,

    'supports_credentials' => false,
];
