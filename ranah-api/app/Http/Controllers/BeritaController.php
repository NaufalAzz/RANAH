<?php

namespace App\Http\Controllers;

use App\Models\Berita;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class BeritaController extends Controller
{
    public function index(): JsonResponse
    {
        $items = $this->publishedQuery()
            ->orderByDesc('waktu_publikasi')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar berita berhasil diambil.',
            'data' => $items->map(fn (Berita $item) => $this->serialize($item)),
        ]);
    }

    public function show(int $id): JsonResponse
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
            'data' => $this->serialize($item),
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
    private function serialize(Berita $item): array
    {
        return [
            'id' => $item->id,
            'judul' => $item->judul,
            'kategori' => $item->kategori,
            'jenis_konten' => $item->jenis_konten,
            'isi' => $item->isi,
            'gambar' => $this->publicImageUrl($item->gambar, $item->id),
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

    public function image(int $id): StreamedResponse
    {
        $item = $this->publishedQuery()->find($id);
        if ($item === null) {
            abort(404);
        }

        $path = $this->localImagePath($item->gambar);
        if ($path === null) {
            abort(404);
        }

        $disk = Storage::disk('public');
        if (!$disk->exists($path)) {
            abort(404);
        }

        $mimeType = $disk->mimeType($path);
        if (!in_array($mimeType, [
            'image/avif',
            'image/bmp',
            'image/gif',
            'image/jpeg',
            'image/png',
            'image/webp',
        ], true)) {
            abort(404);
        }

        return $disk->response(
            $path,
            null,
            ['X-Content-Type-Options' => 'nosniff'],
            'inline',
        );
    }

    private function publicImageUrl(?string $image, int $id): ?string
    {
        $image = trim((string) $image);
        if ($image === '') {
            return null;
        }

        if (preg_match('/^[a-z][a-z0-9+.-]*:\/\//i', $image) === 1) {
            $scheme = strtolower((string) parse_url($image, PHP_URL_SCHEME));

            return in_array($scheme, ['http', 'https'], true) ? $image : null;
        }

        if ($this->localImagePath($image) === null) {
            return null;
        }

        return route('api.berita.image', ['id' => $id]);
    }

    private function localImagePath(?string $image): ?string
    {
        $image = trim((string) $image);
        if ($image === '' || preg_match('/^[a-z][a-z0-9+.-]*:\/\//i', $image) === 1) {
            return null;
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

        return implode('/', $segments);
    }
}
