<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

class OsmAssemblyPointController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'code' => 'eruption_evacuation_data_unavailable',
            'message' => 'Referensi OSM umum dihentikan. Jalur dan posko evakuasi erupsi yang ditetapkan petugas belum tersedia.',
        ], 410);
    }
}
