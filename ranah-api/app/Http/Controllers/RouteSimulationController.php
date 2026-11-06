<?php

namespace App\Http\Controllers;

use App\Services\FootWalkingRoutingProvider;
use App\Services\OsmAssemblyPointService;
use App\Services\RouteSimulationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;

class RouteSimulationController extends Controller
{
    public function store(
        Request $request,
        OsmAssemblyPointService $osm,
        FootWalkingRoutingProvider $routing,
    ): JsonResponse {
        $validated = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'destination_id' => ['required', 'string', 'max:64', 'regex:/^(node|way)\/[1-9][0-9]*$/'],
        ]);

        try {
            $destination = $osm->findById($validated['destination_id']);
        } catch (RuntimeException) {
            return response()->json([
                'success' => false,
                'code' => 'osm_dataset_unavailable',
                'message' => 'Dataset titik referensi sementara tidak dapat dimuat.',
            ], 503);
        }

        if ($destination === null) {
            return response()->json([
                'success' => false,
                'code' => 'destination_not_found',
                'message' => 'Tujuan tidak ditemukan dalam dataset OSM yang digunakan.',
            ], 404);
        }
        if (($destination['geometri']['type'] ?? null) !== 'Point') {
            return response()->json([
                'success' => false,
                'code' => 'polygon_access_not_available',
                'message' => 'Geometri area tidak memiliki titik akses terverifikasi; rute tidak dibuat.',
            ], 422);
        }

        try {
            $route = $routing->route(
                (float) $validated['latitude'],
                (float) $validated['longitude'],
                $destination,
            );
        } catch (RouteSimulationException $exception) {
            return response()->json([
                'success' => false,
                'code' => $exception->errorCode,
                'message' => $exception->getMessage(),
            ], $exception->httpStatus);
        }

        return response()->json([
            'success' => true,
            'message' => 'Rute simulasi pejalan kaki berhasil dihitung.',
            'data' => $route + [
                'tujuan' => [
                    'id' => $destination['id'],
                    'nama' => $destination['nama'],
                    'status_verifikasi' => $destination['status_verifikasi'],
                    'url_osm' => $destination['url_osm'],
                ],
            ],
        ]);
    }
}
