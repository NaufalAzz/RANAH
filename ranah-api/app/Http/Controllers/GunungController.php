<?php

namespace App\Http\Controllers;

use App\Models\Gunung;
use Illuminate\Http\JsonResponse;

class GunungController extends Controller
{
    public function index(): JsonResponse
    {
        $gunung = Gunung::query()
            ->where('aktif', true)
            ->orderBy('nama')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar gunung berhasil diambil.',
            'data' => $gunung,
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $gunung = Gunung::query()
            ->where('aktif', true)
            ->with([
                'laporan' => fn ($query) => $query
                    ->orderByDesc('waktu_publikasi')
                    ->orderByDesc('id'),
            ])
            ->find($id);

        if ($gunung === null) {
            return response()->json([
                'success' => false,
                'message' => 'Data gunung tidak ditemukan atau tidak aktif.',
                'data' => null,
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail gunung berhasil diambil.',
            'data' => [
                'gunung' => $gunung->makeHidden('laporan'),
                'laporan' => $gunung->laporan,
            ],
        ]);
    }
}
