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

    public function test_loopback_web_origin_can_use_an_unconfigured_development_port(): void
    {
        $this->withHeaders([
            'Origin' => 'http://127.0.0.1:59910',
            'Access-Control-Request-Method' => 'GET',
        ])->options('/api/notifikasi')
            ->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', 'http://127.0.0.1:59910');
    }

    public function test_local_web_origin_can_preflight_complaint_submission(): void
    {
        $response = $this->withHeaders([
            'Origin' => 'http://localhost:5000',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'content-type',
        ])->options('/api/pengaduan')
            ->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', 'http://localhost:5000')
            ->assertHeader('Access-Control-Allow-Headers', 'content-type');

        $methods = array_map(
            'trim',
            explode(',', (string) $response->headers->get('Access-Control-Allow-Methods')),
        );
        self::assertContains('POST', $methods);
        self::assertNotContains('PUT', $methods);
    }

    public function test_local_web_origin_can_preflight_hazard_analysis(): void
    {
        $response = $this->withHeaders([
            'Origin' => 'http://localhost:5000',
            'Access-Control-Request-Method' => 'POST',
            'Access-Control-Request-Headers' => 'content-type',
        ])->options('/api/peta/analisis-bahaya')
            ->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', 'http://localhost:5000');

        $methods = array_map(
            'trim',
            explode(',', (string) $response->headers->get('Access-Control-Allow-Methods')),
        );
        self::assertContains('POST', $methods);
        self::assertNotContains('PUT', $methods);
    }
}
