<?php

namespace Tests\Feature;

use App\Models\Berita;
use App\Services\BmkgInformationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class BmkgInformationTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_felt_quake_feed_imports_only_padang_impacts_and_deduplicates_sources(): void
    {
        Carbon::setTestNow('2026-10-24 03:00:00');
        Http::fake([
            'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json' => Http::response([
                'Infogempa' => ['gempa' => [
                    $this->earthquake('III-IV Kota Padang, II Pariaman'),
                    $this->earthquake('III Kab. Padang Pariaman'),
                    $this->earthquake('III Kota Bengkulu'),
                ]],
            ]),
            'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json' => Http::response([
                'Infogempa' => ['gempa' => $this->earthquake(
                    'III Kota Padang, II Pariaman',
                    'Berpotensi tsunami',
                )],
            ]),
        ]);
        $count = app(BmkgInformationService::class)->synchronizeFeltEarthquakes();

        $this->assertSame(1, $count);
        $this->assertDatabaseCount('berita', 1);
        $item = Berita::query()->sole();
        $this->assertSame('Tsunami', $item->kategori);
        $this->assertSame('kejadian', $item->jenis_konten);
        $this->assertSame('BMKG', $item->sumber);
        $this->assertSame('published', $item->status_publikasi);
        $this->assertSame('2026-10-24T03:30:00.000000Z', $item->waktu_kejadian->toISOString());
        $this->assertSame('2026-10-24T03:30:00.000000Z', $item->waktu_publikasi->toISOString());
        $this->assertNull($item->waktu_berakhir);
        $this->assertStringStartsWith('bmkg-quake:', $item->sumber_id);
        $this->assertStringContainsString('bukan peringatan aktif', $item->isi);
        $this->assertSame('https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json', $item->url_sumber);
    }

    public function test_repeated_quake_source_id_updates_one_record_instead_of_duplicating(): void
    {
        Carbon::setTestNow('2026-10-24 03:00:00');
        $sourceId = 'bmkg-quake:'.hash(
            'sha256',
            Carbon::parse('2026-10-24T03:30:00+00:00')->toIso8601String().'|-0.95,100.36',
        );
        Berita::query()->create($this->baseNews([
            'judul' => 'Versi lama',
            'sumber' => 'BMKG',
            'sumber_id' => $sourceId,
        ]));
        $quake = $this->earthquake('III Kota Padang');
        $quake['Magnitude'] = '5.4';
        Http::fake([
            'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json' => Http::response([
                'Infogempa' => ['gempa' => [$quake]],
            ]),
            'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json' => Http::response([
                'Infogempa' => ['gempa' => $this->earthquake('III Kota Bengkulu')],
            ]),
        ]);
        $service = app(BmkgInformationService::class);
        $this->assertSame(1, $service->synchronizeFeltEarthquakes());
        $this->assertDatabaseCount('berita', 1);
        $this->assertDatabaseHas('berita', ['sumber_id' => $sourceId, 'judul' => 'Gempa dirasakan di Padang']);
        $this->assertStringContainsString('M5.4', Berita::query()->sole()->isi);
    }

    public function test_empty_quake_feed_does_not_delete_existing_server_data(): void
    {
        Carbon::setTestNow('2026-10-24 03:00:00');
        Berita::query()->create($this->baseNews(['sumber_id' => 'editorial:existing']));
        Http::fake([
            'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json' => Http::response([
                'Infogempa' => ['gempa' => []],
            ]),
            'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json' => Http::response([
                'Infogempa' => ['gempa' => $this->earthquake('III Kota Bengkulu')],
            ]),
        ]);
        Log::spy();

        $count = app(BmkgInformationService::class)->synchronizeFeltEarthquakes();

        $this->assertSame(0, $count);
        $this->assertDatabaseCount('berita', 1);
        $this->assertDatabaseHas('berita', ['sumber_id' => 'editorial:existing']);
        Log::shouldHaveReceived('info')
            ->with('BMKG earthquake feed processed', \Mockery::on(
                fn (array $context): bool => ($context['result'] ?? null) === 'valid_feed_no_padang_matches'
                    && ($context['records_out_of_padang_scope'] ?? null) === 1,
            ))
            ->once();
    }

    public function test_cap_warning_is_imported_only_when_padang_is_affected_and_expiry_is_future(): void
    {
        Carbon::setTestNow('2026-10-24 03:00:00');
        Http::fake([
            'https://www.bmkg.go.id/alerts/nowcast/id' => Http::response($this->capFeed()),
            'https://www.bmkg.go.id/alerts/nowcast/id/PADANG_alert.xml' => Http::response(
                $this->capAlert('Kota Padang', '2026-10-24T04:00:00Z'),
            ),
            'https://www.bmkg.go.id/alerts/nowcast/id/PARIAMAN_alert.xml' => Http::response(
                $this->capAlert('Kabupaten Padang Pariaman', '2026-10-24T04:00:00Z'),
            ),
            'https://www.bmkg.go.id/alerts/nowcast/id/EXPIRED_alert.xml' => Http::response(
                $this->capAlert('Kota Padang', '2026-10-24T02:00:00Z'),
            ),
        ]);

        $count = app(BmkgInformationService::class)->synchronizePadangWeatherAlerts();

        $this->assertSame(1, $count);
        $this->assertDatabaseCount('berita', 1);
        $item = Berita::query()->sole();
        $this->assertSame('peringatan', $item->jenis_konten);
        $this->assertSame('Imbauan/penanganan bencana', $item->kategori);
        $this->assertSame('Kota Padang', $item->wilayah);
        $this->assertStringStartsWith('bmkg-cap:', $item->sumber_id);
        $this->getJson('/api/berita')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.jenis_konten', 'peringatan')
            ->assertJsonPath('data.0.sumber', 'BMKG')
            ->assertJsonPath('data.0.url_sumber', 'https://www.bmkg.go.id/alerts/nowcast/id/PADANG_alert.xml')
            ->assertJsonPath('data.0.wilayah', 'Kota Padang');

        $this->getJson('/api/berita/'.$item->id)
            ->assertOk()
            ->assertJsonPath('data.id', $item->id)
            ->assertJsonPath('data.waktu_berakhir', '2026-10-24T04:00:00.000000Z');
    }

    public function test_valid_weather_feed_without_active_padang_alerts_keeps_saved_alert_published(): void
    {
        Carbon::setTestNow('2026-10-24 03:00:00');
        Berita::query()->create($this->baseNews([
            'jenis_konten' => 'peringatan',
            'sumber' => 'BMKG',
            'sumber_id' => 'bmkg-cap:previous-active',
            'url_sumber' => 'https://www.bmkg.go.id/alerts/nowcast/id/PREVIOUS_alert.xml',
            'wilayah' => 'Kota Padang',
            'waktu_kejadian' => '2026-10-24 02:00:00',
            'waktu_berakhir' => '2026-10-24 04:00:00',
        ]));
        Http::fake([
            'https://www.bmkg.go.id/alerts/nowcast/id' => Http::response($this->capFeed()),
            'https://www.bmkg.go.id/alerts/nowcast/id/PADANG_alert.xml' => Http::response(
                $this->capAlert('Kota Padang', '2026-10-24T02:00:00Z'),
            ),
            'https://www.bmkg.go.id/alerts/nowcast/id/PARIAMAN_alert.xml' => Http::response(
                $this->capAlert('Kabupaten Padang Pariaman', '2026-10-24T02:00:00Z'),
            ),
            'https://www.bmkg.go.id/alerts/nowcast/id/EXPIRED_alert.xml' => Http::response(
                $this->capAlert('Kota Padang', '2026-10-24T02:00:00Z'),
            ),
        ]);

        $this->assertSame(0, app(BmkgInformationService::class)->synchronizePadangWeatherAlerts());
        $this->assertDatabaseHas('berita', [
            'sumber_id' => 'bmkg-cap:previous-active',
            'status_publikasi' => 'published',
        ]);
        $this->assertSame(1, Berita::query()->count());
    }

    public function test_api_never_returns_expired_or_unbounded_warning_records(): void
    {
        Carbon::setTestNow('2026-10-24 03:00:00');
        Berita::query()->create($this->baseNews([
            'jenis_konten' => 'peringatan',
            'waktu_berakhir' => '2026-10-24 02:59:00',
        ]));
        Berita::query()->create($this->baseNews([
            'jenis_konten' => 'peringatan',
            'sumber_id' => 'bmkg-cap:missing-expiry',
            'waktu_berakhir' => null,
        ]));

        $this->getJson('/api/berita')->assertOk()->assertJsonPath('data', []);
    }

    public function test_feed_cannot_direct_cap_fetch_to_an_untrusted_host(): void
    {
        Carbon::setTestNow('2026-10-24 03:00:00');
        Http::fake([
            'https://www.bmkg.go.id/alerts/nowcast/id' => Http::response(
                str_replace('www.bmkg.go.id', 'attacker.example', $this->capFeed()),
                200,
            ),
        ]);

        try {
            app(BmkgInformationService::class)->synchronizePadangWeatherAlerts();
            $this->fail('URL CAP eksternal seharusnya ditolak.');
        } catch (\UnexpectedValueException $exception) {
            $this->assertStringContainsString('untrusted_cap_url', $exception->getMessage());
        }

        $this->assertDatabaseCount('berita', 0);
    }

    public function test_http_failure_is_reported_by_command_and_retains_existing_data(): void
    {
        Berita::query()->create($this->baseNews(['sumber_id' => 'editorial:keep']));
        Http::fake([
            'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json' => Http::response('unavailable', 503),
            'https://www.bmkg.go.id/alerts/nowcast/id' => Http::response(
                '<rss version="2.0"><channel><title>BMKG</title></channel></rss>',
            ),
        ]);
        Log::spy();

        $this->artisan('ranah:sync-bmkg')->assertExitCode(1);

        $this->assertDatabaseHas('berita', ['sumber_id' => 'editorial:keep']);
        Log::shouldHaveReceived('warning')
            ->with('BMKG source synchronization failed; stored records were retained', \Mockery::on(
                fn (array $context): bool => ($context['feed'] ?? null) === 'earthquakes'
                    && ($context['failure_category'] ?? null) === 'http_status_failure'
                    && ($context['http_status'] ?? null) === 503
                    && ! array_key_exists('response_body', $context),
            ))
            ->once();
    }

    public function test_timeout_is_reported_separately_from_http_status_failure(): void
    {
        Berita::query()->create($this->baseNews(['sumber_id' => 'editorial:keep-timeout']));
        Http::fake([
            'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json' => Http::failedConnection(
                'cURL error 28: Operation timed out',
            ),
            'https://www.bmkg.go.id/alerts/nowcast/id' => Http::response(
                '<rss version="2.0"><channel><title>BMKG</title></channel></rss>',
            ),
        ]);
        Log::spy();

        $this->artisan('ranah:sync-bmkg')->assertExitCode(1);

        $this->assertDatabaseHas('berita', ['sumber_id' => 'editorial:keep-timeout']);
        Log::shouldHaveReceived('warning')
            ->with('BMKG source synchronization failed; stored records were retained', \Mockery::on(
                fn (array $context): bool => ($context['feed'] ?? null) === 'earthquakes'
                    && ($context['failure_category'] ?? null) === 'timeout',
            ))
            ->once();
    }

    public function test_invalid_json_is_logged_as_source_parse_failure_and_does_not_delete_data(): void
    {
        Berita::query()->create($this->baseNews(['sumber_id' => 'editorial:keep-json']));
        Http::fake([
            'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json' => Http::response(
                '{invalid json',
                200,
                ['Content-Type' => 'application/json'],
            ),
        ]);
        Log::spy();

        try {
            app(BmkgInformationService::class)->synchronizeFeltEarthquakes();
            $this->fail('JSON tidak valid harus menyebabkan kegagalan sinkronisasi.');
        } catch (\UnexpectedValueException $exception) {
            $this->assertStringContainsString('invalid_json', $exception->getMessage());
        }

        $this->assertDatabaseHas('berita', ['sumber_id' => 'editorial:keep-json']);
        Log::shouldHaveReceived('warning')
            ->with('BMKG source response failed validation', \Mockery::on(
                fn (array $context): bool => ($context['feed'] ?? null) === 'felt_earthquakes'
                    && ($context['stage'] ?? null) === 'json_parse'
                    && ($context['reason'] ?? null) === 'invalid_json',
            ))
            ->once();
    }

    public function test_invalid_padang_earthquake_record_fails_before_writing_any_feed_data(): void
    {
        Berita::query()->create($this->baseNews(['sumber_id' => 'editorial:keep-record']));
        $invalid = $this->earthquake('III Kota Padang');
        $invalid['Coordinates'] = 'invalid';
        Http::fake([
            'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json' => Http::response([
                'Infogempa' => ['gempa' => [$invalid]],
            ]),
            'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json' => Http::response([
                'Infogempa' => ['gempa' => $this->earthquake('III Kota Bengkulu')],
            ]),
        ]);
        Log::spy();

        try {
            app(BmkgInformationService::class)->synchronizeFeltEarthquakes();
            $this->fail('Record Padang dengan koordinat tidak valid harus menggagalkan sinkronisasi.');
        } catch (\UnexpectedValueException $exception) {
            $this->assertStringContainsString('invalid_padang_records', $exception->getMessage());
        }

        $this->assertDatabaseCount('berita', 1);
        $this->assertDatabaseHas('berita', ['sumber_id' => 'editorial:keep-record']);
        Log::shouldHaveReceived('warning')
            ->with('BMKG source response failed validation', \Mockery::on(
                fn (array $context): bool => ($context['feed'] ?? null) === 'earthquakes'
                    && ($context['stage'] ?? null) === 'record_validation'
                    && ($context['reason'] ?? null) === 'invalid_padang_records',
            ))
            ->once();
    }

    public function test_invalid_cap_xml_is_reported_and_does_not_archive_saved_alerts(): void
    {
        Carbon::setTestNow('2026-10-24 03:00:00');
        Berita::query()->create($this->baseNews([
            'jenis_konten' => 'peringatan',
            'sumber_id' => 'bmkg-cap:existing',
            'url_sumber' => 'https://www.bmkg.go.id/alerts/nowcast/id/OLD_alert.xml',
            'wilayah' => 'Kota Padang',
            'waktu_berakhir' => '2026-10-24 04:00:00',
        ]));
        Http::fake([
            'https://www.bmkg.go.id/alerts/nowcast/id' => Http::response($this->capFeed()),
            'https://www.bmkg.go.id/alerts/nowcast/id/PADANG_alert.xml' => Http::response('<alert><broken>'),
            'https://www.bmkg.go.id/alerts/nowcast/id/PARIAMAN_alert.xml' => Http::response(
                $this->capAlert('Kabupaten Padang Pariaman', '2026-10-24T04:00:00Z'),
            ),
            'https://www.bmkg.go.id/alerts/nowcast/id/EXPIRED_alert.xml' => Http::response(
                $this->capAlert('Kota Padang', '2026-10-24T02:00:00Z'),
            ),
        ]);
        Log::spy();

        try {
            app(BmkgInformationService::class)->synchronizePadangWeatherAlerts();
            $this->fail('XML tidak valid harus menyebabkan kegagalan sinkronisasi.');
        } catch (\UnexpectedValueException $exception) {
            $this->assertStringContainsString('invalid_xml', $exception->getMessage());
        }

        $this->assertDatabaseHas('berita', [
            'sumber_id' => 'bmkg-cap:existing',
            'status_publikasi' => 'published',
        ]);
        Log::shouldHaveReceived('warning')
            ->with('BMKG source response failed validation', \Mockery::on(
                fn (array $context): bool => ($context['feed'] ?? null) === 'weather_alerts'
                    && ($context['stage'] ?? null) === 'xml_parse'
                    && ($context['reason'] ?? null) === 'invalid_xml',
            ))
            ->once();
    }

    /** @return array<string, mixed> */
    private function earthquake(string $feltAreas, string $potential = ''): array
    {
        return [
            'Tanggal' => '24 Okt 2026',
            'Jam' => '10:30:00 WIB',
            'DateTime' => '2026-10-24T03:30:00+00:00',
            'Coordinates' => '-0.95,100.36',
            'Magnitude' => '5.1',
            'Kedalaman' => '10 km',
            'Wilayah' => 'Pusat gempa uji',
            'Potensi' => $potential,
            'Dirasakan' => $feltAreas,
        ];
    }

    private function capFeed(): string
    {
        return '<rss version="2.0"><channel><title>BMKG CAP</title>'
            .'<item><title>Peringatan Sumatera Barat</title><description>Sumatera Barat</description>'
            .'<link>https://www.bmkg.go.id/alerts/nowcast/id/PADANG_alert.xml</link>'
            .'<pubDate>Sat, 24 Oct 2026 02:45:00 GMT</pubDate></item>'
            .'<item><title>Peringatan Sumatera Barat</title><description>Sumatera Barat</description>'
            .'<link>https://www.bmkg.go.id/alerts/nowcast/id/PARIAMAN_alert.xml</link>'
            .'<pubDate>Sat, 24 Oct 2026 02:45:00 GMT</pubDate></item>'
            .'<item><title>Peringatan Sumatera Barat</title><description>Sumatera Barat</description>'
            .'<link>https://www.bmkg.go.id/alerts/nowcast/id/EXPIRED_alert.xml</link>'
            .'<pubDate>Sat, 24 Oct 2026 02:45:00 GMT</pubDate></item>'
            .'</channel></rss>';
    }

    private function capAlert(string $region, string $expires): string
    {
        return '<alert xmlns="urn:oasis:names:tc:emergency:cap:1.2">'
            .'<identifier>test-alert-'.sha1($region.$expires).'</identifier><info>'
            .'<event>Hujan lebat</event><headline>Peringatan cuaca uji</headline>'
            .'<description>Deskripsi peringatan uji dari sumber resmi.</description>'
            .'<effective>2026-10-24T02:30:00Z</effective><expires>'.$expires.'</expires>'
            .'<area><areaDesc>'.$region.'</areaDesc><polygon>0,0 1,1</polygon></area>'
            .'</info></alert>';
    }

    /** @param array<string, mixed> $overrides
     * @return array<string, mixed>
     */
    private function baseNews(array $overrides = []): array
    {
        return array_merge([
            'judul' => 'Artikel uji',
            'kategori' => 'Erupsi',
            'jenis_konten' => 'artikel',
            'isi' => 'Konten uji.',
            'gambar' => null,
            'sumber' => 'Sumber uji',
            'sumber_id' => null,
            'url_sumber' => null,
            'wilayah' => null,
            'waktu_publikasi' => '2026-10-23 02:00:00',
            'waktu_kejadian' => null,
            'waktu_berakhir' => null,
            'waktu_pengambilan' => null,
            'status_publikasi' => 'published',
        ], $overrides);
    }
}
