<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\GunungController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/gunung', [GunungController::class, 'index']);

Route::get('/gunung/{id}', [GunungController::class, 'show'])
    ->whereNumber('id');
