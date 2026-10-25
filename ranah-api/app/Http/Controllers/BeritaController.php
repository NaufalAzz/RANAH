<?php

namespace App\Http\Controllers;

use App\Models\Berita;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BeritaController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $items = $this->publishedQuery()
            ->orderByDesc('waktu_publikasi')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar berita berhasil diambil.',
            'data' => $items->map(fn (Berita $item) => $this->serialize($item, $request)),
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $item = $this->publishedQuery()->find($id);

        if ($item === null) {
            return response()->json([
                'success' => false,
                'message' => 'Berita tidak ditemukan atau belum dipublikasikan.',
                'data' => null,
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail berita berhasil diambil.',
            'data' => $this->serialize($item, $request),
        ]);
    }

    private function publishedQuery(): Builder
    {
        return Berita::query()
            ->where('status_publikasi', 'published')
            ->whereNotNull('waktu_publikasi')
            ->where('waktu_publikasi', '<=', now())
            ->where(function (Builder $query): void {
                $query->where('jenis_konten', '!=', 'peringatan')
                    ->orWhere(function (Builder $warningQuery): void {
                        $warningQuery->whereNotNull('waktu_berakhir')
                            ->where('waktu_berakhir', '>', now());
                    });
            });
    }

    /** @return array<string, mixed> */
    private function serialize(Berita $item, Request $request): array
    {
        return [
            'id' => $item->id,
            'judul' => $item->judul,
            'kategori' => $item->kategori,
            'jenis_konten' => $item->jenis_konten,
            'isi' => $item->isi,
            'gambar' => $this->publicImageUrl($item->gambar, $request),
            'sumber' => $item->sumber,
            'sumber_id' => $item->sumber_id,
            'tingkat_kepentingan' => $item->tingkat_kepentingan,
            'url_sumber' => $item->url_sumber,
            'wilayah' => $item->wilayah,
            'waktu_publikasi' => $item->waktu_publikasi,
            'waktu_kejadian' => $item->waktu_kejadian,
            'waktu_berakhir' => $item->waktu_berakhir,
            'waktu_pengambilan' => $item->waktu_pengambilan,
            'status_publikasi' => $item->status_publikasi,
        ];
    }

    private function publicImageUrl(?string $image, Request $request): ?string
    {
        $image = trim((string) $image);
        if ($image === '') {
            return null;
        }

        if (preg_match('/^[a-z][a-z0-9+.-]*:\/\//i', $image) === 1) {
            $scheme = strtolower((string) parse_url($image, PHP_URL_SCHEME));

            return in_array($scheme, ['http', 'https'], true) ? $image : null;
        }

        $path = ltrim($image, '/');
        if (str_starts_with($path, 'storage/')) {
            $path = substr($path, strlen('storage/'));
        }

        $segments = explode('/', $path);
        foreach ($segments as $segment) {
            if ($segment === '' || $segment === '.' || $segment === '..'
                || preg_match('/^[A-Za-z0-9._-]+$/', $segment) !== 1) {
                return null;
            }
        }

        return $request->getSchemeAndHttpHost().'/storage/'.implode(
            '/',
            array_map('rawurlencode', $segments),
        );
    }
}
