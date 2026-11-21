<?php

namespace Tests\Feature;

use App\Models\Gunung;
use App\Models\LaporanGunung;
use App\Services\MagmaInformationService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Sleep;
use Tests\TestCase;

class MagmaAllReportsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_all_69_reports_are_filled_once_and_legacy_lewotobi_id_is_preserved(): void
    {
        $this->freezeTime();
        Sleep::fake();
        Http::preventStrayRequests();
        $legacy = Gunung::query()->create(['nama' => 'Lewotobi Laki', 'provinsi' => 'Nusa Tenggara Timur', 'aktif' => true]);
        $roster = json_decode(file_get_contents(__DIR__.'/../Fixtures/magma_volcano_roster.json'), true, flags: JSON_THROW_ON_ERROR);
        $this->fakeSource($roster);
        $service = app(MagmaInformationService::class);

        $first = $service->synchronizeAllReports();
        $second = $service->synchronizeAllReports();

        self::assertSame(69, $first['total']);
        self::assertSame(69, $first['updated']);
        self::assertSame(0, $first['remaining']);
        self::assertSame(0, $first['failed']);
        self::assertSame(0, $first['missing']);
        self::assertSame(69, $second['skipped']);
        self::assertSame(0, $second['updated']);
        self::assertDatabaseCount('gunung', 69);
        self::assertDatabaseCount('laporan_gunung', 69);
        self::assertDatabaseHas('gunung', ['id' => $legacy->id, 'nama' => 'Lewotobi Laki-laki', 'provinsi' => 'Nusa Tenggara Timur', 'status_aktivitas' => 'Level III (Siaga)']);
        self::assertSame(69, LaporanGunung::query()->whereNotNull('rekomendasi')->count());
        Http::assertSentCount(71);
        Sleep::assertSleptTimes(68);
    }

    public function test_unavailable_recommendations_and_wrong_names_are_not_invented_or_saved_as_other_volcanoes(): void
    {
        Sleep::fake();
        Http::preventStrayRequests();
        $roster = [['name' => 'Marapi', 'province' => 'Sumatera Barat'], ['name' => 'Merapi', 'province' => 'Jawa Tengah']];
        $this->fakeSource($roster, missing: true, mismatched: true);

        $summary = app(MagmaInformationService::class)->synchronizeAllReports();

        self::assertSame(1, $summary['missing']);
        self::assertSame(1, $summary['failed']);
        self::assertSame(0, $summary['updated']);
        self::assertDatabaseCount('laporan_gunung', 1);
        self::assertDatabaseHas('laporan_gunung', ['sumber_id' => '1', 'rekomendasi' => null]);
        self::assertDatabaseMissing('laporan_gunung', ['sumber_id' => '2']);
        Http::assertSentCount(3);
    }

    public function test_http_429_halts_remaining_requests_and_blocks_both_command_modes(): void
    {
        $this->freezeTime();
        Sleep::fake();
        Http::preventStrayRequests();
        $this->fakeSource([['name' => 'Marapi', 'province' => 'Sumatera Barat'], ['name' => 'Merapi', 'province' => 'Jawa Tengah']], status: 429);

        $this->artisan('ranah:sync-magma', ['--semua-laporan' => true])->assertExitCode(1);
        $this->artisan('ranah:sync-magma', ['--gunung' => 'Marapi'])->assertExitCode(1);

        self::assertDatabaseCount('laporan_gunung', 0);
        self::assertSame(now()->addSeconds(7200)->timestamp, Cache::get('ranah:magma-source-backoff-until')->timestamp);
        Http::assertSentCount(2);
    }

    public function test_http_403_stops_the_batch_without_fetching_the_next_volcano(): void
    {
        Sleep::fake();
        Http::preventStrayRequests();
        $this->fakeSource([['name' => 'Marapi', 'province' => 'Sumatera Barat'], ['name' => 'Merapi', 'province' => 'Jawa Tengah']], status: 403);

        $summary = app(MagmaInformationService::class)->synchronizeAllReports();

        self::assertSame(403, $summary['halted_status']);
        self::assertSame(1, $summary['failed']);
        self::assertSame(1, $summary['remaining']);
        self::assertDatabaseCount('laporan_gunung', 0);
        Http::assertSentCount(2);
    }

    public function test_manual_fill_is_not_blocked_by_the_separate_status_schedule_cooldown(): void
    {
        Sleep::fake();
        Http::preventStrayRequests();
        Cache::put('ranah:magma-next-allowed-at', now()->addHours(6));
        $this->fakeSource([['name' => 'Marapi', 'province' => 'Sumatera Barat']]);

        $this->artisan('ranah:sync-magma', ['--semua-laporan' => true])->assertSuccessful();
        $this->artisan('ranah:sync-magma', ['--semua-laporan' => true])->assertExitCode(1);

        self::assertDatabaseCount('laporan_gunung', 1);
        Http::assertSentCount(2);
    }

    public function test_conflicting_modes_are_rejected_before_any_request(): void
    {
        Http::preventStrayRequests();
        Http::fake();

        $this->artisan('ranah:sync-magma', ['--semua-laporan' => true, '--gunung' => 'Marapi'])->assertExitCode(2);

        Http::assertNothingSent();
    }

    /** @param list<array{name:string,province:string}> $roster */
    private function fakeSource(array $roster, int $status = 200, bool $missing = false, bool $mismatched = false): void
    {
        $listing = '<table><tr><td>Level III (Siaga)</td></tr>';
        foreach ($roster as $index => $row) {
            $id = $index + 1;
            $listing .= '<tr><td>'.$row['name'].' - '.$row['province'].' <a href="https://magma.esdm.go.id/v1/gunung-api/laporan/'.$id.'?signature=fixture">Lihat laporan</a></td></tr>';
        }
        $listing .= '</table>';
        Http::fake(['magma.esdm.go.id/*' => function (Request $request) use ($listing, $roster, $status, $missing, $mismatched) {
            if ($request->url() === 'https://magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas') {
                return Http::response($listing, 200, ['Content-Type' => 'text/html']);
            }
            if ($status !== 200) {
                return Http::response('Source unavailable', $status, ['Retry-After' => '7200']);
            }
            preg_match('~/laporan/(\d+)~', $request->url(), $match);
            $index = (int) $match[1] - 1;
            $name = $mismatched && $index === 1 ? 'Bromo' : $roster[$index]['name'];
            $recommendation = $missing ? '' : '<h6>Rekomendasi</h6><p>Panduan uji '.$name.'.</p>';

            return Http::response('<html><title>Laporan Aktivitas Gunung Api - '.$name.', Sabtu - 21 November 2026, periode 00:00-24:00 WIB</title><body><h2>Level I (Normal)</h2>'.$recommendation.'</body></html>', 200, ['Content-Type' => 'text/html']);
        }]);
    }
}
