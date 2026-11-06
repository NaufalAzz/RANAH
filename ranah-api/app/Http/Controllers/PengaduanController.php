<?php

namespace App\Http\Controllers;

use App\Models\Pengaduan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Throwable;

class PengaduanController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nama_pelapor' => ['required', 'string', 'max:150'],
            'nomor_telepon' => [
                'required',
                'string',
                'max:30',
                'regex:/^[0-9+\\s().-]+$/',
            ],
            'kategori' => [
                'required',
                'string',
                Rule::in([
                    'Erupsi gunung api',
                    'Gempa bumi',
                    'Banjir',
                    'Tsunami',
                    'Lainnya',
                ]),
            ],
            'lokasi_kejadian' => ['required', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'deskripsi' => ['required', 'string', 'max:10000'],
            'persetujuan' => ['required', 'accepted'],
            'media' => ['nullable', 'array', 'max:3'],
            'media.*' => ['file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $storedMedia = [];
        try {
            foreach ($request->file('media', []) as $file) {
                $path = $file->store('pengaduan', 'local');
                if (! is_string($path)) {
                    throw new \RuntimeException('Lampiran gagal disimpan.');
                }

                $storedMedia[] = [
                    'path' => $path,
                    'nama' => $file->getClientOriginalName(),
                    'mime' => $file->getMimeType(),
                    'ukuran' => $file->getSize(),
                ];
            }

            $pengaduan = DB::transaction(fn () => Pengaduan::query()->create([
                'nama_pelapor' => $validated['nama_pelapor'],
                'nomor_telepon' => $validated['nomor_telepon'],
                'kategori' => $validated['kategori'],
                'lokasi_kejadian' => $validated['lokasi_kejadian'],
                'latitude' => $validated['latitude'] ?? null,
                'longitude' => $validated['longitude'] ?? null,
                'deskripsi' => $validated['deskripsi'],
                'media' => $storedMedia ?: null,
                'waktu_pengaduan' => now(),
            ]));
        } catch (Throwable $exception) {
            Storage::disk('local')->delete(array_column($storedMedia, 'path'));
            throw $exception;
        }

        return response()->json([
            'success' => true,
            'message' => 'Pengaduan berhasil diterima.',
            'data' => [
                'id' => $pengaduan->id,
                'waktu_pengaduan' => $pengaduan->waktu_pengaduan,
            ],
        ], 201);
    }
}
