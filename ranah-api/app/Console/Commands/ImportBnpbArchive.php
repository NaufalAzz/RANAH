<?php

namespace App\Console\Commands;

use App\Models\Berita;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class ImportBnpbArchive extends Command
{
    protected $signature = 'ranah:import-bnpb-archive {path?} {--dry-run}';

    protected $description = 'Import curated BNPB archive candidates as published news';

    public function handle(): int
    {
        $path = $this->argument('path')
            ?? base_path('../data_berita/hasil_ekstraksi/paket_final_impor_2024_2026/berita_siap_impor.csv');

        try {
            $candidates = $this->readCandidates($path);
        } catch (RuntimeException $exception) {
            $this->error($exception->getMessage());

            return self::FAILURE;
        }

        $inserted = 0;
        $updated = 0;
        $skipped = 0;

        DB::transaction(function () use ($candidates, &$inserted, &$updated, &$skipped): void {
            foreach ($candidates as $candidate) {
                $existing = Berita::query()
                    ->where('judul', $candidate['judul'])
                    ->where('sumber', $candidate['sumber'])
                    ->where('jenis_konten', 'kejadian')
                    ->first();

                if ($existing !== null) {
                    $provenance = 'ID kurasi internal: '.$candidate['id_kandidat_asli'].'.';
                    if (! str_contains($existing->isi, $provenance)) {
                        $skipped++;

                        continue;
                    }

                    $cleanedBody = str_replace(
                        [
                            ' Arsip akademik berstatus draft; bukan peringatan aktif.',
                            ' Arsip akademik RANAH; catatan kejadian historis, bukan peringatan aktif.',
                        ],
                        '',
                        $existing->isi,
                    );
                    $needsPublishUpdate = $existing->status_publikasi !== 'published'
                        || $existing->waktu_publikasi === null;
                    if ($needsPublishUpdate || $cleanedBody !== $existing->isi) {
                        if (! $this->option('dry-run')) {
                            $changes = [
                                'isi' => $cleanedBody,
                                'waktu_pengambilan' => now(),
                            ];
                            if ($needsPublishUpdate) {
                                $changes['waktu_publikasi'] = now();
                                $changes['status_publikasi'] = 'published';
                            }
                            $existing->update($changes);
                        }
                        $updated++;

                        continue;
                    }

                    $skipped++;

                    continue;
                }

                if ($this->option('dry-run')) {
                    $inserted++;

                    continue;
                }

                Berita::query()->create($this->toAttributes($candidate));
                $inserted++;
            }
        });

        $this->info(sprintf(
            '%s: %d kandidat baru, %d record diperbarui, %d sudah ada.',
            $this->option('dry-run') ? 'Simulasi' : 'Impor selesai',
            $inserted,
            $updated,
            $skipped,
        ));

        return self::SUCCESS;
    }

    /** @return list<array<string, string>> */
    private function readCandidates(string $path): array
    {
        if (! is_file($path) || ! is_readable($path)) {
            throw new RuntimeException("CSV tidak ditemukan atau tidak dapat dibaca: {$path}");
        }

        $handle = fopen($path, 'rb');
        if ($handle === false) {
            throw new RuntimeException('CSV gagal dibuka.');
        }

        try {
            $headers = fgetcsv($handle);
            if (! is_array($headers)) {
                throw new RuntimeException('CSV tidak memiliki header.');
            }
            $headers[0] = preg_replace('/^\xEF\xBB\xBF/', '', (string) $headers[0]) ?? (string) $headers[0];

            $required = [
                'id_kandidat_asli', 'status_final', 'judul', 'jenis_bencana',
                'ringkasan_faktual', 'sumber', 'nama_file_pdf', 'halaman_fisik_pdf',
            ];
            if (array_diff($required, $headers) !== []) {
                throw new RuntimeException('Header CSV tidak sesuai dengan paket berita siap impor.');
            }

            $rows = [];
            while (($values = fgetcsv($handle)) !== false) {
                if ($values === [null] || $values === []) {
                    continue;
                }

                $candidate = array_combine($headers, array_pad($values, count($headers), ''));
                if (! is_array($candidate)
                    || ($candidate['status_final'] ?? '') !== 'SIAP_IMPOR_DENGAN_CATATAN'
                    || trim((string) ($candidate['id_kandidat_asli'] ?? '')) === ''
                    || trim((string) ($candidate['judul'] ?? '')) === ''
                    || trim((string) ($candidate['ringkasan_faktual'] ?? '')) === ''
                    || trim((string) ($candidate['sumber'] ?? '')) === ''
                    || trim((string) ($candidate['nama_file_pdf'] ?? '')) === ''
                    || trim((string) ($candidate['halaman_fisik_pdf'] ?? '')) === '') {
                    throw new RuntimeException('CSV memuat kandidat yang tidak memenuhi syarat import.');
                }

                $rows[] = array_map(static fn ($value): string => trim((string) $value), $candidate);
            }
        } finally {
            fclose($handle);
        }

        if ($rows === []) {
            throw new RuntimeException('CSV tidak memuat kandidat siap impor.');
        }

        return $rows;
    }

    /** @param array<string, string> $candidate
     * @return array<string, mixed>
     */
    private function toAttributes(array $candidate): array
    {
        $date = $candidate['tanggal_kejadian_mulai'] ?? '';
        $time = preg_match('/[T ]\d{2}:\d{2}/', $date) === 1
            ? Carbon::parse($date)
            : null;

        $summary = $candidate['ringkasan_faktual'];
        if ($date !== '') {
            $summary .= "\n\nTanggal kejadian menurut buletin: {$date}. Waktu kejadian tidak dicantumkan pada kandidat.";
        }
        $endDate = $candidate['tanggal_kejadian_selesai'] ?? '';
        if ($endDate !== '') {
            $summary .= "\nTanggal akhir kejadian menurut buletin: {$endDate}. Waktu tidak dicantumkan.";
        }

        $evidence = trim($candidate['bukti_sumber'] ?? '');
        if ($evidence !== '') {
            $summary .= "\n\nCatatan bukti: {$evidence}";
        }

        $summary .= sprintf(
            "\n\nRujukan: Buletin Info Bencana BNPB, %s, halaman fisik %s. ID kurasi internal: %s. Tanggal publikasi sumber tidak tercantum; tanggal publikasi di aplikasi menunjukkan waktu pencatatan.",
            $candidate['nama_file_pdf'],
            $candidate['halaman_fisik_pdf'],
            $candidate['id_kandidat_asli'],
        );

        return [
            'judul' => $candidate['judul'],
            'kategori' => $this->categoryLabel($candidate['jenis_bencana']),
            'jenis_konten' => 'kejadian',
            'isi' => $summary,
            'gambar' => null,
            'sumber' => $candidate['sumber'],
            'sumber_id' => null,
            'url_sumber' => null,
            'wilayah' => $this->regionLabel($candidate),
            'waktu_publikasi' => now(),
            'waktu_kejadian' => $time,
            'waktu_berakhir' => null,
            'waktu_pengambilan' => now(),
            'status_publikasi' => 'published',
        ];
    }

    private function categoryLabel(string $category): string
    {
        return match ($category) {
            'BANJIR_DAN_TANAH_LONGSOR' => 'Banjir dan longsor',
            'TANAH_LONGSOR' => 'Tanah longsor',
            'ERUPSI_GUNUNG_API' => 'Erupsi gunung api',
            'BANJIR' => 'Banjir',
            'CUACA_EKSTREM' => 'Cuaca ekstrem',
            default => str($category)->replace('_', ' ')->lower()->ucfirst()->toString(),
        };
    }

    /** @param array<string, string> $candidate */
    private function regionLabel(array $candidate): ?string
    {
        $parts = array_filter([
            $candidate['kecamatan'] ?? '',
            $candidate['kabupaten_kota'] ?? '',
            $candidate['provinsi'] ?? '',
        ], static fn (string $part): bool => $part !== '');

        return $parts === [] ? null : implode(', ', array_unique($parts));
    }
}
