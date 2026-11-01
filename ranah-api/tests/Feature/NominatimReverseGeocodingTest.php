<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class NominatimReverseGeocodingTest extends TestCase
{
    private function clearReverseCache(float $latitude, float $longitude): void
    {
        $cache = Cache::store('file');
        $coordinateKey = sprintf('%.5f,%.5f', $latitude, $longitude);
        $cache->forget('ranah:nominatim:reverse:' . hash('sha256', $coordinateKey));
        $cache->forget('ranah:nominatim:reverse:last-request');
        $cache->forget('ranah:nominatim:reverse:cooldown-until');
    }

    public function test_it_returns_a_single_reverse_geocode_response_and_caches_it(): void
    {
        $query = ['latitude' => -0.91234, 'longitude' => 100.41234];
        $this->clearReverseCache($query['latitude'], $query['longitude']);

        Http::fake([
            'nominatim.openstreetmap.org/reverse*' => Http::response([
                'display_name' => 'Jalan, Kelurahan, Kota Padang, Sumatera Barat',
                'address' => [
                    'road' => 'Jalan Contoh',
                    'suburb' => 'Kelurahan Contoh',
                    'district' => 'Kecamatan Contoh',
                    'city' => 'Kota Padang',
                    'state' => 'Sumatera Barat',
                ],
            ]),
        ]);

        $first = $this->getJson('/api/peta/alamat?' . http_build_query($query));
        $second = $this->getJson('/api/peta/alamat?' . http_build_query($query));

        $first->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.address.road', 'Jalan Contoh')
            ->assertJsonPath('data.address.district', 'Kecamatan Contoh')
            ->assertJsonPath('data.address.state', 'Sumatera Barat')
            ->assertJsonPath('data.sumber', 'Nominatim / OpenStreetMap')
            ->assertJsonPath('data.url_atribusi', 'https://www.openstreetmap.org/copyright');
        $second->assertJsonPath('data.display_name', 'Jalan, Kelurahan, Kota Padang, Sumatera Barat');

        Http::assertSentCount(1);
        Http::assertSent(fn ($request): bool =>
            str_contains($request->url(), 'https://nominatim.openstreetmap.org/reverse')
            && $request->hasHeader('User-Agent', 'RANAH/1.0 (' . config('app.url') . ')')
            && (string) $request['addressdetails'] === '1'
            && (string) $request['accept-language'] === 'id'
            && (string) $request['zoom'] === '18'
        );
    }

    public function test_invalid_coordinates_are_rejected_without_contacting_nominatim(): void
    {
        Http::fake();

        $this->getJson('/api/peta/alamat?latitude=91&longitude=100')
            ->assertUnprocessable();

        Http::assertNothingSent();
    }

    public function test_nominatim_rate_limit_is_returned_and_sets_a_short_cooldown(): void
    {
        $this->clearReverseCache(-1.23456, 100.12345);

        Http::fake([
            'nominatim.openstreetmap.org/reverse*' => Http::response([], 429, ['Retry-After' => '3']),
        ]);

        $this->getJson('/api/peta/alamat?latitude=-1.23456&longitude=100.12345')
            ->assertStatus(429)
            ->assertHeader('Retry-After', '3');
        $this->getJson('/api/peta/alamat?latitude=-1.23457&longitude=100.12346')
            ->assertStatus(429);

        Http::assertSentCount(1);
        Cache::store('file')->forget('ranah:nominatim:reverse:cooldown-until');
    }
}
