<?php

namespace App\Http\Controllers;

use App\Models\Berita;
use App\Services\BmkgInformationService;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class NotifikasiController extends Controller
{
    public function index(Request $request, BmkgInformationService $bmkg): JsonResponse
    {
        $now = now();
        $days = max(1, (int) config('bmkg.sumatera_barat.earthquake_notification_days', 7));
        $query = Berita::query()
            ->where('sumber', 'BMKG')
            ->where('status_publikasi', 'published')
            ->where(function (Builder $currentSourceItems) use ($now, $days): void {
                $currentSourceItems->where(function (Builder $earthquakes) use ($now, $days): void {
                    $earthquakes->where('sumber_id', 'like', 'bmkg-quake:%')
                        ->where('jenis_konten', 'kejadian')
                        ->whereNotNull('waktu_kejadian')
                        ->where('waktu_kejadian', '>=', $now->copy()->subDays($days))
                        ->where('waktu_kejadian', '<=', $now);
                })->orWhere(function (Builder $alerts) use ($now): void {
                    $alerts->where('sumber_id', 'like', 'bmkg-cap:%')
                        ->where('jenis_konten', 'peringatan')
                        ->whereNotNull('waktu_kejadian')
                        ->where('waktu_kejadian', '<=', $now)
                        ->whereNotNull('waktu_berakhir')
                        ->where('waktu_berakhir', '>', $now)
                        ->whereNotNull('waktu_publikasi')
                        ->where('waktu_publikasi', '<=', $now);
                });
            });

        if ($category = trim((string) $request->query('kategori', ''))) {
            $query->where('kategori', $category);
        }

        // Filter using the same configured locality matcher as ingestion. The
        // source records carry BMKG's affected/epicenter area text; no boundary
        // polygon is available locally for a point-in-polygon calculation.
        $items = $query->orderByRaw('COALESCE(waktu_kejadian, waktu_publikasi) DESC')
            ->orderByDesc('id')
            ->get()
            ->filter(fn (Berita $item): bool => $bmkg->hasWestSumatraLocality((string) $item->wilayah))
            ->values();

        $perPage = min(max($request->integer('per_page', 30), 1), 100);
        $currentPage = max($request->integer('page', 1), 1);
        $total = $items->count();
        $lastPage = max(1, (int) ceil($total / $perPage));
        $pageItems = $items->slice(($currentPage - 1) * $perPage, $perPage)->values();

        $data = $pageItems->map(fn (Berita $item): array => [
            'id' => $item->id,
            'judul' => $item->judul,
            'kategori' => $item->kategori,
            'jenis_konten' => $item->jenis_konten,
            'ringkasan' => $item->isi,
            'wilayah' => $item->wilayah,
            'cakupan_wilayah' => 'Sumatera Barat',
            'rentang_gempa_hari' => $days,
            'sumber' => $item->sumber,
            'sumber_id' => $item->sumber_id,
            'url_sumber' => $item->url_sumber,
            'tingkat_kepentingan' => $item->tingkat_kepentingan,
            'waktu_kejadian' => $item->waktu_kejadian,
            'waktu_publikasi' => $item->waktu_publikasi,
            'waktu_pengambilan' => $item->waktu_pengambilan,
            'waktu_berakhir' => $item->waktu_berakhir,
            'status' => $this->status($item),
        ]);

        $lastBmkgSync = $this->latestBmkgSync();

        return response()->json([
            'success' => true,
            'message' => 'Daftar informasi BMKG aktif untuk Sumatera Barat berhasil diambil.',
            'data' => $data,
            'meta' => [
                'current_page' => $currentPage,
                'last_page' => $lastPage,
                'per_page' => $perPage,
                'total' => $total,
                'waktu_pembaruan_terakhir' => $lastBmkgSync,
                'waktu_pembaruan_terakhir_bmkg' => $lastBmkgSync,
                'rentang_gempa_hari' => $days,
            ],
        ]);
    }

    private function latestBmkgSync(): ?string
    {
        $values = collect([
            Cache::get('bmkg_earthquake_last_success_at'),
            Cache::get('bmkg_weather_last_success_at'),
        ])->filter(fn ($value): bool => is_string($value) && $value !== '')
            ->map(fn (string $value): ?CarbonImmutable => $this->parseDate($value))
            ->filter()
            ->sortByDesc(fn (CarbonImmutable $value): int => $value->getTimestamp());

        return $values->first()?->toIso8601String();
    }

    private function parseDate(string $value): ?CarbonImmutable
    {
        try {
            return CarbonImmutable::parse($value);
        } catch (\Throwable) {
            return null;
        }
    }

    private function status(Berita $item): string
    {
        return $item->jenis_konten === 'peringatan' ? 'aktif' : 'informasi';
    }
}
