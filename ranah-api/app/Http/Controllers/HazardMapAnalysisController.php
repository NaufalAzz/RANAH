<?php

namespace App\Http\Controllers;

use App\Services\HazardSpatialAnalysisService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HazardMapAnalysisController extends Controller
{
    public function store(Request $request, HazardSpatialAnalysisService $analysis): JsonResponse
    {
        $validated = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);

        return response()->json([
            'success' => true,
            'data' => $analysis->analyze(
                (float) $validated['latitude'],
                (float) $validated['longitude'],
            ),
        ]);
    }
}
