<?php

use App\Http\Controllers\BeritaController;
use App\Http\Controllers\BmkgForecastController;
use App\Http\Controllers\GunungController;
use App\Http\Controllers\HazardMapAnalysisController;
use App\Http\Controllers\PengaduanController;
use App\Http\Controllers\NotifikasiController;
use App\Http\Controllers\NominatimReverseGeocodingController;
use App\Http\Controllers\OsmAssemblyPointController;
use App\Http\Controllers\RouteSimulationController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/gunung', [GunungController::class, 'index']);

Route::get('/gunung/{id}', [GunungController::class, 'show'])
    ->whereNumber('id');

Route::get('/berita', [BeritaController::class, 'index']);

Route::get('/berita/{id}/gambar', [BeritaController::class, 'image'])
    ->whereNumber('id')
    ->name('api.berita.image');

Route::get('/berita/{id}', [BeritaController::class, 'show'])
    ->whereNumber('id');

Route::get('/notifikasi', [NotifikasiController::class, 'index']);
Route::get('/prakiraan-cuaca/wilayah', [BmkgForecastController::class, 'areas'])
    ->middleware('throttle:30,1');
Route::get('/prakiraan-cuaca/{adm4}', [BmkgForecastController::class, 'show'])
    ->where('adm4', '\\d{2}\\.\\d{2}\\.\\d{2}\\.\\d{4}')
    ->middleware('throttle:30,1');

Route::get('/peta/titik-kumpul-osm', [OsmAssemblyPointController::class, 'index'])
    ->middleware('throttle:30,1');

Route::post('/peta/rute-simulasi', [RouteSimulationController::class, 'store'])
    ->middleware('throttle:5,1');

Route::get('/peta/alamat', [NominatimReverseGeocodingController::class, 'show'])
    ->middleware('throttle:30,1');

Route::post('/peta/analisis-bahaya', [HazardMapAnalysisController::class, 'store'])
    ->middleware('throttle:5,1');

Route::post('/pengaduan', [PengaduanController::class, 'store'])
    ->middleware('throttle:5,1');
