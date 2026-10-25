<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PengaduanApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_valid_complaint_is_saved_and_response_omits_reporter_details(): void
    {
        $this->travelTo(Carbon::parse('2026-10-24 10:15:00'));
        $payload = $this->validPayload();
        $payload['waktu_pengaduan'] = '2000-01-01 00:00:00';

        $response = $this->postJson('/api/pengaduan', $payload);

        $response
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['id', 'waktu_pengaduan'],
            ])
            ->assertJsonMissing(['nama_pelapor' => 'Pelapor Uji'])
            ->assertJsonMissing(['nomor_telepon' => '081234567890']);

        $this->assertDatabaseHas('pengaduan', [
            'id' => $response->json('data.id'),
            'nama_pelapor' => 'Pelapor Uji',
            'nomor_telepon' => '081234567890',
            'kategori' => 'Erupsi gunung api',
            'lokasi_kejadian' => 'Lokasi Uji',
            'deskripsi' => 'Laporan uji, bukan kejadian resmi.',
            'media' => null,
            'waktu_pengaduan' => '2026-10-24 10:15:00',
        ]);
    }

    public function test_valid_photo_is_stored_privately_and_linked_to_complaint(): void
    {
        Storage::fake('local');
        $payload = $this->validPayload();
        $payload['media'] = [UploadedFile::fake()->image('dokumentasi.jpg')];

        $response = $this->post('/api/pengaduan', $payload, [
            'Accept' => 'application/json',
        ]);

        $response->assertCreated();
        $media = json_decode(
            (string) DB::table('pengaduan')
                ->where('id', $response->json('data.id'))
                ->value('media'),
            true,
        );

        $this->assertCount(1, $media);
        $this->assertSame('dokumentasi.jpg', $media[0]['nama']);
        Storage::disk('local')->assertExists($media[0]['path']);
        $this->assertStringStartsWith('pengaduan/', $media[0]['path']);
    }

    public function test_non_image_or_excessive_photo_attachments_are_rejected(): void
    {
        Storage::fake('local');
        $payload = $this->validPayload();
        $payload['media'] = [UploadedFile::fake()->create('catatan.pdf', 50, 'application/pdf')];

        $this->post('/api/pengaduan', $payload, [
            'Accept' => 'application/json',
        ])->assertUnprocessable()->assertJsonValidationErrors('media.0');

        $payload['media'] = [
            UploadedFile::fake()->image('satu.jpg'),
            UploadedFile::fake()->image('dua.jpg'),
            UploadedFile::fake()->image('tiga.jpg'),
            UploadedFile::fake()->image('empat.jpg'),
        ];
        $this->post('/api/pengaduan', $payload, [
            'Accept' => 'application/json',
        ])->assertUnprocessable()->assertJsonValidationErrors('media');

        $this->assertDatabaseCount('pengaduan', 0);
        $this->assertSame([], Storage::disk('local')->allFiles('pengaduan'));
    }

    public function test_required_fields_and_consent_are_validated_without_saving(): void
    {
        $response = $this->postJson('/api/pengaduan', []);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'nama_pelapor',
                'nomor_telepon',
                'kategori',
                'lokasi_kejadian',
                'deskripsi',
                'persetujuan',
            ]);

        $this->assertDatabaseCount('pengaduan', 0);
    }

    public function test_invalid_category_and_coordinates_are_rejected(): void
    {
        $payload = $this->validPayload();
        $payload['kategori'] = 'Status resmi palsu';
        $payload['latitude'] = 91;
        $payload['longitude'] = -181;
        $payload['persetujuan'] = false;

        $response = $this->postJson('/api/pengaduan', $payload);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'kategori',
                'latitude',
                'longitude',
                'persetujuan',
            ]);

        $this->assertDatabaseCount('pengaduan', 0);
    }

    public function test_public_read_route_is_not_available(): void
    {
        $this->getJson('/api/pengaduan')->assertMethodNotAllowed();
    }

    public function test_submission_rate_limit_rejects_sixth_request_in_a_minute(): void
    {
        for ($attempt = 0; $attempt < 5; $attempt++) {
            $this->postJson('/api/pengaduan', $this->validPayload())
                ->assertCreated();
        }

        $this->postJson('/api/pengaduan', $this->validPayload())
            ->assertTooManyRequests();

        $this->assertDatabaseCount('pengaduan', 5);
    }

    /** @return array<string, mixed> */
    private function validPayload(): array
    {
        return [
            'nama_pelapor' => 'Pelapor Uji',
            'nomor_telepon' => '081234567890',
            'kategori' => 'Erupsi gunung api',
            'lokasi_kejadian' => 'Lokasi Uji',
            'deskripsi' => 'Laporan uji, bukan kejadian resmi.',
            'persetujuan' => true,
        ];
    }
}
