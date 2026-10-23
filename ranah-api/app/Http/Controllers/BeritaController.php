<?php

namespace App\Http\Controllers;

use App\Models\Berita;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;

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
            ->where('waktu_publikasi', '<=', now());
    }

    /** @return array<string, mixed> */
    private function serialize(Berita $item): array
    {
        return [
            'id' => $item->id,
            'judul' => $item->judul,
            'kategori' => $item->kategori,
            'isi' => $item->isi,
            'gambar' => $item->gambar,
            'sumber' => $item->sumber,
            'waktu_publikasi' => $item->waktu_publikasi,
        ];
    }
}
