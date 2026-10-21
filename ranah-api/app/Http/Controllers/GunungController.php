<?php

namespace App\Http\Controllers;

use App\Models\Gunung;
use Illuminate\Http\JsonResponse;

class GunungController extends Controller
{
    public function index(): JsonResponse
    {
        $gunung = Gunung::query()
            ->orderBy('nama')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar gunung berhasil diambil.',
            'data' => $gunung,
        ]);
    }
}
