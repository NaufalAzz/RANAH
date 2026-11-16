<?php

namespace App\Http\Controllers;

use App\Models\Berita;
use App\Services\MediaEruptionFeed;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class BeritaController extends Controller
{
    public function index(): JsonResponse
    {
        if (config('services.media_news.enabled')) {
            try {
                return response()->json(['success' => true, 'data' => app(MediaEruptionFeed::class)->items()]);
            } catch (\RuntimeException $error) {
                return response()->json(['success' => false, 'message' => $error->getMessage(), 'data' => []], 503);
            }
        }
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

    public function mediaImage(string $key): Response
    {
        $preview = Cache::get('media-preview-v3:'.$key);
        $url = is_array($preview) ? ($preview['image'] ?? null) : null;
        $parts = is_string($url) ? parse_url($url) : false;
        $allowed = ['antaranews.com', 'kompas.com', 'detik.com', 'detik.net.id', 'tempo.co', 'cnnindonesia.com', 'rri.co.id', 'mediaindonesia.com', 'kompas.tv', 'tstatic.net'];
        $trusted = false;
        foreach ($allowed as $host) {
            $candidate = strtolower($parts['host'] ?? '');
            $trusted = $trusted || $candidate === $host || str_ends_with($candidate, '.'.$host);
        }
        abort_unless($trusted && ($parts['scheme'] ?? '') === 'https' && ! isset($parts['user']) && ! isset($parts['pass']) && ! isset($parts['port']), 404);
        $cached = Cache::get('media-cover:'.$key);
        if (! is_array($cached)) {
            try {
                $upstream = Http::connectTimeout(2)->timeout(6)
                    ->withOptions(['allow_redirects' => false])->get($url)->throw();
                $bytes = $upstream->body();
                abort_if(strlen($bytes) > 8_000_000, 502);
                $info = @getimagesizefromstring($bytes);
                $mime = $info['mime'] ?? '';
                abort_unless(in_array($mime, ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/avif'], true), 502);
                $cached = ['body' => base64_encode($bytes), 'mime' => $mime];
                Cache::put('media-cover:'.$key, $cached, now()->addDay());
            } catch (\Throwable) {
                abort(502, 'Gambar sumber belum dapat diambil.');
            }
        }

        return response(base64_decode($cached['body'], true), 200, [
            'Content-Type' => $cached['mime'],
            'Cache-Control' => 'public, max-age=3600',
            'X-Content-Type-Options' => 'nosniff',
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
        if (! $disk->exists($path)) {
            abort(404);
        }

        $mimeType = $disk->mimeType($path);
        if (! in_array($mimeType, [
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
