<?php

namespace Tests\Feature;

use Tests\TestCase;

class WebApiCorsTest extends TestCase
{
    public function test_local_web_origin_can_preflight_public_get_endpoints(): void
    {
        foreach ([
            '/api/notifikasi',
            '/api/berita',
            '/api/berita/11/gambar',
            '/api/gunung',
        ] as $path) {
            $this->withHeaders([
                'Origin' => 'http://localhost:5000',
                'Access-Control-Request-Method' => 'GET',
            ])->options($path)
                ->assertNoContent()
                ->assertHeader('Access-Control-Allow-Origin', 'http://localhost:5000');
        }
    }

    public function test_unconfigured_origin_is_not_granted_cors_access(): void
    {
        $response = $this->withHeaders([
            'Origin' => 'https://unconfigured.example',
            'Access-Control-Request-Method' => 'GET',
        ])->options('/api/notifikasi');

        $response->assertNoContent();
        self::assertFalse($response->headers->has('Access-Control-Allow-Origin'));
    }

    public function test_local_web_origin_can_preflight_complaint_submission(): void
    {
        $this->withHeaders([
            'Origin' => 'http://localhost:5000',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'content-type',
        ])->options('/api/pengaduan')
            ->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', 'http://localhost:5000')
            ->assertHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    }
}
