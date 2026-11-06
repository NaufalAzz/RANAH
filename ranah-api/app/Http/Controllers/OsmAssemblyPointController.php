<?php

namespace App\Http\Controllers;

use App\Services\OsmAssemblyPointService;
use Illuminate\Http\JsonResponse;
use RuntimeException;

class OsmAssemblyPointController extends Controller
{
    public function index(OsmAssemblyPointService $service): JsonResponse
    {
        try {
            return response()->json([
                'success' => true,
                'data' => $service->read(),
            ]);
        } catch (RuntimeException) {
            return response()->json([
                'success' => false,
                'message' => 'Data referensi OpenStreetMap sementara tidak dapat dimuat.',
            ], 503);
        }
    }
}
