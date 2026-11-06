<?php

namespace App\Http\Controllers;

use App\Models\Berita;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotifikasiController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $items = Berita::query()
            ->where('status_publikasi', 'published')
            ->whereNotNull('waktu_publikasi')
            ->where('waktu_publikasi', '<=', now())
            ->where(function (Builder $query): void {
                $query->where('kategori', 'like', '%gunung%')
                    ->orWhere('kategori', 'like', '%erupsi%')
                    ->orWhere('kategori', 'like', '%vulkan%')
                    ->orWhere('kategori', 'like', '%lahar%');
            })
            ->where(function (Builder $query): void {
                $query->where('jenis_konten', '!=', 'peringatan')
                    ->orWhere('waktu_berakhir', '>', now());
            })
            ->orderByDesc('waktu_publikasi')
            ->paginate(min(max($request->integer('per_page', 30), 1), 100));

        return response()->json([
            'success' => true,
            'message' => 'Pembaruan gunung api; bukan perintah evakuasi otomatis.',
            'data' => $items->getCollection()->map(fn (Berita $item): array => [
                'id' => $item->id,
                'judul' => $item->judul,
                'kategori' => $item->kategori,
                'jenis_konten' => $item->jenis_konten,
                'ringkasan' => $item->isi,
                'wilayah' => $item->wilayah,
                'sumber' => $item->sumber,
                'url_sumber' => $item->url_sumber,
                'waktu_publikasi' => $item->waktu_publikasi,
                'waktu_pengambilan' => $item->waktu_pengambilan,
                'waktu_berakhir' => $item->waktu_berakhir,
                'status' => 'informasi',
            ]),
            'meta' => [
                'current_page' => $items->currentPage(),
                'last_page' => $items->lastPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
            ],
        ]);
    }
}
