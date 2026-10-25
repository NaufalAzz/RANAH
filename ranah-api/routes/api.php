<?php

use App\Http\Controllers\BeritaController;
use App\Http\Controllers\GunungController;
use App\Http\Controllers\PengaduanController;
use App\Http\Controllers\NotifikasiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/gunung', [GunungController::class, 'index']);

Route::get('/gunung/{id}', [GunungController::class, 'show'])
    ->whereNumber('id');

Route::get('/berita', [BeritaController::class, 'index']);

Route::get('/berita/{id}', [BeritaController::class, 'show'])
    ->whereNumber('id');

Route::get('/notifikasi', [NotifikasiController::class, 'index']);

Route::post('/pengaduan', [PengaduanController::class, 'store'])
    ->middleware('throttle:5,1');
