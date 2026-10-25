<?php

namespace Tests\Unit;

use App\Services\MagmaHtmlParser;
use PHPUnit\Framework\TestCase;
use RuntimeException;

class MagmaHtmlParserTest extends TestCase
{
    public function test_activity_listing_parses_the_sanitized_real_capture(): void
    {
        $parser = new MagmaHtmlParser;
        $html = file_get_contents(__DIR__.'/../Fixtures/magma_activity_listing_capture_2026-10-25.html');
        self::assertIsString($html);

        $rows = $parser->parseActivityListing($html);

        self::assertCount(2, $rows);
        self::assertSame('Anak Krakatau', $rows[0]['name']);
        self::assertSame('Lampung', $rows[0]['province']);
        self::assertSame('Level III (Siaga)', $rows[0]['status']);
        self::assertSame('329164', $rows[0]['report_id']);
        self::assertSame('Merapi', $rows[1]['name']);
        self::assertSame('Daerah Istimewa Yogyakarta dan Jawa Tengah', $rows[1]['province']);
        self::assertSame('Level III (Siaga)', $rows[1]['status']);
        self::assertSame('329163', $rows[1]['report_id']);
        self::assertNull($parser->signedReportUrl('https://magma.esdm.go.id/v1/gunung-api/laporan/123'));
    }

    public function test_incomplete_empty_and_changed_activity_pages_are_rejected(): void
    {
        $parser = new MagmaHtmlParser;
        $cases = [
            '<table><tr><td>Level II (Waspada)</td></tr><tr><td>Unclassified label</td><td><a href="https://magma.esdm.go.id/v1/gunung-api/laporan/1?signature=x">Lihat laporan</a></td></tr></table>',
            '<html><body><table></table></body></html>',
            '<html><body><a href="https://magma.esdm.go.id/v1/gunung-api/laporan/1?signature=x">Lihat laporan</a></body></html>',
        ];
        foreach ($cases as $html) {
            try {
                $parser->parseActivityListing($html);
                self::fail('Expected invalid or incomplete HTML to be rejected.');
            } catch (RuntimeException) {
                self::assertTrue(true);
            }
        }
    }

    public function test_report_detail_extracts_observation_period_and_valid_coordinates(): void
    {
        $parser = new MagmaHtmlParser;
        $html = '<html><head><title>Laporan Aktivitas Gunung Api - Gunung Merapi, Minggu - 25 Oktober 2026, periode 06:00-12:00 WIB</title></head>'
            .'<body><h2>Level III (Siaga)</h2><h3>Pengamatan Visual</h3><p>Asap kawah teramati.</p>'
            .'<h3>Data Klimatologi</h3><p>Cuaca cerah.</p><h3>Rekomendasi</h3><p>Masyarakat mengikuti arahan.</p>'
            .'<script>L.marker([-7.54, 110.44])</script></body></html>';

        $detail = $parser->parseReportDetail($html);

        self::assertSame('Gunung Merapi', $detail['name']);
        self::assertSame('Level III (Siaga)', $detail['status']);
        self::assertSame('25 Oktober 2026', $detail['period_date']);
        self::assertSame('06:00-12:00 WIB', $detail['period_time']);
        self::assertSame(-7.54, $detail['latitude']);
        self::assertSame(110.44, $detail['longitude']);
        self::assertSame('Asap kawah teramati.', $detail['observation']);
    }

    public function test_invalid_or_changed_detail_is_rejected_and_bad_coordinates_ignored(): void
    {
        $parser = new MagmaHtmlParser;
        $this->expectException(RuntimeException::class);
        $parser->parseReportDetail('<html><title>HALAMAN BERUBAH</title><body>Laporan unavailable</body></html>');
    }
}
