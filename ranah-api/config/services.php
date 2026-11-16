<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'openrouteservice' => [
        'api_key' => env('ORS_API_KEY'),
        'foot_walking_url' => 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson',
    ],

    'routing' => [
        'provider' => env('ROUTING_PROVIDER', 'ors'),
        'valhalla_base_url' => env('VALHALLA_BASE_URL', 'https://valhalla1.openstreetmap.de'),
        'valhalla_client_id' => env('VALHALLA_CLIENT_ID', 'RANAH-AcademicPrototype/1.0'),
    ],

];
