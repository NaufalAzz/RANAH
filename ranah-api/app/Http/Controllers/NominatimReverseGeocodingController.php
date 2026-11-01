<?php

namespace App\Http\Controllers;

use App\Services\NominatimLookupException;
use App\Services\NominatimReverseGeocodingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NominatimReverseGeocodingController extends Controller
{
    public function show(Request $request, NominatimReverseGeocodingService $service): JsonResponse
    {
        $validated = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);

        try {
            return response()->json([
                'success' => true,
                'data' => $service->reverse(
                    (float) $validated['latitude'],
                    (float) $validated['longitude'],
                ),
            ]);
        } catch (NominatimLookupException $exception) {
            $response = response()->json([
                'success' => false,
                'message' => $exception->getMessage(),
            ], $exception->httpStatus);

            if ($exception->retryAfterSeconds > 0) {
                $response->header('Retry-After', (string) $exception->retryAfterSeconds);
            }

            return $response;
        }
    }
}
